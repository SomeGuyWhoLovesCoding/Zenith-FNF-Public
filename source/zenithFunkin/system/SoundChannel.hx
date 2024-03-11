// Don't mind this class, it's unused

package zenithFunkin.system;

import openfl.media.Sound;

typedef SoundFile =
{
	var name:String;
	var sound:Sound;
}

class SoundChannel
{
	public var channels:Array<SoundFile> = [];

	public function new():Void
	{
		channels = [];
	}

	public function playSoundFromChannel(name:String, channel:Int):Void
	{
		if (channels[channel].sound != null)
			channels[channel].sound.play();
	}
}