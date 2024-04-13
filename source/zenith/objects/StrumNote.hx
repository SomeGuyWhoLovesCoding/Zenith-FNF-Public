package zenith.objects;

@:access(flixel.animation.FlxAnimationController)
@:access(flixel.animation.FlxAnimation)
class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	public var scrollMult:Float = 1;
	public var playerStrum(default, set):Bool = false;

	inline function set_playerStrum(value:Bool):Bool
	{
		animation.finishCallback = value ? null : (anim:String) ->
		{
			if (anim == 'confirm' && (!playerStrum || Gameplay.cpuControlled))
				playAnim('static');
		}
		return playerStrum = value;
	}

	public function new(data:Int, plr:Int)
	{
		super();

		noteData = data;
		player = plr;

		frames = @:privateAccess Paths.strumNoteAnimationHolder.frames;
		animation.copyFrom(@:privateAccess Paths.strumNoteAnimationHolder.animation);

		pixelPerfectPosition = false;

		angle = NoteBase.angleArray[noteData];

		scale.x = scale.y = 0.7;

		playAnim = (anim:String) ->
		{
			color = anim == 'static' ? 0xffffffff : NoteBase.colorArray[noteData];

			(animation.curAnim = animation._animations.get(anim))._frameTimer = animation.curAnim.curFrame = 0;
			animation.curAnim.finished = animation.curAnim.paused = !(active = anim != 'static');

			// Broken down version of updateHitbox(), basically inlining manually
			width = Math.abs(scale.x) * frameWidth;
			height = Math.abs(scale.y) * frameHeight;
			offset.x = (frameWidth * 0.5) - 54;
			offset.y = (frameHeight * 0.5) - 56;
			origin.x = offset.x + 54;
			origin.y = offset.y + 56;
		}

		playAnim('static'); // Wow, am I really a dumbass?
	}

	public var playAnim:(String)->(Void);
}