package tests;

import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import lime.ui.KeyCode;

class SustainNoteTest extends FlxState
{
	var sustainNote:SustainNote;

	override function create():Void
	{
		Paths.initNoteShit();

		super.create();

		FlxG.cameras.bgColor = 0xFF999999;

		sustainNote = new SustainNote();
		// sustainNote.scale.x = sustainNote.scale.y = 0.7;
		sustainNote.downScroll = false;
		sustainNote.strum = Paths.idleStrumNote;
		sustainNote.setFrame(Paths.sustainNoteFrame);
		sustainNote.origin.x = sustainNote.frameWidth * 0.5;
		sustainNote.offset.x = -0.5 * ((sustainNote.frameWidth * 0.7) - sustainNote.frameWidth);
		sustainNote.origin.y = sustainNote.offset.y = 0.0;
		sustainNote.x = sustainNote.y = 400.0;
		sustainNote.length = 0.0;
		add(sustainNote);

		Main.game.onKeyDown.on(SignalEvent.KEY_DOWN, (code:Int, modifier:Int) ->
		{
			if (code == KeyCode.A)
				sustainNote.x -= 5.0;

			if (code == KeyCode.S)
				sustainNote.y += 5.0;

			if (code == KeyCode.W)
				sustainNote.y -= 5.0;

			if (code == KeyCode.D)
				sustainNote.x += 5.0;

			if (code == KeyCode.DOWN)
				sustainNote.length += 10.0;

			if (code == KeyCode.UP)
				sustainNote.length -= 10.0;

			if (code == KeyCode.LEFT)
				sustainNote.direction += 15.0;

			if (code == KeyCode.RIGHT)
				sustainNote.direction -= 15.0;

			if (code == KeyCode.SPACE)
				sustainNote.downScroll = !sustainNote.downScroll;

			if (code == KeyCode.J)
				sustainNote.mult -= 0.1;

			if (code == KeyCode.I)
				sustainNote.mult += 0.1;
		});
	}
}
// You must set the ``length`` first to display, even when adding the object to the game
