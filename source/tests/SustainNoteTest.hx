package tests;

import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import lime.ui.KeyCode;

class SustainNoteTest extends FlxState
{
	var sustainNote:SustainNote;

	override function create():Void
	{
		Paths.initNoteShit();

		super.create();

		FlxG.cameras.bgColor = 0xFF999999;

		sustainNote = new SustainNote();
		//sustainNote.x = sustainNote.y = 400.0;
		sustainNote.length = 200.0;
		add(sustainNote);

		Game.onKeyDown.on(SignalEvent.KEY_DOWN, (code:Int, modifier:Int) ->
		{
			if (code == KeyCode.A)
				sustainNote.x -= 5.0;

			if (code == KeyCode.S)
				sustainNote.y += 5.0;

			if (code == KeyCode.W)
				sustainNote.y -= 5.0;

			if (code == KeyCode.D)
				sustainNote.x += 5.0;

			if (code == KeyCode.DOWN)
				sustainNote.length += 10.0;

			if (code == KeyCode.UP)
				sustainNote.length -= 10.0;

			if (code == KeyCode.LEFT)
				sustainNote.direction += 15.0;

			if (code == KeyCode.RIGHT)
				sustainNote.direction -= 15.0;

			if (code == KeyCode.SPACE)
				sustainNote.downScroll = !sustainNote.downScroll;
		});
	}
}

// You must set the ``length`` first to display, even when adding the object to the game

class SustainNote extends NoteBase
{
	public var length(default, set):Float;

	inline function set_length(len:Float):Float
	{
		_frame.frame.height = 1 - (_frame.frame.y = -(length = len) / Math.abs(scale.y)) + frameHeight;
		height = _frame.frame.height * Math.abs(scale.y);
		return len;
	}

	public var direction(default, set):Float;

	inline function set_direction(dir:Float):Float
	{
		return angle = (direction = dir) + (downScroll ? 180.0 : 0.0);
	}

	public var downScroll(default, set):Bool = false;

	inline function set_downScroll(ds:Bool):Bool
	{
		angle = direction + ((downScroll = ds) ? 180.0 : 0.0); // For downscroll display, don't remove
		return ds;
	}

	public function new():Void
	{
		super();
		active = false;
		_frame = Paths.sustainNoteFrame;
		frameWidth = Std.int(_frame.frame.width);
		frameHeight = Std.int(_frame.frame.height);
		offset.x = -0.5 * ((frameWidth * 0.7) - frameWidth);
		origin.x = frameWidth * 0.5;
		origin.y = offset.y = 0.0;
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
			return inline newRect.getRotatedBounds(angle, _scaledOrigin, newRect);

		if (camera == null)
			camera = FlxG.camera;

		newRect.x = x;
		newRect.y = y;

		_scaledOrigin.x = origin.x * scale.x;
		_scaledOrigin.y = origin.y * scale.y;

		newRect.x += (-Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x);
		newRect.y += (-Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y);

		newRect.width = _frame.frame.width * Math.abs(scale.x);
		newRect.height = _frame.frame.height * Math.abs(scale.y);

		return inline newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}

	override function set_height(value:Float):Float
	{
		visible = value > 0.0;
		return height = value;
	}
}