package zenith.objects.ui;

class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	public var scrollMult:Float = 1;
	public var playerStrum:Bool = false;

	var _played:Bool = false;

	public function new(data:Int, plr:Int)
	{
		super();

		noteData = data;
		player = plr;

		frames = Paths.getSparrowAtlas('noteskins/Regular');

		animation.addByPrefix('static', 'static');
		animation.addByPrefix('pressed', 'press', 24, false);
		animation.addByPrefix('confirm', 'confirm', 24, false);

		pixelPerfectPosition = false;

		angle = Note.angleArray[noteData];

		scale.set(0.7, 0.7);

		playAnim('static'); // Wow, am I really a dumbass?

		animation.finishCallback = (anim:String) -> {
			if (anim == 'confirm' && (!playerStrum || Gameplay.cpuControlled))
				playAnim('static');
		}
	}

	inline public function playAnim(anim:String):Void
	{
		color = anim == 'static' ? 0xffffffff : Note.colorArray[noteData];

		animation.play(anim, true);

		updateHitbox();
		offset.set((frameWidth * 0.5) - 54, (frameHeight * 0.5) - 56);

		active = anim != 'static';

		_played = true;
	}

	override function draw():Void
	{
		_played = false;
		super.draw();
	}
}