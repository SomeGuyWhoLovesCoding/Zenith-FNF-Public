package zenith.objects.ui;

using StringTools;

typedef ChartNoteData =
{
	strumTime:Float,
	noteData:Int,
	mustPress:Bool,
	noteType:String,
	gfNote:Bool,
	isSustainNote:Bool,
	isSustainEnd:Bool,
	sustainLength:Float,
	noAnimation:Bool
}

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var strumTime(default, null):Float = 0;
	public var noteData(default, null):Int = 0;
	public var mustPress(default, null):Bool = false;
	public var gfNote(default, null):Bool = false;
	public var isSustainNote(default, null):Bool = false;
	public var sustainLength(default, null):Float = 0;
	public var noteType(default, null):String = '';

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

		scale.set(0.7, 0.7);
		updateHitbox();

		//trace('Yes');

		pixelPerfectPosition = active = false;
	}

	override public function update(elapsed:Float):Void
	{
	}

	override public function draw():Void
	{
		inline centerOrigin();
		inline centerOffsets();

		super.draw();
	}

	// Used for recycling
	public function setupNoteData(chartNoteData:ChartNoteData):Note
	{
		y = -2000;
		wasHit = tooLate = false;

		strumTime = chartNoteData.strumTime;
		noteData = inline Std.int(chartNoteData.noteData % 4);
		mustPress = chartNoteData.mustPress;
		gfNote = chartNoteData.gfNote;
		isSustainNote = chartNoteData.isSustainNote;
		sustainLength = chartNoteData.sustainLength;

		color = colorArray[noteData];
		angle = isSustainNote ? 0 : angleArray[noteData];

		inline animation.play(isSustainNote ? (chartNoteData.isSustainEnd ? 'tail' : 'piece') : 'scroll');

		cameras = [isSustainNote ? Gameplay.instance.hudCameraBelow : Gameplay.instance.hudCamera];

		offsetX = isSustainNote ? SUSTAIN_NOTE_OFFSET_THRESHOLD : 0;

		return this;
	}
}