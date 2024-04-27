package zenith.objects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;

	public function new(image:String, x:Float = 0, y:Float = 0, scrollX:Float = 1, scrollY:Float = 1, animArray:Array<String> = null, loop:Bool = false)
	{
		super(x, y);

		if (animArray != null)
		{
			frames = Paths.getSparrowAtlas(image);
			for (i in 0...animArray.length)
			{
				var anim:String = animArray[i];
				animation.addByPrefix(anim, anim, 24, loop);
				if (null == idleAnim)
				{
					idleAnim = anim;
					inline animation.play(anim);
				}
			}
		}
		else
		{
			if (null != image)
				loadGraphic(Paths.ASSET_PATH + '/images/stage/$image.png');

			active = moves = false;
		}
		scrollFactor.set(scrollX, scrollY);
		antialiasing = true;
	}

	public function dance(?forceplay:Bool = false)
	{
		if (null != idleAnim)
		{
			animation.play(idleAnim, forceplay);
		}
	}
}