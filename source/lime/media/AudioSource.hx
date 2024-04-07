package lime.media;

import lime.app.Event;
import lime.media.openal.AL;
import lime.media.openal.ALSource;
import lime.math.Vector4;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AudioSource
{
	public var onComplete:Event<Void->Void> = new Event<Void->Void>();
	public var buffer:AudioBuffer;
	public var currentTime(get, set):Float;
	public var gain(get, set):Float;
	public var length(get, set):Float;
	public var loops(get, set):Int;
	public var pitch(get, set):Float;
	public var offset:Int;
	public var position(get, set):Vector4;

	private var __backend:AudioSourceBackend;

	public function new(buffer:AudioBuffer = null, offset:Int = 0, length:Float = 0, loops:Int = 0)
	{
		this.buffer = buffer;
		this.offset = offset;

		__backend = new AudioSourceBackend(this);

		if (length != 0.0)
			this.length = length;

		this.loops = loops;

		if (buffer != null)
			init();
	}
	
	inline public function dispose():Void
		__backend.dispose();
	
	inline private function init():Void
		__backend.init();
	
	inline public function play():Void
		__backend.play();
	
	inline public function pause():Void
		__backend.pause();
	
	inline public function stop():Void
		__backend.stop();
	
	// Get & Set Methods
	inline private function get_currentTime():Float
		return __backend.getCurrentTime();
	
	inline private function set_currentTime(value:Float):Float
		return __backend.setCurrentTime(value);
	
	inline private function get_gain():Float
		return __backend.getGain();
	
	inline private function set_gain(value:Float):Float
		return __backend.setGain(value);
	
	inline private function get_length():Float
		return __backend.getLength();
	
	inline private function set_length(value:Float):Float
		return __backend.setLength(value);
	
	inline private function get_loops():Int
		return __backend.getLoops();
	
	inline private function set_loops(value:Int):Int
		return __backend.setLoops(value);
	
	inline private function get_pitch():Float
		return __backend.getPitch();
	
	inline private function set_pitch(value:Float):Float
		return __backend.setPitch(value);
	
	inline private function get_position():Vector4
		return __backend.getPosition();
	
	inline private function set_position(value:Vector4):Vector4
		return __backend.setPosition(value);
}

#if flash
private typedef AudioSourceBackend = lime._internal.backend.flash.FlashAudioSource;
#elseif (js && html5)
private typedef AudioSourceBackend = lime._internal.backend.html5.HTML5AudioSource;
#else
private typedef AudioSourceBackend = lime._internal.backend.native.NativeAudioSource;
#end
