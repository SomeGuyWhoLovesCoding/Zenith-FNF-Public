package zenith.objects;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

class HealthBar extends FlxSpriteGroup
{
	private var __width:Int = 100;
	private var __height:Int = 10;
	private var __left:FlxSprite = null;
	private var __right:FlxSprite = null;

	public var value:Float = 1.0;
	public var maxValue:Float = 2.0;

	var v(default, null):Float = 0.0;

	public function new(x:Float = 0.0, y:Float = 0.0, left:Array<Int>, right:Array<Int>, width:Int = 100, height:Int = 10, maxValue:Float = 2.0):Void
	{
		super(x, y);

		this.maxValue = maxValue;

		__width = width;
		__height = height;

		reloadBar(left, right);

		moves = false;
	}

	public function reloadBar(left:Array<Int>, right:Array<Int>):Void
	{
		if (null != __left)
			remove(__left);

		if (left.length > 1)
			add(__left = flixel.util.FlxGradient.overlayGradientOnFlxSprite(new FlxSprite(), __width, __height, left));
		else
			add(__left = new FlxSprite().makeGraphic(__width, __height, left[0]));

		if (null != __right)
			remove(__right);

		if (right.length > 1)
			add(__right = flixel.util.FlxGradient.overlayGradientOnFlxSprite(new FlxSprite(), __width, __height, right));
		else
			add(__right = new FlxSprite().makeGraphic(__width, __height, right[0]));

		__left.pixelPerfectPosition = __right.pixelPerfectPosition = false;
	}

	override public function update(elapsed:Float):Void
	{
		v = FlxMath.bound(value / maxValue, 0.0, 1.0);

		__left.scale.x = 1.0 - v;
		__left.updateHitbox();

		__right.scale.x = v;
		__right.updateHitbox();
		__right.x = __left.width + 340.0;
	}
}
