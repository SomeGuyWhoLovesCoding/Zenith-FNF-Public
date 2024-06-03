package zenith.enums;

class HScriptFunctions
{
	static public var GAME_BOOT:String = "onGameBoot";

	// State-wise
	static public var CREATE:String = "create";
	static public var UPDATE:String = "update";
	static public var DESTROY:String = "destroy";
	static public var CREATE_POST:String = "createPost";
	static public var UPDATE_POST:String = "updatePost";
	static public var DESTROY_POST:String = "destroyPost";
	static public var STEP_HIT:String = "onStepHit";
	static public var BEAT_HIT:String = "onBeatHit";
	static public var MEASURE_HIT:String = "onMeasureHit";

	// Gameplay-wise
	static public var CREATE_STAGE:String = "createStage";
	static public var CREATE_STAGE_POST:String = "createStagePost";
	static public var GENERATE_SONG:String = "generateSong";
	static public var START_COUNTDOWN:String = "startCountdown";
	static public var START_SONG:String = "startSong";
	static public var END_SONG:String = "endSong";
	static public var KEY_DOWN:String = "onKeyDown";
	static public var KEY_UP:String = "onKeyUp";
	static public var KEY_DOWN_POST:String = "onKeyDownPost";
	static public var KEY_UP_POST:String = "onKeyUpPost";
	static public var NOTE_HIT:String = "onNoteHit";
	static public var NOTE_MISS:String = "onNoteMiss";
	static public var NOTE_HIT_POST:String = "onNoteHitPost";
	static public var NOTE_MISS_POST:String = "onNoteMissPost";
	static public var NOTE_HOLD:String = "onHold";
	static public var NOTE_RELEASE:String = "onRelease";
	static public var NOTE_HOLD_POST:String = "onHoldPost";
	static public var NOTE_RELEASE_POST:String = "onReleasePost";
	static public var NEW_NOTE:String = "newNote";
	static public var SETUP_NOTE_DATA:String = "setupNoteData";
	static public var SETUP_SUSTAIN_DATA:String = "setupSustainData";
	static public var SETUP_NOTE_DATA_POST:String = "setupNoteDataPost";
	static public var SETUP_SUSTAIN_DATA_POST:String = "setupSustainDataPost";
}
