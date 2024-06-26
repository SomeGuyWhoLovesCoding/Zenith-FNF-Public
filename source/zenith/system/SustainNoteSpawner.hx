package zenith.system;

import flixel.math.FlxMath;
import flixel.math.FlxAngle;

@:access(zenith.Gameplay)
@:access(Stack)
@:final
class SustainNoteSpawner extends FlxBasic
{
	var members(default, null):Stack<SustainNote>;
	var missable(default, null):Stack<SustainNote>;

	public function new():Void
	{
		super();

		members = new Stack<SustainNote>(512, Paths.idleSustain);

		missable = new Stack<SustainNote>(32, Paths.idleSustain);

		if (SaveData.contents.experimental.fastNoteSpawning)
			pool = new Stack<SustainNote>(512, Paths.idleSustain);

		active = false;
	}

	inline function updateMissCheck(s:SustainNote):Void
	{
		if (s.strum.playable)
		{
			_s = missable.__items[s.strum.index];
			if (_s == Paths.idleSustain ||
				_s.position  > s.position ||
				s.state == IDLE)
			{
				missable.__items[s.strum.index] = s;
			}
		}
	}

	var _s(default, null):SustainNote;

	public function spawn(parent:Note):Void
	{
		_s = SaveData.contents.experimental.fastNoteSpawning ? pool.pop() : recycle();

		if (_s != null)
		{
			_s.y = FlxG.height * (Gameplay.downScroll || _s.strum.scrollMult <= 0.0 ? -8.0 : 8.0);
			_s.exists = true;
		}
		else
		{
			_s = new SustainNote();
			_s.y = FlxG.height * (Gameplay.downScroll ? -8.0 : 8.0);
			members.push(_s);
		}

		_s.alpha = 0.6;

		_s.state = IDLE;
		_s.clip = 1.0;

		_s.camera = camera;
		_s.cameras = cameras;
		_s.frame = Paths.sustainNoteFrame.copyTo(null);

		parent.child = _s;
		parent.hasChild = true;
		_s.parent = parent;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupSustainData', _s);
		#end

		_s.position = parent.position;
		_s.noteData = parent.noteData;
		_s.length = parent.sustainLength;
		_s.lane = parent.lane % Gameplay.strumlineCount;
		_s.targetCharacter = _s.lane == 0 ? Gameplay.instance.dad : Gameplay.instance.bf;

		_sk = Gameplay.instance.strumlines.members[_s.lane].keys;
		_s.noteData = _s.noteData % _sk;

		_s.strum = Gameplay.instance.strumlines.members[_s.lane].members[_s.noteData % _sk];
		_s.scale.set(_s.strum.scale.x, _s.strum.scale.y);

		_s.offset.x = Std.int((-_s.frameWidth * _s.scale.x) + _s.frameWidth) >> 1;
		_s.origin.x = _s.frameWidth >> 1;
		_s.origin.y = _s.offset.y = 0.0;

		_s.color = NoteBase.colorArray[_s.noteData % _sk];

		_s.downScroll = _s.strum.scrollMult < 0.0;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('newSustain', _s);
		#end

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupSustainDataPost', _s);
		#end
	}

	var s(default, null):SustainNote;

	override function draw():Void
	{
		for (i in 0...members.length)
		{
			s = members.__items[i];

			if (s.exists)
			{
				if (s != Paths.idleSustain)
				{
					s.draw();
				}

				s.scale.set(s.strum.scale.x, s.strum.scale.y);
				s.offset.x = Std.int((-s.frameWidth * s.scale.x) + s.frameWidth) >> 1;
				s.origin.x = s.frameWidth >> 1;
				s.origin.y = s.offset.y = 0.0;

				s.distance = 0.45 * (Main.conductor.songPosition - s.position) * Gameplay.instance.songSpeed;

				if (s.state == HELD)
					s.clip = ((s.position + s.length) - Main.conductor.songPosition) / s.length;

				_updatePositionOf(s);

				if (Main.conductor.songPosition > (s.position + s.length) + (750.0 / Gameplay.instance.songSpeed))
				{
					missable.__items[s.strum.index] = Paths.idleSustain;
					s.exists = false;

					if (SaveData.contents.experimental.fastNoteSpawning)
					{
						pool.push(s);
					}

					continue;
				}

				if (Main.conductor.songPosition > s.position - 166.7
					&& Main.conductor.songPosition < (s.position + s.length) - (Main.conductor.stepCrochet * 0.685))
				{
					updateMissCheck(s);

					if ((s.state == HELD && Main.conductor.songPosition > s.position) && (!s.strum.isIdle || !s.strum.playable))
					{
						onSustainHold(s);
					}
				}
			}
		}
	}

