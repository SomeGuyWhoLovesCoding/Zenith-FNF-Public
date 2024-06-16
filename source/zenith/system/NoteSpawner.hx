package zenith.system;

import flixel.math.FlxMath;
import flixel.math.FlxAngle;

@:access(zenith.Gameplay)
@:access(Stack)
@:access(zenith.system.SustainNoteSpawner)

@:final
class NoteSpawner extends FlxBasic
{
	var members(default, null):Stack<Note>; // Members
	var hittable(default, null):Stack<Note>; // Hittable

	var preallocationCount:Int = 1024;

	public function new(preallocationCount:Int = 0):Void
	{
		super();

		if (preallocationCount != 0)
			this.preallocationCount = preallocationCount;

		members = new Stack<Note>(preallocationCount, Paths.idleNote);

		hittable = new Stack<Note>(32, Paths.idleNote);

		if (SaveData.contents.experimental.fastNoteSpawning)
			pool = new Stack<Note>(preallocationCount, Paths.idleNote);

		active = false;
	}

	var _n(default, null):Note;
	public function spawn(chartNoteData:ChartBytesData.ChartNoteData):Void
	{
		_n = SaveData.contents.experimental.fastNoteSpawning ? pool.pop() : recycle();

		if (_n != null)
		{
			_n.y = FlxG.height * (Gameplay.downScroll || _n.strum.scrollMult <= 0.0 ? -8.0 : 8.0);
			_n.exists = true;
		}
		else
		{
			_n = new Note();
			_n.y = FlxG.height * (Gameplay.downScroll ? -8.0 : 8.0);
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

		_n.position = chartNoteData.position;
		_n.noteData = chartNoteData.noteData;
		_n.sustainLength = chartNoteData.sustainLength;
		_n.lane = chartNoteData.lane % Gameplay.strumlineCount;
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

		_n.child = null;
		_n.hasChild = false;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('newNote', _n);

		Main.hscript.callFromAllScripts('setupNoteDataPost', _n, chartNoteData);
		#end

		if (_n.sustainLength > 20) // Don't spawn too short sustains
		{
			Gameplay.instance.sustainNoteSpawner.spawn(chartNoteData, _n);
		}
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
				n.offset.x = -0.5 * (n.frameWidth - n.frameWidth);
				n.offset.y = -0.5 * (n.frameHeight - n.frameHeight);
				n.origin.x = n.frameWidth * 0.5;
				n.origin.y = n.frameHeight * 0.5;

				n.distance = 0.45 * (Main.conductor.songPosition - n.position) * Gameplay.instance.songSpeed;
				n.x = n.strum.x + n.offsetX + (-Math.abs(n.strum.scrollMult) * n.distance) *
					FlxMath.fastCos(FlxAngle.asRadians(n.direction - 90.0));
				n.y = n.strum.y + n.offsetY + (n.strum.scrollMult * n.distance) *
					FlxMath.fastSin(FlxAngle.asRadians(n.direction - 90.0));

				if (Main.conductor.songPosition > n.position + (750.0 / Gameplay.instance.songSpeed)) // Remove them if they're offscreen
				{
					hittable.__items[n.strum.index] = Paths.idleNote;
					n.exists = false;

					if (SaveData.contents.experimental.fastNoteSpawning)
					{
						pool.push(n);
					}

					continue;
				}

				if (!Gameplay.cpuControlled && n.strum.playable)
				{
					if (n.state == IDLE)
					{
						if (Main.conductor.songPosition > n.position + 166.7)
						{
							onNoteMiss(n);
							n.state = MISS;
						}

						// Took forever to fully polish here ofc
						_n = hittable.__items[n.strum.index];
						if ((_n == Paths.idleNote ||
							_n.position > n.position ||
							_n.state != IDLE) &&
							Main.conductor.songPosition > n.position - 166.7)
						{
							hittable.__items[n.strum.index] = n;
						}
					}
				}
				else
				{
					if (Main.conductor.songPosition > n.position)
					{
						onNoteHit(n);

						if (SaveData.contents.experimental.fastNoteSpawning)
						{
							pool.push(n);
						}
					}
				}
			}
		}
	}

	var _nk(default, null):Int = 0;

	inline public function handlePress(strum:StrumNote):Void
	{
		_n = hittable.__items[strum.index];
		if (strum != null && !strum.isIdle && strum.playable && _n.state == IDLE &&
			Main.conductor.songPosition > _n.position - (166.7 * Gameplay.instance.songSpeed))
		{
			onNoteHit(_n);

			if (SaveData.contents.experimental.fastNoteSpawning)
			{
				pool.push(_n);
			}

			hittable.__items[strum.index] = Paths.idleNote;
		}
	}

	function recycle():Note
	{
		for (note in members)
			if (note.exists)
				return note;
		return null;
	}

	var pool(default, null):Stack<Note>; // Rewritten recycler

	// Called from gameplay

	public function onNoteHit(note:Note):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteHit", note);
		#end

		note.strum.playAnim("confirm");

		Gameplay.instance.health += 0.045 * (note.strum.playable ? 1.0 : -1.0);

		if (note.strum.playable)
		{
			Gameplay.instance.score += 350.0;
			Gameplay.instance.accuracy_left += ((note.position - Main.conductor.songPosition < 0.0 ? -(note.position - Main.conductor.songPosition) :
				note.position - Main.conductor.songPosition) > 83.35 ? 0.75 : 1.0);
			Gameplay.instance.accuracy_right++;
		}

		if (!Gameplay.noCharacters)
		{
			if (null != note.targetCharacter)
			{
				note.targetCharacter.playAnim(note.strum.parent.singAnimations(note.noteData));
				note.targetCharacter.holdTimer = 0.0;
			}
		}

		note.state = HIT;

		if (note.hasChild)
		{
			note.child.state = HELD;
			note.child.mult = ((note.child.position + note.child.length) - Main.conductor.songPosition) / note.child.length;
			Gameplay.instance.sustainNoteSpawner._updatePositionOf(note.child);
		}

		note.exists = false;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteHitPost", note);
		#end

		if (Gameplay.instance.hudGroup != null)
			Gameplay.instance.hudGroup.updateScoreText();
	}

	public function onNoteMiss(note:Note):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteMiss", note);
		#end

		note.state = MISS;

		if (note.hasChild)
		{
			note.child.state = MISS;
			Gameplay.instance.sustainNoteSpawner.onSustainMiss(note.child);
		}

		note.alpha = 0.6;

		Gameplay.instance.health -= 0.045;
		Gameplay.instance.score -= 100.0;
		Gameplay.instance.misses++;
		Gameplay.instance.accuracy_right++;

		if (!Gameplay.noCharacters)
		{
			note.targetCharacter.playAnim(note.strum.parent.singAnimations(note.noteData) + "miss");
			note.targetCharacter.holdTimer = 0.0;
		}

		if (Gameplay.instance.hudGroup != null)
			Gameplay.instance.hudGroup.updateScoreText();

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteMissPost", note);
		#end
	}
}
