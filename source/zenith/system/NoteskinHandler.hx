package zenith.system;

import openfl.display.BitmapData;

/**
 * This is going to the shadow realms.
 */
class NoteskinHandler
{
	static public var strumNoteAnimationHolder:FlxSprite = new FlxSprite();
	static public var idleNote:NoteObject;
	static public var idleStrumNote:StrumNote;

	static public var noteskins:Array<Noteskin> = [];

	static public function reload(skin:String = 'Regular')
	{
		var noteskin = new Noteskin(skin);
		noteskin.id = noteskins.length;
		noteskins.push(noteskin);

		strumNoteAnimationHolder.frames = AssetManager.getSparrowAtlas('ui/noteskins/$skin/Strums');
		strumNoteAnimationHolder.animation.addByPrefix('static', 'static', 0, false);
		strumNoteAnimationHolder.animation.addByPrefix('pressed', 'press', 12, false);
		strumNoteAnimationHolder.animation.addByPrefix('confirm', 'confirm', 24, false);

		if (idleNote == null)
			idleNote = new NoteObject(false, noteskin.id);

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
		noteBMD = AssetManager.image('ui/noteskins/$skin/Note');
		sustainBMD = AssetManager.image('ui/noteskins/$skin/Sustain');
	}
}
