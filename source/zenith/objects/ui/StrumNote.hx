package zenith.objects.ui;

class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	//public var resetAnim:Float = 0;
	public var scrollMult:Float = 1;
	public var playerStrum:Bool = false;

	public static final animArray:Array<String> = ['left', 'down', 'up', 'right'];

	public function new(data:Int, plr:Int)
	{
		super();

		noteData = data;
		player = plr;

		//trace(noteData);

		frames = Paths.getSparrowAtlas('noteskins/Regular');

		animation.addByPrefix('static', 'static');
		animation.addByPrefix('pressed', 'press', 24, false);
		animation.addByPrefix('confirm', 'confirm', 24, false);

		scale.set(0.7, 0.7);
		updateHitbox();

		pixelPerfectPosition = false;

		angle = Note.angleArray[noteData];

		inline playAnim('static'); // Wow, am I really a dumbass?
	}

	public function playAnim(anim:String):Void
	{
		color = anim == 'static' ? 0xffffffff : Note.colorArray[noteData];
		animation.play(anim, true);
		active = anim != 'static';
	}

	override function draw():Void
	{
		inline centerOrigin();
		inline centerOffsets();

		super.draw();

		if (animation.curAnim.name == 'confirm')
			if (animation.curAnim.finished && (!playerStrum || Gameplay.cpuControlled))
				playAnim('static');
	}
}