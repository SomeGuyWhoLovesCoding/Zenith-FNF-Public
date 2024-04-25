package zenith.objects;

@:access(flixel.animation.FlxAnimationController)
@:access(flixel.animation.FlxAnimation)
class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	public var scrollMult:Float = 1.0;
	public var playerStrum(default, set):Bool = false;

	public var colorArray:Array<Int> = [0xffc941d5, 0xff00ffff, 0xff0ffb3e, 0xfffa3e3e];
	public var angleArray:Array<Float> = [0.0, -90.0, 90.0, 180.0];

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
		animation.copyFrom(Paths.strumNoteAnimationHolder.animation);

		pixelPerfectPosition = false;

		angle = angleArray[noteData];

		scale.x = scale.y = 0.7;

		playAnim = (anim:String) ->
		{
			color = anim == 'static' ? 0xffffffff : colorArray[noteData];

			(animation.curAnim = animation._animations.get(anim))._frameTimer = animation.curAnim.curFrame = 0;
			animation.curAnim.finished = animation.curAnim.paused = !(active = anim != 'static');

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
			if ((visible && alpha != 0.0) || (camera.visible && camera.exists && isOnScreen(camera)) && (null != _frame && _frame.type != flixel.graphics.frames.FlxFrame.FlxFrameType.EMPTY))
			{
				_frame.prepareMatrix(_matrix, flixel.graphics.frames.FlxFrame.FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
				inline _matrix.translate(-origin.x, -origin.y);
				inline _matrix.scale(scale.x, scale.y);
	
				if (bakedRotationAngle <= 0)
				{
					inline updateTrig();
	
					if (angle != 0.0)
						inline _matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}
	
				getScreenPosition(_point, camera).subtractPoint(offset);
				_point.add(origin.x, origin.y);
				inline _matrix.translate(_point.x, _point.y);
	
				camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	
				#if FLX_DEBUG
				FlxBasic.visibleCount++;
				#end
			}
		}
	}

	public var playAnim:(String)->(Void);
}