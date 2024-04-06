package zenith.core;

import lime.ui.KeyCode;

class SaveData
{
	static public var contents:SaveFile = {
		preferences: {
			downScroll: false,
			smoothHealth: false,
			ghostTapping: false,
			hideHUD: false,
			noCharacters: false,
			antialiasing: false,
			fps: 480
		},
		controls: {
			GAMEPLAY_BINDS: [
				KeyCode.A,
				KeyCode.S,
				KeyCode.UP,
				KeyCode.RIGHT
			],
			LEFT: KeyCode.LEFT,
			DOWN: KeyCode.DOWN,
			UP: KeyCode.UP,
			RIGHT: KeyCode.RIGHT,
			ACCEPT: KeyCode.RETURN,
			BACK: KeyCode.ESCAPE,
			RESET: KeyCode.DELETE,
			CONTROL: KeyCode.LEFT_CTRL
		},
		extraData: null
	};

	static public function reloadSave():Void
	{
		//contents = (sys.io.File.getContent('savedata.sav') : SaveFile);
		if (!sys.FileSystem.exists('savedata.sav'))
			inline sys.io.File.saveContent('savedata.sav', '');
		// WIP
	}

	static public function saveContent():Void
	{
		// WIP
	}
}

typedef SaveFile =
{
	var preferences:PreferencesData;
	var controls:ControlsData;
	var extraData:Dynamic;
}

typedef PreferencesData =
{
	var downScroll:Bool;
	var smoothHealth:Bool;
	var ghostTapping:Bool;
	var hideHUD:Bool;
	var noCharacters:Bool;
	var antialiasing:Bool;
	var fps:Int;
}

typedef ControlsData =
{
	var GAMEPLAY_BINDS:Array<KeyCode>;
	var LEFT:KeyCode;
	var DOWN:KeyCode;
	var UP:KeyCode;
	var RIGHT:KeyCode;
	var ACCEPT:KeyCode;
	var BACK:KeyCode;
	var RESET:KeyCode;
	var CONTROL:KeyCode;
}