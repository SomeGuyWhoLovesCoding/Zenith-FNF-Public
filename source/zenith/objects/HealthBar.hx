package zenith.objects;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;

class HealthBar extends FlxSpriteGroup
{
	private var __width:Int = 100;
	private var __height:Int = 10;
	private var __left:FlxSprite;
	private var __right:FlxSprite;

	public var top:FlxSprite;

	public var value:Float = 1;
	public var maxValue:Int = 2;

	var v(default, null):Float = 0;

	public function new(x:Float = 0, y:Float = 0, left:Array<Int>, right:Array<Int>, width:Int = 100, height:Int = 10, maxValue:Int = 2):Void
	{
		super(x, y);

		this.maxValue = maxValue;

		__width = width;
		__height = height;

		reloadBar(left, right);

		active = moves = false;
	}

	public function reloadBar(left:Array<Int>, right:Array<Int>):Void
	{
		if (__left?.exists)
			remove(__left);

		if (left.length == 1)
			add(__left = new FlxSprite().makeGraphic(__width, __height, left[0]));
		else
			add(__left = flixel.util.FlxGradient.overlayGradientOnFlxSprite(new FlxSprite(), __width, __height, left));

		if (__right?.exists)
			remove(__right);

		if (right.length == 1)
			add(__right = new FlxSprite().makeGraphic(__width, __height, right[0]));
		else
			add(__right = flixel.util.FlxGradient.overlayGradientOnFlxSprite(new FlxSprite(), __width, __height, right));
	}

	override public function update(elapsed:Float):Void {}

	override public function draw():Void
	{
		v = FlxMath.bound(value / maxValue, 0, 1);

		__left.scale.x = 1 - v;
		__left.updateHitbox();

		__right.scale.x = v;
		__right.updateHitbox();
		__right.x = __left.width + 340;

		__left.draw();
		__right.draw();

		top.draw();
	}
}
