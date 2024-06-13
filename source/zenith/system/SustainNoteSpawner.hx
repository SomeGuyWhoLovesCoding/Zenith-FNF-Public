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

	var _s(default, null):SustainNote;
	public function spawn(chartSustainData:ChartBytesData.ChartNoteData):Void
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

		_s.camera = camera;
		_s.cameras = cameras;
		_s.setFrame(Paths.sustainNoteFrame);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupSustainData', _s, chartSustainData);
		#end

		_s.position = chartSustainData.position;
		_s.noteData = chartSustainData.noteData;
		_s.length = chartSustainData.sustainLength;
		_s.lane = chartSustainData.lane % Gameplay.strumlineCount;
		_s.targetCharacter = _s.lane == 0 ? Gameplay.instance.dad : Gameplay.instance.bf;

		_sk = Gameplay.instance.strumlines.members[_s.lane].keys;
		_s.noteData = _s.noteData % _sk;

		_s.strum = Gameplay.instance.strumlines.members[_s.lane].members[_s.noteData % _sk];
		_s.scale.set(_s.strum.scale.x, _s.strum.scale.y);

		_s.offset.x = -0.5 * ((_s.frameWidth * _s.scale.x) - _s.frameWidth);
		_s.origin.x = _s.frameWidth * 0.5;
		_s.origin.y = _s.offset.y = 0.0;

		_s.color = NoteBase.colorArray[_s.noteData % _sk];

		_s.downScroll = _s.strum.scrollMult < 0.0;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('newSustain', _s);
		#end

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupSustainDataPost', _s, chartSustainData);
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
				s.draw();

				s.scale.set(s.strum.scale.x, s.strum.scale.y);
				s.offset.x = -0.5 * ((s.frameWidth * s.scale.x) - s.frameWidth);
				s.origin.x = s.frameWidth * 0.5;
				s.origin.y = s.offset.y = 0.0;

				s.distance = 0.45 * (Main.conductor.songPosition - s.position) * Gameplay.instance.songSpeed;

				s.x = (s.strum.x + s.offsetX + (-Math.abs(s.strum.scrollMult) * s.distance) *
					FlxMath.fastCos(FlxAngle.asRadians(s.direction - 90.0))) + ((Gameplay.instance.initialStrumWidth - (s.frameWidth * s.scale.x)) * 0.5);

				s.y = (s.strum.y + s.offsetY + (s.strum.scrollMult * s.distance) *
					FlxMath.fastSin(FlxAngle.asRadians(s.direction - 90.0))) + (Gameplay.instance.initialStrumHeight * 0.5);

				if (Main.conductor.songPosition > (s.position + s.length) + (750.0 / Gameplay.instance.songSpeed))
				{
					s.exists = false;
					if (SaveData.contents.experimental.fastNoteSpawning)
						pool.push(s);
					continue;
				}

				if (Main.conductor.songPosition < (s.position + s.length) - (Main.conductor.stepCrochet * 0.875) &&
					Main.conductor.songPosition > s.position && s.state != MISS)
				{
					if (s.strum.playable)
					{
						_s = missable.__items[s.strum.index];
						if (Main.conductor.songPosition > s.position - 166.7 &&
							(_s == Paths.idleSustain ||
							_s.position > s.position ||
							_s.state != IDLE))
						{
							missable.__items[s.strum.index] = s;
						}
					}

					if ((s.strum.active && s.state != MISS) || !s.strum.playable)
					{
						Gameplay.instance.onHold(s);
					}
				}
				else
				{
					missable.__items[s.strum.index] = Paths.idleSustain;
				}
			}
		}
	}

	var _sk(default, null):Int = 0;

	public function handleRelease(strum:StrumNote):Void
	{
		_s = missable.__items[strum.index];
		if (strum != null && strum.playable && _s != Paths.idleSustain &&
			Main.conductor.songPosition > _s.position &&
			_s.state != MISS)
		{
			_s.state = MISS;
			_s.alpha = 0.3;

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onRelease', _s);
			#end

			Gameplay.instance.health -= 0.045;

			if (!Gameplay.noCharacters)
			{
				Gameplay.instance.bf.playAnim(strum.parent.singAnimations(_s.noteData));
				Gameplay.instance.bf.holdTimer = 0.0;
			}

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onReleasePost', _s);
			#end
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
}
