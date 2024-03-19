package zenith.system.ffmpeg;

import sys.io.Process;

using StringTools;

class RenderMode
{
	private static var process(default, null):Process;

	private static var videoPath:String = '';

	public static function create(path:String):Void
	{
		if (!sys.FileSystem.exists('ffmpeg.exe'))
			throw "\"ffmpeg.exe\" not found!";

		videoPath = path;

		process = new Process('ffmpeg', [
			'-v', 'quiet', '-y', '-f', 'rawvideo', '-crf', '0', '-pix_fmt', 'rgba', '-s',
			lime.app.Application.current.window.width + 'x' + lime.app.Application.current.window.height, '-r', '60',
			'-i', '-', '-c:v', 'libx264', videoPath + ".mp4"
		]);

		lime.app.Application.current.window.onClose.add(stopError);
		FlxG.autoPause = false;
	}

	public static function pipeFrame():Void
	{
		var img = lime.app.Application.current.window.readPixels(new lime.math.Rectangle(FlxG.scaleMode.offset.x, FlxG.scaleMode.offset.y, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));
		var bytes = img.getPixels(new lime.math.Rectangle(0, 0, img.width, img.height));
		process.stdin.writeBytes(bytes, 0, bytes.length);
	}

	// This function also called when you close the window
	public function stopError():Void
	{
		process.stdin.close();
		process.close();
		trace("Error: Cannot save video.");
	}
	
	public static function stop():Void
	{
		process.stdin.close();
		process.close();
		trace("Saved to \"" + videoPath + ".mp4\"");
		FlxG.autoPause = true;
	}
}