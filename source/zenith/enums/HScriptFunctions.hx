package zenith.enums;

enum abstract HScriptFunctions(String) from String to String
{
	var GAME_BOOT:String = "onGameBoot";

	// State-wise
	var CREATE:String = "create";
	var UPDATE:String = "update";
	var DESTROY:String = "destroy";
	var CREATE_POST:String = "createPost";
	var UPDATE_POST:String = "updatePost";
	var DESTROY_POST:String = "destroyPost";
	var STEP_HIT:String = "onStepHit";
	var BEAT_HIT:String = "onBeatHit";
	var MEASURE_HIT:String = "onMeasureHit";

	// Gameplay-wise
	var CREATE_STAGE:String = "createStage";
	var CREATE_STAGE_POST:String = "createStagePost";
	var GENERATE_SONG:String = "generateSong";
	var START_COUNTDOWN:String = "startCountdown";
	var START_SONG:String = "startSong";
	var END_SONG:String = "endSong";
	var MOVE_CAMERA:String = "moveCamera";
	var KEY_DOWN:String = "onKeyDown";
	var KEY_UP:String = "onKeyUp";
	var KEY_DOWN_POST:String = "onKeyDownPost";
	var KEY_UP_POST:String = "onKeyUpPost";
	var NOTE_HIT:String = "onNoteHit";
	var NOTE_MISS:String = "onNoteMiss";
	var NOTE_HIT_POST:String = "onNoteHitPost";
	var NOTE_MISS_POST:String = "onNoteMissPost";
	var NOTE_HOLD:String = "onHold";
	var NOTE_RELEASE:String = "onRelease";
	var NOTE_HOLD_POST:String = "onHoldPost";
	var NOTE_RELEASE_POST:String = "onReleasePost";
	var NEW_NOTE:String = "newNote";
	var SETUP_NOTE_DATA:String = "setupNoteData";
	var SETUP_SUSTAIN_DATA:String = "setupSustainData";
	var SETUP_NOTE_DATA_POST:String = "setupNoteDataPost";
	var SETUP_SUSTAIN_DATA_POST:String = "setupSustainDataPost";
}
