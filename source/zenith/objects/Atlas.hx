package zenith.objects;

import flixel.system.FlxAssets;

class Atlas extends FlxSprite
{
	public function new(img:FlxGraphicAsset, lenWidth:Int, lenHeight:Int):Void
	{
		super(img);

		_frame.frame.width /= lenWidth;
		_frame.frame.height /= lenHeight;
	}

	inline public function updatePosW(pos:Float):Void
	{
		_frame.frame.x = (_frame.frame.width * Std.int(pos)) % frameWidth;
	}

	inline public function updatePosH(pos:Float):Void
	{
		_frame.frame.y = (_frame.frame.height * Std.int(pos)) % frameHeight;
	}
}
