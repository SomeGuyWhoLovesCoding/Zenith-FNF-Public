package zenith.objects;

@:access(flixel.FlxSprite)
class Note extends FlxSprite
{
	public var strumTime:Float = 0.0;
	public var noteData:Int = 0;
	public var gfNote:Bool = false;

	public var lane:Int = 0;

	public var strum:StrumNote;

	public var multSpeed:Float = 1.0;
	public var distance:Float = 0.0;
	public var direction:Float = 0.0;

	public var offsetX:Int = 0;
	public var offsetY:Int = 0;

	public var sustainLength:Float = 0.0;
	public var wasHit:Bool = false;
	public var tooLate:Bool = false;

	public var multiplier:Int = 0;

	public var onDraw:()->(Void);

	public function new():Void
	{
		super();

		onDraw = () ->
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

		moves = pixelPerfectPosition = active = false;

		scale.x = scale.y = 0.7;
		_flashRect.x = _flashRect.y = 0.0;
		_frame = Paths.noteFrame;

		_flashRect.width = frameWidth = Std.int(_frame.sourceSize.x);
		_flashRect.height = frameHeight = Std.int(_frame.sourceSize.y);

		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		offset.x = -0.5 * (width - frameWidth);
		offset.y = -0.5 * (height - frameHeight);
		_halfSize.x = origin.x = frameWidth * 0.5;
		_halfSize.y = origin.y = frameHeight * 0.5;
	}

	override function draw():Void
	{
		onDraw();
	}
}