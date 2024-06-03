package zenith.enums;

enum abstract HScriptFunctions(String) to String
{
	final GAME_BOOT:String = "onGameBoot";

	// State-wise
	final CREATE:String = "create";
	final UPDATE:String = "update";
	final DESTROY:String = "destroy";
	final CREATE_POST:String = "createPost";
	final UPDATE_POST:String = "updatePost";
	final DESTROY_POST:String = "destroyPost";
	final STEP_HIT:String = "onStepHit";
	final BEAT_HIT:String = "onBeatHit";
	final MEASURE_HIT:String = "onMeasureHit";

	// Gameplay-wise
	final CREATE_STAGE:String = "createStage";
	final CREATE_STAGE_POST:String = "createStagePost";
	final GENERATE_SONG:String = "generateSong";
	final START_COUNTDOWN:String = "startCountdown";
	final START_SONG:String = "startSong";
	final END_SONG:String = "endSong";
	final KEY_DOWN:String = "onKeyDown";
	final KEY_UP:String = "onKeyUp";
	final KEY_DOWN_POST:String = "onKeyDownPost";
	final KEY_UP_POST:String = "onKeyUpPost";
	final NOTE_HIT:String = "onNoteHit";
	final NOTE_MISS:String = "onNoteMiss";
	final NOTE_HIT_POST:String = "onNoteHitPost";
	final NOTE_MISS_POST:String = "onNoteMissPost";
	final NOTE_HOLD:String = "onHold";
	final NOTE_RELEASE:String = "onRelease";
	final NOTE_HOLD_POST:String = "onHoldPost";
	final NOTE_RELEASE_POST:String = "onReleasePost";
	final NEW_NOTE:String = "newNote";
	final SETUP_NOTE_DATA:String = "setupNoteData";
	final SETUP_SUSTAIN_DATA:String = "setupSustainData";
	final SETUP_NOTE_DATA_POST:String = "setupNoteDataPost";
	final SETUP_SUSTAIN_DATA_POST:String = "setupSustainDataPost";
}
