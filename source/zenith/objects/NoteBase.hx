package zenith.objects;

class NoteBase extends FlxSprite
{
	public var strumTime:Float = 0.0;
	public var noteData:Int = 0;
	public var gfNote:Bool = false;

	public var lane:Int = 0;

	public var strum:StrumNote;

	public var multSpeed:Float = 1.0;
	public var distance:Float = 0.0;

	public var offsetX:Int = 0;
	public var offsetY:Int = 0;

	static public var colorArray:Array<Int> = [0xffc941d5, 0xff00ffff, 0xff0ffb3e, 0xfffa3e3e];
	static public var angleArray:Array<Float> = [0.0, -90.0, 90.0, 180.0];

	public function new():Void
	{
		super();
		pixelPerfectPosition = active = false;
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
}