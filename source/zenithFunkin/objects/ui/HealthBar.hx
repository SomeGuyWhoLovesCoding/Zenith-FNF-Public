package zenithFunkin.objects.ui;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

class HealthBar extends FlxSpriteGroup
{
	private var __width:Int = 100;
	private var __height:Int = 10;
	private var __left:FlxSprite;
	private var __right:FlxSprite;

	public var value:Float = 1;
	public var maxValue:Float = 2;

	public function new(x:Float = 0, y:Float = 0, left:Array<Int>, right:Array<Int>, width:Int = 100, height:Int = 10, maxValue:Float = 2):Void
	{
		super(x, y);

		this.maxValue = maxValue;

		__width = width;
		__height = height;

		reloadBar(left, right);

		antialiasing = true;
		moves = false;
	}

	public function reloadBar(left:Array<Int>, right:Array<Int>):Void
	{
		if (__left != null)
			remove(__left);

		if (left.length > 1)
			add(__left = flixel.util.FlxGradient.overlayGradientOnFlxSprite(new FlxSprite(), __width, __height, left));
		else
			add(__left = new FlxSprite().makeGraphic(__width, __height, left[0]));

		__left.antialiasing = true;
		__left.pixelPerfectPosition = false;

		if (__right != null)
			remove(__right);

		if (right.length > 1)
			add(__right = flixel.util.FlxGradient.overlayGradientOnFlxSprite(new FlxSprite(), __width, __height, right));
		else
			add(__right = new FlxSprite().makeGraphic(__width, __height, right[0]));

		__right.antialiasing = true;
		__right.pixelPerfectPosition = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var v = FlxMath.bound(value / maxValue, 0, 1);

		if (__left != null)
		{
			__left.scale.x = 1 - v;
			__left.updateHitbox();
		}
		if (__right != null)
		{
			__right.scale.x = v;
			__right.updateHitbox();
			__right.x = __left.width + 340 /* Crazy math I got there :trollface: */;
		}
	}
}