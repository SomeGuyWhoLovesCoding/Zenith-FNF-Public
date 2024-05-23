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
		animation.finishCallback = value ? null : (anim:(String)) ->
		{
			if (anim == 'confirm' && (!playable || Gameplay.cpuControlled))
				playAnim('static');
		}
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

		playAnim = (anim:String) ->
		{
			color = anim == 'static' ? 0xffffffff : NoteBase.colorArray[noteData];

			// I swear to fucking god bro, I'll find a solution to this for HXCPP_CHECK_POINTER
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
			animation.curAnim.finished = animation.curAnim.paused = !(active = anim != 'static');
			#end
			active = anim != 'static';

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

	override function draw():Void
	{
		for (camera in cameras)
		{
			if ((!visible || alpha == 0.0) || (!camera.visible || !camera.exists || !isOnScreen(camera)) || (null == _frame || _frame.type == flixel.graphics.frames.FlxFrame.FlxFrameType.EMPTY))
				continue;

			_frame.prepareMatrix(_matrix, flixel.graphics.frames.FlxFrame.FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
			_matrix.translate(-origin.x, -origin.y);
			_matrix.scale(scale.x, scale.y);

			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0.0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}

			getScreenPosition(_point, camera).subtractPoint(offset);
			_point.add(origin.x, origin.y);
			_matrix.translate(_point.x, _point.y);

			camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}
	}

	public var playAnim:(String)->(Void);

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		return clipRect = rect;
	}
}