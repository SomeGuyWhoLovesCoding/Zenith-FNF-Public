package zenith.system;

import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import sys.thread.Deque;

@:access(zenith.Gameplay)

class NoteSpawner extends FlxBasic
{
	var m(default, null):Array<Note>; // Members
	var h(default, null):Map<StrumNote, Note>; // Hittable

	public function new():Void
	{
		super();

		m = [];
		h = new Map<StrumNote, Note>();
		p = new Deque<Note>();
	}

	var _n(default, null):Note;
	public function spawn(chartNoteData:Array<Float>):Note
	{
		_n = p.pop(false);

		if (_n != null)
		{
			_n.exists = true;
		}
		else
		{
			_n = new Note();
			m.push(_n);
		}

		_n.state = IDLE;

		_n.camera = camera;
		_n.cameras = cameras;
		_n.setFrame(Paths.regularNoteFrame);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupNoteData', _n, chartNoteData);
		#end

		_n.alpha = 1.0;
		_n.y = -2000.0;

		_n.strumTime = chartNoteData[0];
		_n.noteData = Std.int(chartNoteData[1]);
		_n.sustainLength = Std.int(chartNoteData[2]) - 32;
		_n.lane = Std.int(chartNoteData[3]) % Gameplay.strumlineCount;
		_n.multiplier = Std.int(chartNoteData[4]);

		_nk = Gameplay.instance.strumlines.members[_n.lane].keys;
		_n.noteData = _n.noteData % _nk;

		_n.strum = Gameplay.instance.strumlines.members[_n.lane].members[_n.noteData % _nk];
		_n.scale.set(_n.strum.scale.x, _n.strum.scale.y);

		_n.offset.x = -0.5 * ((_n.frameWidth * _n.scale.x) - _n.frameWidth);
		_n.offset.y = -0.5 * ((_n.frameHeight * _n.scale.y) - _n.frameHeight);
		_n.origin.x = _n.frameWidth * 0.5;
		_n.origin.y = _n.frameHeight * 0.5;

		_n.color = NoteBase.colorArray[_n.noteData % _nk];
		_n.angle = NoteBase.angleArray[_n.noteData % _nk];

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('newNote', _n);
		#end

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupNoteDataPost', _n, chartNoteData);
		#end

		if (_n.sustainLength > 32.0)
		{
			Gameplay.instance.sustainNoteSpawner.spawn(chartNoteData);
		}

		return _n;
	}

	var n(default, null):Note;
	override function update(elapsed:Float):Void
	{
		for (i in 0...m.length)
		{
			n = m[i];

			if (n.exists)
			{
				n.scale.set(n.strum.scale.x, n.strum.scale.y);
				n.offset.x = -0.5 * ((n.frameWidth * 0.7) - n.frameWidth);
				n.offset.y = -0.5 * ((n.frameHeight * 0.7) - n.frameHeight);
				n.origin.x = n.frameWidth * 0.5;
				n.origin.y = n.frameHeight * 0.5;

				n.distance = 0.45 * (Main.conductor.songPosition - n.strumTime) * Gameplay.instance.songSpeed;
				n.x = n.strum.x + n.offsetX + (-Math.abs(n.strum.scrollMult) * n.distance) *
					FlxMath.fastCos(FlxAngle.asRadians(n.direction - 90.0));
				n.y = n.strum.y + n.offsetY + (n.strum.scrollMult * n.distance) *
					FlxMath.fastSin(FlxAngle.asRadians(n.direction - 90.0));

				if (Main.conductor.songPosition > n.strumTime + (750.0 / Gameplay.instance.songSpeed)) // Remove them if they're offscreen
				{
					n.exists = false;
					h.remove(n.strum);
					p.push(n);
					continue;
				}

				if (n.strum.playable)
				{
					if (n.state == IDLE)
					{
						// Took forever to fully polish jack detection here
						if (Main.conductor.songPosition > n.strumTime - 166.7 &&
							(!h.exists(n.strum) || h[n.strum].strumTime > n.strumTime && h[n.strum].state == MISS))
						{
							h[n.strum] = n;
						}

						if (Main.conductor.songPosition > n.strumTime + (166.7 / Gameplay.instance.songSpeed))
						{
							Gameplay.instance.onNoteMiss(n);
							n.state = MISS;
						}
					}
				}

				if ((Gameplay.cpuControlled || !n.strum.playable) && Main.conductor.songPosition > n.strumTime)
				{
					Gameplay.instance.onNoteHit(n);
					p.push(n);
				}
			}
		}
	}

	override function draw():Void
	{
		for (i in 0...m.length)
		{
			n = m[i];
			if (n.exists)
				n.draw();
		}
	}

	override function destroy():Void
	{
		while (m.length != 0)
		{
			m.pop().destroy();
		}

		m = null;
	}

	var _nk(default, null):Int = 0;

	inline public function handleHittableNote(strum:StrumNote):Void
	{
		if (h.exists(strum) && h[strum].state == IDLE)
		{
			h[strum].state = HIT;
			Gameplay.instance.onNoteHit(h[strum]);
			p.push(h[strum]);
			h.remove(strum);
		}
	}

	var p(default, null):Deque<Note>; // Rewritten recycler
}