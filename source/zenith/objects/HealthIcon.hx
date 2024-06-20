package zenith.objects;

import flixel.math.FlxMath;

@:access(flixel.FlxSprite)
class HealthIcon extends Atlas
{
	var _scale(default, null):Float = 1.0;

	public function new(character:Character)
	{
		super(Paths.image('ui/icons/${character.healthIcon}'), 2, 1);
		width = height = frameWidth = frameHeight = 150;

		// Some dumb shit I did to correct the player icon offset.
		if (character.isPlayer)
			offset.x += 150.0;

		active = false;
	}

	public function bop():Void
	{
		_scale += 0.15;
	}

	override function draw():Void
	{
		super.draw();
		_scale = FlxMath.lerp(_scale, 1.0, FlxG.elapsed * 32.0);
		scale.set(_scale, _scale);
	}
}
