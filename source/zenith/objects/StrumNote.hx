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

	public var parent:Strumline;

	// Easter egg moment

	public var PRESS_ANIM:FlxAnimation;
	public var CONFIRM_ANIM:FlxAnimation;
	public var STATIC_ANIM:FlxAnimation;

	public function new(data:Int, plr:Int)
	{
		super();

		noteData = data;
		player = plr;

		frames = Paths.strumNoteAtlas;
		animation.copyFrom(Paths.strumNoteAnimationHolder.animation);

		PRESS_ANIM = animation._animations['pressed'];
		CONFIRM_ANIM = animation._animations['confirm'];
		STATIC_ANIM = animation._animations['static'];

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

		width = (scale.x < 0.0 ? -scale.x : scale.x) * frameWidth;
		height = (scale.y < 0.0 ? -scale.y : scale.y) * frameHeight;
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

		width = (scale.x < 0.0 ? -scale.x : scale.x) * frameWidth;
		height = (scale.y < 0.0 ? -scale.y : scale.y) * frameHeight;
		offset.x = (frameWidth * 0.5) - 54;
		offset.y = (frameHeight * 0.5) - 56;
		origin.x = offset.x + 54;
		origin.y = offset.y + 56;
	}

	inline public function isIdle():Bool
	{
		return animation.curAnim == STATIC_ANIM;
	}
}
