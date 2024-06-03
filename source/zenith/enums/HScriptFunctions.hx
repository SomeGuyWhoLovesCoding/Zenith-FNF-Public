package zenith.enums;

enum abstract HScriptFunctions(String)
{
	var GAME_BOOT = "onGameBoot";

	// State-wise
	var CREATE = "create";
	var UPDATE = "update";
	var DESTROY = "destroy";
	var CREATE_POST = "createPost";
	var UPDATE_POST = "updatePost";
	var DESTROY_POST = "destroyPost";
	var STEP_HIT = "onStepHit";
	var BEAT_HIT = "onBeatHit";
	var MEASURE_HIT = "onMeasureHit";

	// Gameplay-wise
	var CREATE_STAGE = "createStage";
	var CREATE_STAGE_POST = "createStagePost";
	var GENERATE_SONG = "generateSong";
	var START_COUNTDOWN = "startCountdown";
	var START_SONG = "startSong";
	var END_SONG = "endSong";
	var KEY_DOWN = "onKeyDown";
	var KEY_UP = "onKeyUp";
	var KEY_DOWN_POST = "onKeyDownPost";
	var KEY_UP_POST = "onKeyUpPost";
	var NOTE_HIT = "onNoteHit";
	var NOTE_MISS = "onNoteMiss";
	var NOTE_HIT_POST = "onNoteHitPost";
	var NOTE_MISS_POST = "onNoteMissPost";
	var NOTE_HOLD = "onHold";
	var NOTE_RELEASE = "onRelease";
	var NOTE_HOLD_POST = "onHoldPost";
	var NOTE_RELEASE_POST = "onReleasePost";
	var NEW_NOTE = "newNote";
	var SETUP_NOTE_DATA = "setupNoteData";
	var SETUP_SUSTAIN_DATA = "setupSustainData";
	var SETUP_NOTE_DATA_POST = "setupNoteDataPost";
	var SETUP_SUSTAIN_DATA_POST = "setupSustainDataPost";
}
