package zenith.objects;

import flixel.math.FlxMath;

@:access(flixel.FlxSprite)
class HealthIcon extends Atlas
{
	var _scaleA(default, null):Float = 1.0;
	var _scaleB(default, null):Float = 1.0;

	public function new(character:Character)
	{
		super(Paths.image('ui/icons/${character.healthIcon}'), 2, 1);
		width = height = frameWidth = frameHeight = 150;

		// Some dumb shit I did to correct the player icon offset.
		if (character.isPlayer)
			offset.x += 150.0;

		active = moves = false;
	}

	inline public function bop():Void
	{
		_scaleA += 0.5;
		_scaleB += 0.075;
	}

	override function draw():Void
	{
		_scaleA = FlxMath.lerp(_scaleA, 1.0, FlxG.elapsed * 46.0);
		_scaleB = FlxMath.lerp(_scaleB, 0.0, FlxG.elapsed * 8.0);
		scale.x = scale.y = _scaleA + _scaleB;
		y = Gameplay.instance.hudGroup?.healthBar?.y - (60 / scale.y);

		super.draw();
	}
}
