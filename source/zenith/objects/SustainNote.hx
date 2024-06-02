package zenith.objects;

import flixel.math.FlxRect;

class SustainNote extends NoteBase
{
	public var length:Float = 0.0;
	public var state:NoteState = IDLE;

	override function set_direction(dir:Float):Float
	{
		return angle = (direction = dir) + (downScroll ? 180.0 : 0.0);
	}

	public var downScroll(default, set):Bool = false;

	inline function set_downScroll(ds:Bool):Bool
	{
		angle = direction + ((downScroll = ds) ? 180.0 : 0.0); // For downscroll display, don't remove
		return ds;
	}

	override function draw():Void
	{
		if (null != _frame)
		{
			_frame.frame.height = (1 - (_frame.frame.y = -length * (((null != Gameplay.SONG ? Gameplay.SONG.info.speed : 1.0) *
				0.6428571428571431) /* What the hell? */ / (strum.scale.y * 1.428571428571429))) * (strum.scrollMult < 0.0 ? -strum.scrollMult : strum.scrollMult)) + frameHeight;
			height = _frame.frame.height * (scale.y < 0.0 ? -scale.y : scale.y);
		}
		super.draw();
	}

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this sprite's graphic as it
	 * would be displayed. Honors scrollFactor, rotation, scale, offset and origin.
	 * @param newRect Optional output `FlxRect`, if `null`, a new one is created.
	 * @param camera  Optional camera used for scrollFactor, if null `FlxG.camera` is used.
	 * @return A globally aligned `FlxRect` that fully contains the input sprite.
	 * @since 4.11.0
	 */
	override public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (newRect == null)
			newRect = FlxRect.get();

		if (_frame == null)
			return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);

		if (camera == null)
			camera = FlxG.camera;

		newRect.x = x;
		newRect.y = y;

		_scaledOrigin.x = origin.x * scale.x;
		_scaledOrigin.y = origin.y * scale.y;

		newRect.x += (-Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x);
		newRect.y += (-Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y);

		newRect.width = _frame.frame.width * (scale.x < 0.0 ? -scale.x : scale.x);
		newRect.height = _frame.frame.height * (scale.y < 0.0 ? -scale.y : scale.y);

		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}
}
