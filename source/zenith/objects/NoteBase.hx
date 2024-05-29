package zenith.objects;

class NoteBase extends StaticSprite
{
	public var strumTime:Float = 0.0;
	public var noteData:Int = 0;
	public var gfNote:Bool = false;

	public var lane:Int = 0;

	public var strum:StrumNote;

	public var distance:Float = 0.0;

	public var offsetX:Int = 0;
	public var offsetY:Int = 0;

	public var direction(default, set):Float = 0.0;

	function set_direction(value:Float):Float
	{
		return direction = value;
	}

	static public var colorArray:Array<Int> = [0xffc941d5, 0xff00ffff, 0xff0ffb3e, 0xfffa3e3e];
	static public var angleArray:Array<Float> = [0.0, -90.0, 90.0, 180.0];
}