	var _sk(default, null):Int = 0;

	public function handleRelease(strum:StrumNote):Void
	{
		_s = missable.__items[strum.index];
		if (strum != null
			&& strum.playable
			&& _s != Paths.idleSustain
			&& Main.conductor.songPosition > _s.position
			&& Main.conductor.songPosition < (_s.position + _s.length) - (Main.conductor.stepCrochet * 0.685) && _s.state != MISS)
		{
			onSustainMiss(_s);
			missable.__items[strum.index] = Paths.idleSustain;
		}
	}

	function recycle():SustainNote
	{
		for (i in 0...members.length)
			if (!members.__items[i].exists)
				return members.__items[i];
		return null;
	}

	var pool(default, null):Stack<SustainNote>;

	// Called from gameplay

	public function onSustainHold(sustain:SustainNote):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onSustainHold", sustain);
		#end

		sustain.strum.playAnim("confirm");

		Gameplay.instance.health += FlxG.elapsed * (sustain.strum.playable ? 0.125 : -0.125);

		if (!Gameplay.noCharacters)
		{
			if (Gameplay.stillCharacters)
				sustain.targetCharacter?.playAnim(sustain.strum.parent.singAnimations(sustain.noteData));
			else
			{
				// This shit is similar to amazing engine's character hold fix, but better

				if (sustain.targetCharacter?.animation.curAnim.name == sustain.strum.parent.singAnimations(sustain.noteData) + "miss")
					sustain.targetCharacter?.playAnim(sustain.strum.parent.singAnimations(sustain.noteData));

				if (sustain.targetCharacter?.animation.curAnim.curFrame > (sustain.targetCharacter?.stillCharacterFrame == -1 ? sustain.targetCharacter?.animation.curAnim.frames.length : sustain.targetCharacter?.stillCharacterFrame))
					@:privateAccess sustain.targetCharacter?.animation.curAnim.set_curFrame(sustain.targetCharacter?.stillCharacterFrame == -1 ? sustain.targetCharacter?.animation.curAnim.frames.length
						- 2 : sustain.targetCharacter?.stillCharacterFrame
						- 1);
			}

			sustain.targetCharacter?.set_holdTimer(0.0);
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onHoldSustainPost", sustain);
		#end
	}

	public function onSustainMiss(sustain:SustainNote):Void
	{
		sustain.state = MISS;
		sustain.alpha = 0.3;
		sustain.clip = 1.0;
		updateMissCheck(sustain);

		_updatePositionOf(sustain);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onSustainMiss', sustain);
		#end

		if (!Gameplay.noCharacters)
		{
			sustain.targetCharacter?.playAnim(sustain.strum.parent.singAnimations(sustain.noteData) + "miss");
			sustain.targetCharacter?.set_holdTimer(0.0);
		}

		if (sustain.strum.playable)
		{
			Gameplay.instance.combo = 0;
			Gameplay.instance.hudGroup?.updateRatings();
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onSustainMissPost', sustain);
		#end
	}

	// Don't want to inline this because it could potentially make compiled code a mess and could decrease performance
	private function _updatePositionOf(s:SustainNote):Void
	{
		s.x = s.state == HELD ? // If held
			s.strum.x + ((Gameplay.instance.initialStrumWidth - (s.frameWidth * s.scale.x)) * 0.5) // If not held
			: ((s.strum.x + s.offsetX + (-Math.abs(s.strum.scrollMult) * s.distance) * FlxMath.fastCos(FlxAngle.asRadians(s.direction - 90.0)))
				+ ((Gameplay.instance.initialStrumWidth - (s.frameWidth * s.scale.x)) * 0.5));

		s.y = s.state == HELD ? // If held
			s.strum.y + (Gameplay.instance.initialStrumHeight * 0.5) // If not held
			: ((s.strum.y + s.offsetY + (s.strum.scrollMult * s.distance) * FlxMath.fastSin(FlxAngle.asRadians(s.direction - 90.0)))
				+ (Gameplay.instance.initialStrumHeight * 0.5));
	}
}
