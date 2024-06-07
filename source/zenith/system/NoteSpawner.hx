package zenith.system;

import flixel.math.FlxMath;
import flixel.math.FlxAngle;

@:access(zenith.Gameplay)

class NoteSpawner extends FlxBasic
{
	var members(default, null):Array<Note>; // Members
	var hittable(default, null):Map<StrumNote, Note>; // Hittable

	public function new():Void
	{
		super();

		members = [];

		hittable = new Map<StrumNote, Note>();

		if (SaveData.contents.experimental.fastNoteSpawning)
			pool = new Array<Note>();

		active = false;
	}

	var _n(default, null):Note;
	public function spawn(chartNoteData:Array<Float>):Note
	{
		_n = SaveData.contents.experimental.fastNoteSpawning ? pool.pop() : recycle();

		if (_n != null)
		{
			_n.y = FlxG.height * 8.0;
			_n.exists = true;
		}
		else
		{
			_n = new Note();
			_n.y = FlxG.height * 8.0;
			members.push(_n);
		}

		_n.alpha = 1.0;
		_n.state = IDLE;

		_n.camera = camera;
		_n.cameras = cameras;
		_n.setFrame(Paths.regularNoteFrame);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupNoteData', _n, chartNoteData);
		#end

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

	override function draw():Void
	{
		for (i in 0...members.length)
		{
			n = members[i];

			if (n.exists)
			{
				n.draw();

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
					hittable[n.strum] = Paths.idleNote;
					n.exists = false;
					if (SaveData.contents.experimental.fastNoteSpawning)
						pool.push(n);
					continue;
				}

				if (!Gameplay.cpuControlled && n.strum.playable)
				{
					if (n.state == IDLE)
					{
						if (Main.conductor.songPosition > n.strumTime + 166.7)
						{
							Gameplay.instance.onNoteMiss(n);
							n.state = MISS;
						}

						// Took forever to fully polish here ofc
						// 
						if ((hittable[n.strum] == Paths.idleNote || hittable[n.strum].strumTime > n.strumTime || hittable[n.strum].state != IDLE) &&
							Main.conductor.songPosition > n.strumTime - 166.7)
						{
							hittable[n.strum] = n;
						}
					}
				}
				else
				{
					if (Main.conductor.songPosition > n.strumTime)
					{
						Gameplay.instance.onNoteHit(n);
						if (SaveData.contents.experimental.fastNoteSpawning)
							pool.push(n);
					}
				}
			}
		}
	}

	override function destroy():Void
	{
		while (members.length != 0)
		{
			members.pop().destroy();
		}

		members = null;

		while (pool.length != 0)
		{
			pool.pop().destroy();
		}

		pool = null;
	}

	var _nk(default, null):Int = 0;

	inline public function handleHittableNote(strum:StrumNote):Void
	{
		// The middle checks are pretty weird but it does fix a couple bugs
		if (strum != null && strum.playable && hittable.exists(strum) && hittable[strum].state == IDLE &&
			Main.conductor.songPosition > hittable[strum].strumTime - (166.7 * Gameplay.instance.songSpeed))
		{
			hittable[strum].state = HIT;
			Gameplay.instance.onNoteHit(hittable[strum]);
			if (SaveData.contents.experimental.fastNoteSpawning)
				pool.push(hittable[strum]);
			hittable[strum] = Paths.idleNote;
		}
	}

	function recycle():Note
	{
		for (note in members)
			if (!note.exists)
				return note;
		return null;
	}

	var pool(default, null):List<Note>; // Rewritten recycler
}
