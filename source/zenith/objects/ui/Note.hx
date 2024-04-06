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

	public static final animArray:Array<String> = ['purple', 'blue', 'green', 'red'];

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

		frames = @:privateAccess Paths.noteFrames;
		animation.copyFrom(@:privateAccess Paths.noteAnimation);

		scale.set(0.7, 0.7);
		updateHitbox();

		//trace('Yes');

		pixelPerfectPosition = false;
	}

	override public function update(elapsed:Float):Void
	{
	}

	// Used for recycling
	public function setupNoteData(chartNoteData:ChartNoteData):Note
	{
		y = -2000;
		wasHit = tooLate = false;

		strumTime = chartNoteData.strumTime;
		noteData = Std.int(chartNoteData.noteData % 4);
		mustPress = chartNoteData.mustPress;
		gfNote = chartNoteData.gfNote;
		isSustainNote = chartNoteData.isSustainNote;
		sustainLength = chartNoteData.sustainLength;

		animation.play(animArray[noteData] + (isSustainNote ? (chartNoteData.isSustainEnd ? 'holdend' : 'hold') : 'Scroll'));

		cameras = [isSustainNote ? Gameplay.instance.hudCameraBelow : Gameplay.instance.hudCamera];

		offsetX = isSustainNote ? SUSTAIN_NOTE_OFFSET_THRESHOLD : 0;

		return this;
	}
}