package zenith.system;

import flixel.math.FlxMath;
import flixel.math.FlxAngle;

@:access(zenith.Gameplay)
@:access(Stack)

class NoteSpawner extends FlxBasic
{
	var members(default, null):Stack<Note>; // Members
	var hittable(default, null):Stack<Note>; // Hittable

	var preallocationCount:Int = 0;

	public function new():Void
	{
		super();

		members = new Stack<Note>(preallocationCount);

		hittable = new Stack<Note>(16);

		if (SaveData.contents.experimental.fastNoteSpawning)
			pool = new Stack<Note>(1000000);

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
		_n.targetCharacter = _n.lane == 0 ? Gameplay.instance.dad : Gameplay.instance.bf;

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
			n = members.__items[i];

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
					hittable.__items[n.strum.index] = Paths.idleNote;
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
						if ((hittable.__items[n.strum.index] == Paths.idleNote ||
						     hittable.__items[n.strum.index].strumTime > n.strumTime ||
						     hittable.__items[n.strum.index].state != IDLE) &&
							Main.conductor.songPosition > n.strumTime - 166.7)
						{
							hittable.__items[n.strum.index] = n;
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

		members.clear(true);

		while (pool.length != 0)
		{
			pool.pop().destroy();
		}

		pool.clear(true);
	}

	var _nk(default, null):Int = 0;

	inline public function handleHittableNote(strum:StrumNote):Void
	{
		// The middle checks are pretty weird but it does fix a couple bugs
		if (strum != null && strum.playable && hittable.__items[strum.index].state == IDLE &&
			Main.conductor.songPosition > hittable.__items[strum.index].strumTime - (166.7 * Gameplay.instance.songSpeed))
		{
			hittable.__items[strum.index].state = HIT;
			Gameplay.instance.onNoteHit(hittable.__items[strum.index]);
			if (SaveData.contents.experimental.fastNoteSpawning)
				pool.push(hittable.__items[strum.index]);
			hittable.__items[strum.index] = Paths.idleNote;
		}
	}

	function recycle():Note
	{
		for (i in 0...members.length)
			if (!members.__items[i].exists)
				return members.__items[i];
		return null;
	}

	var pool(default, null):Stack<Note>; // Rewritten recycler
}
