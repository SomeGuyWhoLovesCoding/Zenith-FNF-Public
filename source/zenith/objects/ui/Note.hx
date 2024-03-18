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

	public static final animArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static final prototypeNoteskin:Bool = false;

	// The offset threshold for the sustain note. Useful when you replace the noteskin with yours.
	// Default: Perfectly centered within the receptor.
	public static final SUSTAIN_NOTE_OFFSET_THRESHOLD:Float = 36.5;

	public function new()
	{
		super();

		visible = false;

		if (prototypeNoteskin)
			makeGraphic(112, 112, 0xFFFF0000);

		antialiasing = true;

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
		if (exists)
		{
			if (Conductor.songPosition >= strumTime + (750 / Gameplay.instance.songSpeed)) // Remove them if they're offscreen
			{
				exists = false;
				return;
			}

			super.update(elapsed);

			followStrum(Gameplay.instance.strums.members[noteData + (mustPress ? 4 : 0)]);

			// For note hits and input

			if (mustPress)
			{
				if (isSustainNote)
					if (Conductor.songPosition >= strumTime && @:privateAccess Gameplay.instance.holdArray[noteData])
						onNoteHit();

				if (Conductor.songPosition >= strumTime + (Conductor.stepCrochet * 2) && (!wasHit && !tooLate))
					onNoteMiss();
			}
			else
				if (Conductor.songPosition >= strumTime)
					onNoteHit();
		}
	}

	public function followStrum(strum:StrumNote):Void
	{
		// Sustain scaling for song speed (even if it's changed)
		if (isSustainNote)
		{
			offsetX = SUSTAIN_NOTE_OFFSET_THRESHOLD;
			flipX = flipY = strum.scrollMult <= 0;
			// Psych engine sustain calculation moment
			scale.set(0.7, animation.curAnim.name.endsWith('end') ? 1 : (153.75 / Gameplay.SONG.bpm) * (Gameplay.instance.songSpeed * multSpeed) * Math.abs(strum.scrollMult));
			updateHitbox();
		}

		distance = 0.45 * (Conductor.songPosition - strumTime) * (Gameplay.instance.songSpeed * multSpeed);
		x = strum.x + offsetX;
		y = (strum.y + offsetY) + (-strum.scrollMult * distance) - (flipY ? (frameHeight * scale.y) - strum.height : 0);
	}

	// Used for recycling
	public function setupNoteData(chartNoteData:ChartNoteData):Note
	{
		y = -2000;
		wasHit = tooLate = false;
		visible = true;

		strumTime = chartNoteData.strumTime;
		noteData = Std.int(chartNoteData.noteData % 4);
		mustPress = chartNoteData.mustPress;
		gfNote = chartNoteData.gfNote;
		isSustainNote = chartNoteData.isSustainNote;
		sustainLength = chartNoteData.sustainLength;

		animation.play(animArray[noteData] + (isSustainNote ? (chartNoteData.isSustainEnd ? 'holdend' : 'hold') : 'Scroll'));

		return this;
	}

	// Note hit functions

	function onNoteHit():Void
	{
		if (!mustPress || isSustainNote)
			inline Gameplay.instance.strums.members[noteData + (mustPress ? 4 : 0)].playAnim('confirm');

		wasHit = true;
		exists = false;

		Gameplay.instance.health += (0.045 * (isSustainNote ? 0.5 : 1)) * (mustPress ? 1 : -1);

		if (mustPress && !isSustainNote)
			Gameplay.instance.score += 350 * Gameplay.instance.noteMult;

		if (Gameplay.noCharacters)
			return;

		var char = (mustPress ? Gameplay.instance.bf : (gfNote ? Gameplay.instance.gf : Gameplay.instance.dad));

		if (char != null)
		{
			inline char.playAnim(@:privateAccess Gameplay.instance.singAnimations[noteData], true);
			char.holdTimer = 0;
		}
	}

	function onNoteMiss():Void
	{
		tooLate = true;

		Gameplay.instance.health -= 0.045 * (isSustainNote ? 0.5 : 1);
		Gameplay.instance.score -= 100 * Gameplay.instance.noteMult;
		Gameplay.instance.misses++;

		if (Gameplay.noCharacters)
			return;

		inline Gameplay.instance.bf.playAnim(@:privateAccess Gameplay.instance.singAnimations[noteData] + 'miss', true);
		Gameplay.instance.bf.holdTimer = 0;
	}
}