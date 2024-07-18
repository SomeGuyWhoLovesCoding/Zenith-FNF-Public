package zenith.system;

import openfl.display.BitmapData;

@:final
class NoteskinHandler
{
	static public var strumNoteAnimationHolder:FlxSprite = new FlxSprite();
	static public var idleNote:NoteObject;
	static public var idleStrumNote:StrumNote;

	static public var noteskins:Array<Noteskin> = [];

	static public function reload(skin:String = 'Regular')
	{
		var id = @:privateAccess Noteskin.findOrCreate(noteskins, skin).id;

		strumNoteAnimationHolder.frames = Paths.getSparrowAtlas('ui/noteskins/$skin/Strums');
		strumNoteAnimationHolder.animation.addByPrefix('static', 'static', 0, false);
		strumNoteAnimationHolder.animation.addByPrefix('pressed', 'press', 12, false);
		strumNoteAnimationHolder.animation.addByPrefix('confirm', 'confirm', 24, false);

		if (idleNote == null)
			idleNote = new NoteObject(false, id);

		if (idleStrumNote == null)
			idleStrumNote = new StrumNote();

		if (idleStrumNote.parent == null)
			idleStrumNote.parent = new Strumline();

		idleStrumNote._reset();

		idleNote.active = idleStrumNote.active = idleNote.visible = idleStrumNote.visible = false;
	}
}

class Noteskin
{
	public var name:String;
	public var id:NoteState.UInt8;

	public var noteBMD:BitmapData;
	public var sustainBMD:BitmapData;

	public function new(skin:String)
	{
		changeTo(skin);
	}

	function changeTo(skin:String)
	{
		name = skin;
		noteBMD = BitmapData.fromFile(Paths.image('ui/noteskins/$skin/Note'));
		sustainBMD = BitmapData.fromFile(Paths.image('ui/noteskins/$skin/Sustain'));
	}

	static function findOrCreate(array:Array<Noteskin>, skin:String)
	{
		var arr = array;
		var name = skin;
		var len = arr.length;

		for (i in 0...len)
		{
			var skin = arr[i];

			if (skin.name == name)
			{
				return skin;
			}
		}

		var noteskin = new Noteskin(skin);
		noteskin.id = array.length;
		array.push(noteskin);
		return noteskin;
	}
}
