package zenith.objects;

typedef UInt8 = #if cpp cpp.UInt8 #elseif hl hl.UI8 #else Int #end;
typedef UInt16 = #if cpp cpp.UInt16 #elseif hl hl.UI16 #else Int #end;

class NoteState
{
	inline static public var IDLE:UInt8 = 0;
	inline static public var HIT:UInt8 = 1;
	inline static public var MISS:UInt8 = 2;
}
