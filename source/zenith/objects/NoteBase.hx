package zenith.objects;

class NoteBase extends StaticSprite
{
	public var strumTime:Float32 = 0.0;
	public var noteData:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end = 0;
	public var gfNote:Bool = false;

	public var lane:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end = 0;

	public var strum:StrumNote;

	public var targetCharacter:Character;

	public var distance:Float32 = 0.0;

	public var offsetX:#if cpp cpp.Int16 #else Int #end = 0;
	public var offsetY:#if cpp cpp.Int16 #else Int #end = 0;

	public var direction(default, set):Float32 = 0.0;

	function set_direction(value:Float32):Float32
	{
		return direction = value;
	}

	static public var colorArray:Array<Int> = [0xffc941d5, 0xff00ffff, 0xff0ffb3e, 0xfffa3e3e];
	static public var angleArray:Array<Float32> = [0.0, -90.0, 90.0, 180.0];
}
