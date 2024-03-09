package;

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
	prevNote:ChartNoteData,
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
	public var prevNote:Note;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var onNoteHit:Note->Void;
	public var onNoteMiss:Note->Void;

	public static final animArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static final prototypeNoteskin:Bool = false;

	// The offset threshold for the sustain note. Useful when you replace the noteskin with yours.
	// Default: Perfectly centered within the receptor.
	public static final SUSTAIN_NOTE_OFFSET_THRESHOLD:Float = 35;

	public function new(time:Float, data:Int, sustainNote:Bool = false)
	{
		super();

		y = -2000;

		frames = @:privateAccess Paths.noteFrames;

		strumTime = time;
		noteData = data;
		isSustainNote = sustainNote;

		if (prototypeNoteskin)
			makeGraphic(112, 112, 0xFFFF0000);

		antialiasing = true;

		// Set the note's scale to 0.7 initially and update the hitbox, don't reuse that same process each time a note, and add the animation prefixes in the constructor.

		scale.set(0.7, 0.7);
		updateHitbox();

		for (d in 0...4)
		{
			animation.addByPrefix(animArray[d] + 'holdend', animArray[d] + ' hold end0');
			animation.addByPrefix(animArray[d] + 'hold', animArray[d] + ' hold piece0');
			animation.addByPrefix(animArray[d] + 'Scroll', animArray[d] + '0');
		}
	}

	public function followStrum(strum:StrumNote):Void
	{
		distance = 0.45 * (Conductor.songPosition - strumTime) * (PlayState.instance.songSpeed * multSpeed);
		x = strum.x + offsetX;
		y = (strum.y + offsetY) + (1 * (strum.downScroll ? distance : -distance)) - (strum.downScroll ? (frameHeight * scale.y) - strum.height : 0);

		// Sustain scaling for song speed (even if it's changed)
		if (isSustainNote)
		{
			offsetX = SUSTAIN_NOTE_OFFSET_THRESHOLD;
			flipX = flipY = strum.downScroll;
			scale.set(0.7, animation.curAnim.name.endsWith('end') ? 1 : Conductor.stepCrochet * 0.0105 * (PlayState.instance.songSpeed * multSpeed));
			updateHitbox();
		}
	}

	public function hit(remove:Bool = false):Void
	{
		if (wasHit)
			return;

		if (!isSustainNote)
			visible = false;

		if (remove)
		{
			wasHit = true;
			return;
		}

		if (onNoteHit != null)
			onNoteHit(this);

		wasHit = true;
	}

	public function miss():Void
	{
		if (onNoteMiss != null)
			onNoteMiss(this);

		tooLate = true;
	}

	// Used for recycling
	private function setupNoteData(chartNoteData:ChartNoteData):Note
	{
		active = pixelPerfectPosition = false; // Don't make an update call of this for the note group

		strumTime = chartNoteData.strumTime;
		noteData = Std.int(chartNoteData.noteData % 4);
		mustPress = chartNoteData.mustPress;
		gfNote = chartNoteData.gfNote;
		isSustainNote = chartNoteData.isSustainNote;
		sustainLength = chartNoteData.sustainLength;

		y = -2000;

		if (isSustainNote)
			alpha = 0.6;

		animation.play(animArray[noteData] + (isSustainNote ? (chartNoteData.isSustainEnd ? 'holdend' : 'hold') : 'Scroll'));

		return this;
	}
}