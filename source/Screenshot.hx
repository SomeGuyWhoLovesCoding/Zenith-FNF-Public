package;

class Screenshot
{
	public static function capture(screen:Dynamic = null,
		surface:openfl.geom.Rectangle = null, fileName:String = "temporary")
	{
		var img = lime.app.Application.current.window.readPixels(new lime.math.Rectangle(
			FlxG.scaleMode.offset.x, FlxG.scaleMode.offset.y,
			FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));

		sys.io.File.saveBytes(fileName + ".png", img.encode());

		openfl.system.System.gc(); // Prevent memory leaks
	}
}