package zenith.core;

class SignalEvent
{
	inline static public var KEY_DOWN:SignalType.SignalType2<((Int), (Int)) -> (Void), ((Int)), ((Int))> = "key_down";
	inline static public var KEY_UP:SignalType.SignalType2<((Int), (Int)) -> (Void), ((Int)), ((Int))> = "key_up";
}
