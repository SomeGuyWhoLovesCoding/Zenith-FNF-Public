package zenith.system;

import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import sys.thread.Deque;

@:access(zenith.Gameplay)

class SustainNoteSpawner extends FlxBasic
{
	var m(default, null):Array<SustainNote>; // Members
	var h(default, null):Map<StrumNote, SustainNote>; // Missable

	public function new():Void
	{
		super();
		m = [];

		h = new Map<StrumNote, SustainNote>();
		p = new Deque<SustainNote>();

		active = false;
	}

	var _s(default, null):SustainNote;
	public function spawn(chartSustainData:Array<Float>):SustainNote
	{
		_s = p.pop(false);

		if (_s != null)
		{
			_s.y = -2000.0;
			_s.alpha = 0.6;
			_s.exists = true;
		}
		else
		{
			_s = new SustainNote();
			_s.y = -2000.0;
			_s.alpha = 0.6;
			m.push(_s);
		}

		_s.state = IDLE;

		_s.camera = camera;
		_s.cameras = cameras;
		_s.setFrame(Paths.sustainNoteFrame);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('setupSustainData', _s, chartSustainData);
		#end

		_s.strumTime = chartSustainData[0];
		_s.noteData = Std.int(chartSustainData[1]);
		_s.length = chartSustainData[2] - 32.0 % Gameplay.strumlineCount;
		_s.lane = Std.int(chartSustainData[3]);

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

		return _s;
	}

	var s(default, null):SustainNote;
	public function _update():Void
	{
		if (m == null)
		{
			return;
		}

		for (i in 0...m.length)
		{
			s = m[i];

			if (s.exists)
			{
				s.scale.set(s.strum.scale.x, s.strum.scale.y);
				s.offset.x = -0.5 * ((s.frameWidth * s.scale.x) - s.frameWidth);
				s.origin.x = s.frameWidth * 0.5;
				s.origin.y = s.offset.y = 0.0;

				s.distance = 0.45 * (Main.conductor.songPosition - s.strumTime) * Gameplay.instance.songSpeed;

				s.x = (s.strum.x + s.offsetX + (-Math.abs(s.strum.scrollMult) * s.distance) *
					FlxMath.fastCos(FlxAngle.asRadians(s.direction - 90.0))) + ((Gameplay.instance.initialStrumWidth - (s.frameWidth * s.scale.x)) * 0.5);

				s.y = (s.strum.y + s.offsetY + (s.strum.scrollMult * s.distance) *
					FlxMath.fastSin(FlxAngle.asRadians(s.direction - 90.0))) + (Gameplay.instance.initialStrumHeight * 0.5);

				if (Main.conductor.songPosition > (s.strumTime + s.length) + (750.0 / Gameplay.instance.songSpeed))
				{
					s.exists = false;
					p.push(s);
					continue;
				}

				if (Main.conductor.songPosition < (s.strumTime + s.length) - (Main.conductor.stepCrochet * 0.875) &&
					Main.conductor.songPosition > s.strumTime && s.state != MISS)
				{
					if (s.strum.playable)
					{
						if (Main.conductor.songPosition > s.strumTime - 166.7 &&
							(!h.exists(s.strum) || h[s.strum].strumTime > s.strumTime || h[s.strum].state != IDLE))
						{
							h[s.strum] = s;
						}
					}

					if ((!s.strum.isIdle() && s.state != MISS) || !s.strum.playable)
					{
						Gameplay.instance.onHold(s);
					}
				}
				else
				{
					h.remove(s.strum);
				}
			}
		}
	}

	override function draw():Void
	{
		for (i in 0...m.length)
		{
			s = m[i];
			if (s.exists)
				s.draw();
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

	var _sk(default, null):Int = 0;

	public function handleRelease(strum:StrumNote):Void
	{
		if (strum.playable && h.exists(strum) && Main.conductor.songPosition > h[strum].strumTime && h[strum].state != MISS)
		{
			h[strum].state = MISS;
			h[strum].alpha = 0.3;

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onRelease', h[strum]);
			#end

			Gameplay.instance.health -= 0.045;

			if (!Gameplay.noCharacters)
			{
				Gameplay.instance.bf.playAnim(Gameplay.missAnimations[h[strum].noteData]);
				Gameplay.instance.bf.holdTimer = 0.0;
			}

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onReleasePost', h[strum]);
			#end

			h.remove(strum);
		}
	}

	var p(default, null):Deque<SustainNote>;
}
