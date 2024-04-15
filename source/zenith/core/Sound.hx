package;

import openfl.events.Event;
import openfl.display.Sprite;
import lime.media.AudioSource;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;

// Just a sound class made to load audio files near-instant by streaming.
// You MUST add the sound to the sound list, or it'll cause unintential behavior.
class Sound extends FlxBasic
{
	public var source(default, null):AudioSource = null;

	public var length:Float = 0.0;
	public var time:Float = 0.0;

	public var volume:Float = 1.0;

	public var pitch(default, set):Float = 1.0;

	function set_pitch(value:Float):Float
	{
		source.pitch = value;
		return pitch = value;
	}

	public var onComplete:() -> (Void);

	public var playing(default, null):Bool = false;
	public var paused(default, null):Bool = false;

	public var stage:Sprite;

	public function new(sourceFile:String, onComplete:() -> (Void) = null):Void
	{
		super();

		stage = new Sprite();
		visible = stage.visible = false;

		ID = -1;

		source = new AudioSource(AudioBuffer.fromVorbisFile(VorbisFile.fromFile(sourceFile)));

		this.onComplete = onComplete;

		if (null != onComplete)
			source.onComplete.add(onComplete);

		length = source.length;
		trace(length);
	}

	override public function update(elapsed:Float):Void
	{
		if (!playing || paused)
			return;

		if (null != FlxG.sound && null != source)
		{
			time = source.currentTime;
			source.gain = FlxG.sound.muted ? 0.0 : (volume * FlxG.sound.volume);
		}
	}

	public function play(forceRestart:Bool = false, startTime:Int = 0):Void
		if (null != source && (!playing || paused))
		{
			if (forceRestart)
				source.stop();
			else
				time = startTime;
			source.play();
			if (null != stage && (!stage.hasEventListener(Event.DEACTIVATE) || !stage.hasEventListener(Event.ACTIVATE)))
			{
				stage.addEventListener(Event.DEACTIVATE, (_) -> pause());
				stage.addEventListener(Event.ACTIVATE, (_) -> play());
			}
			playing = true;
			paused = false;
		}

	public function pause():Void
		if (null != source && (playing || !paused))
		{
			source.pause();
			playing = false;
			paused = true;
		}

	public function stop():Void
		if (null != source && playing)
		{
			source.stop();
			if (null != stage)
				@:privateAccess stage.__removeAllListeners();
			playing = paused = false;
		}

	override public function destroy():Void
	{
		if (null != source)
		{
			source.onComplete.remove(onComplete);
			source.dispose();
			source = null;
		}

		playing = paused = false;

		if (null != stage && (stage.hasEventListener(Event.DEACTIVATE) || stage.hasEventListener(Event.ACTIVATE)))
			@:privateAccess stage.__removeAllListeners();

		super.destroy();
	}

	public inline function setTime(newTime:Float):Void
		time = source.currentTime = newTime;
}