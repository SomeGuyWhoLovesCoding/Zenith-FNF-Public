package zenith.objects.ui;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime(default, null):Float = 0;
	public var noteData(default, null):UInt = 0;
	public var mustPress(default, null):Bool = false;
	public var gfNote(default, null):Bool = false;
	public var sustainLength(default, null):UInt = 0;
	public var noteType(default, null):String = '';

	public var lane:UInt = 0;
	public var multiplier:UInt = 1;

	public var noAnimation:Bool = false;
	public var multSpeed:Float = 1;
	public var wasHit:Bool = false;
	public var tooLate:Bool = false;
	public var distance:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public static final colorArray:Array<Int> = [0xffc941d5, 0xff00ffff, 0xff0ffb3e, 0xfffa3e3e];
	public static final angleArray:Array<Float> = [0, -90, 90, 180];

	public static final prototypeNoteskin:Bool = false;

	// The offset threshold for the sustain note. Useful when you replace the noteskin with yours.
	// Default: Perfectly centered within the receptor.
	public static final SUSTAIN_NOTE_OFFSET_THRESHOLD:Float = 36.5;

	public function new()
	{
		super();

		if (prototypeNoteskin)
			makeGraphic(112, 112, 0xFFFF0000);

		// Set the note's scale to 0.7 initially and update the hitbox, don't reuse that same process each time a note, and add the animation prefixes in the constructor.

		frames = Paths.getSparrowAtlas('noteskins/Regular');
		animation.copyFrom(@:privateAccess Paths.noteAnimationHolder.animation);

		//trace('Yes');

		pixelPerfectPosition = active = false;

		inline animation.play('scroll');
	}

	override public function draw():Void
	{
		if (!exists || alpha == 0.0)
			return;

		scale.x = scale.y = 0.7;
		updateHitbox();

		inline checkEmptyFrame();

		if (_frame.type == flixel.graphics.frames.FlxFrame.FlxFrameType.EMPTY)
			return;

		if (dirty) // rarely
			calcFrame(useFramePixels);

		if (null != shader && shader is flixel.graphics.tile.FlxGraphicsShader)
			shader.setCamSize(_frame.frame.x, _frame.frame.y, _frame.frame.width, _frame.frame.height);

		for (i in 0...cameras.length)
		{
			var camera:FlxCamera = cameras[i];

			if (!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			if (isSimpleRender(camera))
				drawSimple(camera);
			else
				drawComplex(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	// Used for recycling
	public function setupNoteData(chartNoteData:Array<Int>):Note
	{
		y = -2000;
		wasHit = tooLate = false;

		strumTime = chartNoteData[0];
		noteData = chartNoteData[1];
		sustainLength = chartNoteData[2];
		lane = chartNoteData[3];
		multiplier = chartNoteData[4];

		color = colorArray[noteData];
		angle = angleArray[noteData];

		return this;
	}
}