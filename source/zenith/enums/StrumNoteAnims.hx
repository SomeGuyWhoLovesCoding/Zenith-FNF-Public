package zenith.enums;

enum abstract StrumNoteAnims(String) from String to String
{
	var HIT:String = "confirm";
	var IDLE:String = "static";
	var PRESS:String = "pressed";
}