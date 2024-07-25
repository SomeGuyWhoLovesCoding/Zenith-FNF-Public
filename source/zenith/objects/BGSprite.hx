package zenith.objects;

import flixel.FlxSprite;
import flixel.math.FlxRect;

class BGSprite extends FlxSprite
{
	private var idleAnim:String;

	public function new(image:String, x:Float = 0, y:Float = 0, scrollX:Float = 1, scrollY:Float = 1, animArray:Array<String> = null, loop:Bool = false)
	{
		super(x, y);

		if (animArray != null)
		{
			frames = AssetManager.getSparrowAtlas(image);
			for (i in 0...animArray.length)
			{
				var anim = animArray[i];
				animation.addByPrefix(anim, anim, 24, loop);

				if (idleAnim == null)
				{
					idleAnim = anim;
					animation.play(anim);
				}
			}
		}
		else
		{
			if (image != null) loadGraphic(AssetManager.image('stage/$image'));
			@:bypassAccessor active = moves = false;
		}
		@:bypassAccessor scrollFactor.set(scrollX, scrollY);
		antialiasing = true;
	}

	public function dance(?forceplay:Bool = false)
	{
		if (idleAnim != null)
		{
			animation.play(idleAnim, forceplay);
		}
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		return clipRect = rect;
	}
}
