package zenithFunkin.objects.ui;

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
	public var wasHit(default, null):Bool = false;
	public var tooLate(default, null):Bool = false;
	public var isSustainNote(default, null):Bool = false;
	public var sustainLength(default, null):Float = 0;
	public var distance(default, null):Float = 0;
	public var noteType(default, null):String = '';
	public var noAnimation:Bool = false;
	public var multSpeed:Float = 1;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var onNoteHit:Note->Void;
	public var onNoteMiss:Note->Void;

	public static final animArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static final prototypeNoteskin:Bool = false;

	// The offset threshold for the sustain note. Useful when you replace the noteskin with yours.
	// Default: Perfectly centered within the receptor.
	public static final SUSTAIN_NOTE_OFFSET_THRESHOLD:Float = 36.5;

	public function new()
	{
		super();

		y = -2000;

		if (prototypeNoteskin)
			makeGraphic(112, 112, 0xFFFF0000);

		antialiasing = true;

		// Set the note's scale to 0.7 initially and update the hitbox, don't reuse that same process each time a note, and add the animation prefixes in the constructor.

		frames = @:privateAccess Paths.noteFrames;
		animation.copyFrom(@:privateAccess Paths.noteAnimation);

		scale.set(0.7, 0.7);
		updateHitbox();

		//trace('Yes');
	}

	public function followStrum(strum:StrumNote):Void
	{
		// Sustain scaling for song speed (even if it's changed)
		if (isSustainNote)
		{
			offsetX = SUSTAIN_NOTE_OFFSET_THRESHOLD;
			flipX = flipY = strum.scrollMult <= 0;
			scale.set(0.7, animation.curAnim.name.endsWith('end') ? 1 : Conductor.stepCrochet * 0.0105 * (Gameplay.instance.songSpeed * multSpeed) * Math.abs(strum.scrollMult));
			updateHitbox();
		}

		distance = 0.45 * (Conductor.songPosition - strumTime) * (Gameplay.instance.songSpeed * multSpeed);
		x = strum.x + offsetX;
		y = (strum.y + offsetY) + (-strum.scrollMult * distance) - (flipY ? (frameHeight * scale.y) - strum.height : 0);
	}

	public function hit():Void
	{
		if (wasHit)
			return;

		if (null != onNoteHit)
			onNoteHit(this);

		wasHit = true;
	}

	public function miss():Void
	{
		if (tooLate)
			return;

		if (null != onNoteMiss)
			onNoteMiss(this);

		tooLate = true;
	}

	// Used for recycling
	private function setupNoteData(chartNoteData:ChartNoteData):Note
	{
		wasHit = tooLate = active = pixelPerfectPosition = false; // Don't make an update call of this for the note group

		strumTime = chartNoteData.strumTime;
		noteData = Std.int(chartNoteData.noteData % 4);
		mustPress = chartNoteData.mustPress;
		gfNote = chartNoteData.gfNote;
		isSustainNote = chartNoteData.isSustainNote;
		sustainLength = chartNoteData.sustainLength;

		animation.play(animArray[noteData] + (isSustainNote ? (chartNoteData.isSustainEnd ? 'holdend' : 'hold') : 'Scroll'));

		return this;
	}
}