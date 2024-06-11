package zenith.objects;

import flixel.math.FlxRect;
import flixel.animation.FlxAnimation;

@:access(flixel.animation.FlxAnimationController)
@:access(flixel.animation.FlxAnimation)

class StrumNote extends FlxSprite
{
	public var noteData:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end = 0;
	public var player:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end = 0;
	public var scrollMult:Float32 = 1.0;
	public var playable(default, set):Bool = false;

	inline function set_playable(value:Bool):Bool
	{
		animation.finishCallback = value ? null : finishCallbackFunc;
		return playable = value;
	}

	public var parent:Strumline;

	public var index:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end = 0;

	public function new(data:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end, plr:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end)
	{
		super();

		noteData = data;
		player = plr;
	}

	inline public function _reset():Void
	{
		frames = Paths.strumNoteAnimationHolder.frames;
		animation.copyFrom(Paths.strumNoteAnimationHolder.animation);
		angle = NoteBase.angleArray[noteData];
		playAnim("static");
	}

	override function update(elapsed:Float):Void
	{
		animation.update(elapsed);
	}

	inline public function playAnim(anim:String):Void
	{
		active = anim != "static";
		color = !active ? 0xffffffff : NoteBase.colorArray[noteData];

		animation.play(anim, true);

		width = (scale.x < 0.0 ? -scale.x : scale.x) * frameWidth;
		height = (scale.y < 0.0 ? -scale.y : scale.y) * frameHeight;
		offset.x = (frameWidth * 0.5) - 54.0;
		offset.y = (frameHeight * 0.5) - 56.0;
		origin.x = offset.x + 54.0;
		origin.y = offset.y + 56.0;
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		if (clipRect != null)
		{
			clipRect.put();
		}

		return clipRect = rect;
	}

	function finishCallbackFunc(anim:String):Void
	{
		if (anim != "confirm" || (playable && !Gameplay.cpuControlled))
			return;

		animation.play("static", true);

		active = false;
		color = 0xffffffff;

		width = (scale.x < 0.0 ? -scale.x : scale.x) * frameWidth;
		height = (scale.y < 0.0 ? -scale.y : scale.y) * frameHeight;
		offset.x = (frameWidth * 0.5) - 54;
		offset.y = (frameHeight * 0.5) - 56;
		origin.x = offset.x + 54;
		origin.y = offset.y + 56;
	}
}
