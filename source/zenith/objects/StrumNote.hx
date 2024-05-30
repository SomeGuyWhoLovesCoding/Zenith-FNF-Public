package zenith.objects;

import flixel.math.FlxRect;
import flixel.animation.FlxAnimation;

@:access(flixel.animation.FlxAnimationController)
@:access(flixel.animation.FlxAnimation)
class StrumNote extends FlxSprite
{
	public var noteData:Int = 0;
	public var player:Int = 0;
	public var scrollMult:Float = 1.0;
	public var playable(default, set):Bool = false;

	inline function set_playable(value:Bool):Bool
	{
		animation.finishCallback = value ? null : finishCallbackFunc;
		return playable = value;
	}

	// Easter egg moment

	public var PRESS_ANIM:FlxAnimation = null;
	public var CONFIRM_ANIM:FlxAnimation = null;
	public var STATIC_ANIM:FlxAnimation = null;

	public function new(data:Int, plr:Int)
	{
		super();

		noteData = data;
		player = plr;

		frames = Paths.strumNoteAtlas;
		animation.copyFrom(Paths.strumNoteAnimationHolder.animation);

		PRESS_ANIM = animation._animations.get('pressed');
		CONFIRM_ANIM = animation._animations.get('confirm');
		STATIC_ANIM = animation._animations.get('static');

		pixelPerfectPosition = false;

		angle = NoteBase.angleArray[noteData];

		scale.x = scale.y = 0.7;

		playAnim('static'); // Wow, am I really a dumbass?
	}

	override function update(elapsed:Float):Void
	{
		animation.update(elapsed);
	}

	inline public function playAnim(anim:String):Void
	{
		active = anim != 'static';
		color = !active ? 0xffffffff : NoteBase.colorArray[noteData];

		// I swear to fucking god :sob:
		#if HXCPP_CHECK_POINTER
		animation.play(anim, true);
		#else
		if (anim == 'pressed')
			animation.curAnim = PRESS_ANIM;

		if (anim == 'confirm')
			animation.curAnim = CONFIRM_ANIM;

		if (anim == 'static')
			animation.curAnim = STATIC_ANIM;

		animation.curAnim._frameTimer = animation.curAnim.curFrame = 0;
		animation.curAnim.finished = animation.curAnim.paused = false;
		#end

		// Broken down version of updateHitbox(), basically inlining manually
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		offset.x = (frameWidth * 0.5) - 54;
		offset.y = (frameHeight * 0.5) - 56;
		origin.x = offset.x + 54;
		origin.y = offset.y + 56;
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		if (clipRect != null)
		{
			clipRect.put();
		}

		_frame = _frame.clipTo(rect, _frame);
		return clipRect = rect;
	}

	function finishCallbackFunc(anim:String):Void
	{
		if (anim != 'confirm' || (playable && !Gameplay.cpuControlled))
			return;

		#if HXCPP_CHECK_POINTER
		animation.play('static', true);
		#else
		animation.curAnim = STATIC_ANIM;
		animation.curAnim._frameTimer = animation.curAnim.curFrame = 0;
		animation.curAnim.finished = animation.curAnim.paused = false;
		#end

		active = false;
		color = 0xffffffff;

		// Broken down version of updateHitbox(), basically inlining manually
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		offset.x = (frameWidth * 0.5) - 54;
		offset.y = (frameHeight * 0.5) - 56;
		origin.x = offset.x + 54;
		origin.y = offset.y + 56;
	}
}
