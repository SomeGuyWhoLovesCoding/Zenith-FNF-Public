package zenith.core;

import openfl.events.Event;
import openfl.display.Sprite;
import lime.media.AudioSource;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import lime.media.openal.AL;

// Just a sound class made to load audio files near-instant by streaming.
// You MUST add the sound to the sound list, or it'll cause unintential behavior.
@:access(lime.media.AudioSource)
@:access(lime._internal.backend.native.NativeAudioSource)
class Sound extends FlxBasic
{
	public var source(default, null):AudioSource = null;

	public var length:Float = 0.0;

	public var time(get, default):Float = 0.0;

	inline function get_time():Float
	{
		if (null != source)
			return source.currentTime;
		return 0.0;
	}

	public var volume:Float = 1.0;

	public var pitch(default, set):Float = 1.0;

	inline function set_pitch(value:Float):Float
	{
		if (null != source)
			return pitch = source.pitch = value;
		return 0.0;
	}

	public var mute:Bool = false;

	private var __paused(default, null):Bool = false; // For focus gain

	public var onComplete:() -> (Void);

	public var stage:Sprite;

	public function new(sourceFile:String, onComplete:() -> (Void) = null):Void
	{
		super();

		stage = new Sprite();
		stage.visible = visible = false;

		if (!sys.FileSystem.exists(sourceFile))
			return;

		source = new AudioSource(AudioBuffer.fromVorbisFile(VorbisFile.fromFile(sourceFile)));

		this.onComplete = onComplete;

		if (null != onComplete)
			source.onComplete.add(onComplete);

		length = source.length;
	}

	override public function update(elapsed:Float):Void
	{
		if (null == source || !source.__backend.playing)
			return;

		if (null != FlxG.sound)
			source.gain = FlxG.sound.muted || mute ? 0.0 : (volume * FlxG.sound.volume);
	}

	public function play(forceRestart:Bool = false, startTime:Float = 0.0):Void
		if (null != source && !__paused)
		{
			if (forceRestart)
			{
				source.stop();
				setTime(startTime);
			}
			source.play();
			if (null != stage && (!stage.hasEventListener(Event.DEACTIVATE) || !stage.hasEventListener(Event.ACTIVATE)))
			{
				stage.addEventListener(Event.DEACTIVATE, (_) -> {if (null != source) source.pitch = source.gain = 0.0;});
				stage.addEventListener(Event.ACTIVATE, (_) -> {if (null != source) source.pitch = pitch;});
			}
		}

	public function pause():Void
		if (null != source && (source.__backend.playing && !__paused))
		{
			source.pause();
		}

	public function stop():Void
		if (null != source && (source.__backend.playing && !__paused))
		{
			source.stop();
			if (null != stage)
				@:privateAccess stage.__removeAllListeners();
		}

	override public function destroy():Void
	{
		if (null != source)
		{
			source.onComplete.remove(onComplete);
			source.dispose();
			source = null;
		}

		if (null != stage && (stage.hasEventListener(Event.DEACTIVATE) || stage.hasEventListener(Event.ACTIVATE)))
			@:privateAccess stage.__removeAllListeners();

		super.destroy();
	}

	public inline function setTime(newTime:Float):Void
		if (null != source)
			source.currentTime = newTime;
}