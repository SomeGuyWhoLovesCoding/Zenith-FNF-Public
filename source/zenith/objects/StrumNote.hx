package zenith.objects;

@:access(flixel.animation.FlxAnimationController)
@:access(flixel.animation.FlxAnimation)
class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	public var scrollMult:Float = 1;
	public var playerStrum(default, set):Bool = false;

	inline function set_playerStrum(value:Bool):Bool
	{
		animation.finishCallback = value ? null : (anim:String) ->
		{
			if (anim == 'confirm' && (!playerStrum || Gameplay.cpuControlled))
				playAnim('static');
		}
		return playerStrum = value;
	}

	public function new(data:Int, plr:Int)
	{
		super();

		noteData = data;
		player = plr;

		frames = Paths.strumNoteAnimationHolder.frames;
		inline animation.copyFrom(Paths.strumNoteAnimation);

		pixelPerfectPosition = false;

		angle = NoteBase.angleArray[noteData];

		scale.x = scale.y = 0.7;

		playAnim = (anim:String) ->
		{
			color = anim == 'static' ? 0xffffffff : NoteBase.colorArray[noteData];

			inline animation.play(anim, true); // Don't touch this lol
			active = anim != 'static';

			// Broken down version of updateHitbox(), basically inlining manually
			width = Math.abs(scale.x) * frameWidth;
			height = Math.abs(scale.y) * frameHeight;
			offset.x = (frameWidth * 0.5) - 54;
			offset.y = (frameHeight * 0.5) - 56;
			origin.x = offset.x + 54;
			origin.y = offset.y + 56;
		}

		playAnim('static'); // Wow, am I really a dumbass?
	}

	override function draw():Void
	{
		for (camera in cameras)
		{
			if ((!visible || alpha == 0.0) || (!camera.visible || !camera.exists || !isOnScreen(camera)) || (null == _frame || _frame.type == flixel.graphics.frames.FlxFrame.FlxFrameType.EMPTY))
				continue;

			_frame.prepareMatrix(_matrix, flixel.graphics.frames.FlxFrame.FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
			_matrix.translate(-origin.x, -origin.y);
			_matrix.scale(scale.x, scale.y);

			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0.0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}

			getScreenPosition(_point, camera).subtractPoint(offset);
			_point.add(origin.x, origin.y);
			_matrix.translate(_point.x, _point.y);

			camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}

	public var playAnim:(String)->(Void);
}