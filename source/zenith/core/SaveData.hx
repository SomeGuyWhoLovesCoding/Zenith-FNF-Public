package zenith.core;

import lime.ui.KeyCode;
import haxe.Json;

class SaveData
{
	static public var contents:SaveFile = {
		preferences: {
			downScroll: false,
			smoothHealth: true,
			ghostTapping: false,
			hideHUD: false,
			noCharacters: false,
			stillCharacters: true,
			antialiasing: true,
			gpuCaching: true,
			persistentGraphics: false,
			fps: 60
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
		if (sys.FileSystem.exists('savedata.sav'))
		{
			var contentStr:String = sys.io.File.getContent('savedata.sav');
			contents = (contentStr != '' ? (Json.parse(contentStr) : SaveFile) : contents);
		}
		else
			sys.io.File.saveContent('savedata.sav', '');
		// WIP
	}

	static public function saveContent():Void
	{
		sys.io.File.saveContent('savedata.sav', Json.stringify(contents, '\t'));
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
	var stillCharacters:Bool;
	var antialiasing:Bool;
	var gpuCaching:Bool;
	var persistentGraphics:Bool;
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