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
		onDraw = () ->
		{
			if (_frame == null || alpha == 0.0 || _frame.type == FlxFrameType.EMPTY)
				return;
	
			var cameras = inline getCamerasLegacy();
			for (camera in cameras)
			{
				if (!camera.visible || !camera.exists || !isOnScreen(camera))
					continue;
	
				_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, false, false);
				_matrix.translate(-origin.x, -origin.y);
				_matrix.scale(scale.x, scale.y);
	
				if (bakedRotationAngle <= 0)
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
					_sinAngle = FlxMath.fastSin(radians);
					_cosAngle = FlxMath.fastCos(radians);
	
					if (angle != 0)
						_matrix.rotateWithTrig(_cosAngle, _sinAngle);
				}
	
				getScreenPosition(_point, camera).subtractPoint(offset);
				_point.add(origin.x, origin.y);
				_matrix.translate(_point.x, _point.y);
	
				camera.drawPixels(_frame, null, _matrix, colorTransform, blend, antialiasing, null);
	
				#if FLX_DEBUG
				if (FlxG.debugger.drawDebug)
					drawDebugOnCamera(camera);
				FlxBasic.visibleCount++;
				#end
			}
		}

		super();
		pixelPerfectPosition = active = false;
	}

	override function draw():Void
	{
		onDraw();
	}
}