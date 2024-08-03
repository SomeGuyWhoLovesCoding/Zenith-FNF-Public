package zenith.scripting;

import haxe.macro.Expr;

class HScriptMacros
{
	// The switch statement gets inlined down to the case inside it at compilation
	// This was my first successful attempt at making macros for something here lmao
	macro static public function callFromScript(scr:ExprOf<HScriptFile>, id:ExprOf<CallID>, arg1:Expr, arg2:Expr):Expr
	{
		return macro
		{
			var script = $scr;

			// @:access doesn't work on macros so I have to wrap the giant switch condition with @:privateAccess
			@:privateAccess
			{
				switch id
				{
					case CREATE_PRE:
						if (script.createPre != null) script.createPre();
					case CREATE:
						if (script.create != null) script.create();
					case CREATE_POST:
						if (script.createPost != null) script.createPost();
					case UPDATE_PRE:
						if (script.updatePre != null) script.updatePre(($arg1 : Float));
					case UPDATE:
						if (script.update != null) script.update(($arg1 : Float));
					case UPDATE_POST:
						if (script.updatePost != null) script.updatePost(($arg1 : Float));
					case DESTROY:
						if (script.dest != null) script.dest();
					case DESTROY_POST:
						if (script.destroyPost != null) script.destroyPost();
					case STEP_HIT:
						if (script.stepHit != null) script.stepHit(($arg1 : Float));
					case BEAT_HIT:
						if (script.beatHit != null) script.beatHit(($arg1 : Float));
					case MEASURE_HIT:
						if (script.measureHit != null) script.measureHit(($arg1 : Float));
					case GS:
						if (script.generateSong != null) script.generateSong(($arg1 : String), (arg2 : String));
					case GS_POST:
						if (script.generateSongPost != null) script.generateSongPost(($arg1 : String), ($arg2 : String));
					case START_COUNTDOWN:
						if (script.startCountdown != null) script.startCountdown();
					case START_SONG:
						if (script.startSong != null) script.startSong();
					case END_SONG:
						if (script.endSong != null) script.endSong();
					case BOOT:
						if (script.boot != null) script.boot();
					case KD:
						if (script.keyDown != null) script.keyDown(($arg1 : Int), ($arg2 : Int));
					case KD_POST:
						if (script.keyDownPost != null) script.keyDownPost(($arg1 : Int), ($arg2 : Int));
					case KU:
						if (script.keyUp != null) script.keyUp(($arg1 : Int), ($arg2 : Int));
					case KU_POST:
						if (script.keyUpPost != null) script.keyUpPost(($arg1 : Int), ($arg2 : Int));
					case UPDATE_SCORE:
						if (script.updateScore != null) script.updateScore();
					case SND:
						if (script.setupNoteData != null) script.setupNoteData(($arg1 : NoteObject));
					case SSD:
						if (script.setupSustainData != null) script.setupSustainData(($arg1 : NoteObject));
					case NOTE_HIT:
						if (script.hitNote != null) script.hitNote(($arg1 : Int));
					case NOTE_HIT_POST:
						if (script.hitNotePost != null) script.hitNotePost(($arg1 : Int));
					case NOTE_MISS:
						if (script.missNote != null) script.missNote(($arg1 : Int));
					case NOTE_MISS_POST:
						if (script.missNotePost != null) script.missNotePost(($arg1 : Int));
					case HOLD:
						if (script.hold != null) script.hold(($arg1 : Int));
					case HOLD_POST:
						if (script.holdPost != null) script.holdPost(($arg1 : Int));
					case RELEASE:
						if (script.release != null) script.release(($arg1 : Int));
					case RELEASE_POST:
						if (script.releasePost != null) script.releasePost(($arg1 : Int));
				}
			}
		}
	}
}
