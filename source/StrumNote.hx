package;

import sys.FileSystem;

class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	//public var resetAnim:Float = 0;
	public var downScroll:Bool = false;

	public static final animArray:Array<String> = ['left', 'down', 'up', 'right'];

	public function new(data:Int, plr:Int)
	{
		super();

		noteData = data;
		player = plr;

		//trace(noteData);

		frames = @:privateAccess Paths.noteFrames;

		animation.addByPrefix('static', 'arrow' + animArray[noteData].toUpperCase());
		animation.addByPrefix('pressed', animArray[noteData] + ' press', 24, false);
		animation.addByPrefix('confirm', animArray[noteData] + ' confirm', 24, false);

		scale.set(0.7, 0.7);
		updateHitbox();

		antialiasing = true;
		pixelPerfectPosition = false;

		playAnim('static'); // Wow, am I really a dumbass?
	}

	public function playAnim(anim:String):Void
	{
		if (animation != null)
		{
			animation.play(anim, true);
			centerOffsets();
			centerOrigin();
		}
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null)
		{
			if (animation.curAnim.name == 'confirm')
			{
				centerOrigin();
				if (animation.curAnim.finished)
					playAnim('static');
			}
		}

		super.update(elapsed);
	}
}