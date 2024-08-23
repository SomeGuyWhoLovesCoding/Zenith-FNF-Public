package zenith.objects;

import flixel.math.FlxRect;
import flixel.math.FlxMath;

/**
 * This is going to the shadow realms.
 */
class NoteObject extends FlxSprite
{
	// The data that is set from the chart for every time a note spawns
	public var position:Int;
	public var length:NoteState.UInt16;

	// For the sustain note
	public var isSustain:Bool;

	public var distance:Single;
	public var direction:Single;

	public var state:NoteState.UInt8;

	private var isInPool:Bool; // Internal variable for efficiently checking if this is in its pool (Thank you https443 for the idea)

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this sprite's graphic as it
	 * would be displayed. Honors scrollFactor, rotation, scale, offset and origin.
	 * @param newRect Optional output `FlxRect`, if `null`, a new one is created.
	 * @param camera  Optional camera used for scrollFactor, if null `FlxG.camera` is used.
	 * @return A globally aligned `FlxRect` that fully contains the input sprite.
	 * @since 4.11.0
	 */
	override public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera)
	{
		if (newRect == null)
			newRect = FlxRect.get();

		if (_frame == null)
			return newRect.getRotatedBounds(@:bypassAccessor angle, _scaledOrigin, newRect);

		if (camera == null)
			camera = FlxG.camera;

		if (!isSustain)
			return super.getScreenBounds(newRect, camera);

		@:bypassAccessor
		{
			newRect.x = x;
			newRect.y = y;

			var scaleX = scale.x;
			var scaleY = scale.y;

			var originX = origin.x;
			var originY = origin.y;

			_scaledOrigin.x = originX * scaleX;
			_scaledOrigin.y = originY * scaleY;

			newRect.x += (-Std.int(camera.scroll.x * scrollFactor.x) - offset.x + originX - _scaledOrigin.x);
			newRect.y += (-Std.int(camera.scroll.y * scrollFactor.y) - offset.y + originY - _scaledOrigin.y);

			newRect.width = _frame.frame.width * (scaleX < 0 ? -scaleX : scaleX);
			newRect.height = _frame.frame.height * (scaleY < 0 ? -scaleY : scaleY);
		}

		return newRect.getRotatedBounds(@:bypassAccessor angle, _scaledOrigin, newRect);
	} // Please don't remove this

	public function new(sustain:Bool, noteskin:NoteState.UInt8 = 0)
	{
		super();

		@:bypassAccessor active = moves = false;

		isSustain = sustain;
		changeNoteskin(noteskin);
	}

	public function changeNoteskin(noteskin:NoteState.UInt8)
	{
		var noteskin = NoteskinHandler.noteskins[noteskin];
		var _sustain = isSustain;
		loadGraphic(!_sustain ? noteskin.noteBMD : noteskin.sustainBMD);
	}

	inline public function renew(pos:Int, len:NoteState.UInt16)
	{
		state = NoteState.IDLE;

		position = pos;
		length = len;

		direction = 0;

		// Don't remove this. Unless you want to :trollface:
		@:bypassAccessor y = FlxG.height;
	}

	override function update(elapsed:Float) {}

	inline public function hit()
	{
		if (state != NoteState.HIT)
		{
			@:bypassAccessor exists = isSustain;
			state = NoteState.HIT;
		}
	}

	inline private function _updateNoteFrame(strum:StrumNote)
	{
		@:bypassAccessor
		{
			if (isSustain)
			{
				var _scrollMult = strum.scrollMult;

				_frame.frame.y = -length * ((Gameplay.instance.songSpeed * 0.45) / strum.scale.y);
				_frame.frame.height = (-_frame.frame.y * (_scrollMult < 0 ? -_scrollMult : _scrollMult)) + frameHeight;
				angle = direction;

				if (_scrollMult < 0)
					angle += 180;
			}

			var scaleY = scale.y;
			height = _frame.frame.height * (scaleY < 0 ? -scaleY : scaleY);

			offset.x = offset.y = 0;
			origin.x = frameWidth >> 1;
			origin.y = isSustain ? 0 : frameHeight >> 1;
		}
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		return clipRect = rect;
	}
}
