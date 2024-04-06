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
			antialiasing: true,
			fps: 240
		},
		controls: {
			GAMEPLAY_BINDS: [
				KeyCode.A,
				KeyCode.S,
				KeyCode.DOWN,
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
	var GAMEPLAY_BINDS:Array<Int>;
	var LEFT:Int;
	var DOWN:Int;
	var UP:Int;
	var RIGHT:Int;
	var ACCEPT:Int;
	var BACK:Int;
	var RESET:Int;
	var CONTROL:Int;
}