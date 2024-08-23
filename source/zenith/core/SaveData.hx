package zenith.core;

import lime.ui.KeyCode;
import sys.io.File;

/**
 * The savedata system.
 */
class SaveData
{
	// Actual savedata.
	static public var contents(default, null):SaveFile = {
		preferences: {
			downScroll: false,
			smoothHealth: true,
			ghostTapping: false,
			hideHUD: false,
			stillCharacters: true,
		},
		graphics: {
			antialiasing: true,
			gpuCaching: true,
			persistentGraphics: false,
			showFPS: true,
			fps: 60
		},
		experimental: {
			fastNoteSpawning: false,
			multithreading: false
		},
		controls: {
			GAMEPLAY_BINDS: [
				[KeyCode.A, KeyCode.LEFT],
				[KeyCode.S, KeyCode.DOWN],
				[KeyCode.W, KeyCode.UP],
				[KeyCode.D, KeyCode.RIGHT]
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
		customData: new Map<String, _CustomSaveFile>()
	};

	// Reader and writer for the global savedata.

	static public function read():Void
	{
		if (sys.FileSystem.exists('savedata.sav'))
		{
			var contentStr:String = File.getContent('savedata.sav');
			if (contentStr != '')
				contents = (haxe.Unserializer.run(contentStr) : SaveFile);
		}
		else
		{
			File.saveContent('savedata.sav', '');
		}
	}

	static public function write():Void
	{
		var output:String = haxe.Serializer.run(contents);
		File.saveContent('savedata.sav', output);
	}

	// Custom savedata system.
	// Very easy to use due to how fancy it is.

	inline static public function addToCustomSaves(file:CustomSaveFile):Void
	{
		contents.customData[file.name] = file.toStruct();
	}

	inline static public function getCustomSave(name:String):_CustomSaveFile
	{
		return contents.customData[name];
	}

	inline static public function changeCustomSaveName(name:String, newName:String):Void
	{
		contents.customData[name].name = newName;
	}

	inline static public function deleteCustomSave(name:String):Void
	{
		contents.customData[name].data = null;
		contents.customData[name] = null;
		contents.customData.remove(name);
	}
}

typedef PreferencesData =
{
	var downScroll:Bool;
	var smoothHealth:Bool;
	var ghostTapping:Bool;
	var hideHUD:Bool;
	var stillCharacters:Bool;
}

typedef GraphicsData =
{
	var antialiasing:Bool;
	var gpuCaching:Bool;
	var persistentGraphics:Bool;
	var showFPS:Bool;
	var fps:Int;
}

typedef ExperimentalData =
{
	var fastNoteSpawning:Bool;
	var multithreading:Bool;
}

typedef ControlsData =
{
	var GAMEPLAY_BINDS:Array<Array<Int>>;
	var LEFT:Int;
	var DOWN:Int;
	var UP:Int;
	var RIGHT:Int;
	var ACCEPT:Int;
	var BACK:Int;
	var RESET:Int;
	var CONTROL:Int;
}

typedef SaveFile =
{
	var preferences:PreferencesData;
	var graphics:GraphicsData;
	var experimental:ExperimentalData;
	var controls:ControlsData;
	var customData:Map<String, _CustomSaveFile>;
}

class CustomSaveFile
{
	public var name:String;
	public var data:Dynamic;

	public function new(initialName:String):Void
	{
		name = initialName;
	}

	public function toStruct():_CustomSaveFile
	{
		return {name: name, data: data};
	}
}

private typedef _CustomSaveFile =
{
	var name:String;
	var data:Dynamic;
}
