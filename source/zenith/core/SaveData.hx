package zenith.core;

import lime.ui.KeyCode;
import sys.io.File;
using haxe.DynamicAccess;

@:generic class SaveData
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
			multithreading: false,
			gpuCaching: true,
			vsync: {adaptive: false, enabled: false},
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
		customData: new CustomSaveDataBackend()
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
		File.saveContent('savedata.sav', haxe.Serializer.run((contents : SaveFile)));
	}

	// Custom savedata system.
	// Very easy to use due to how fancy it is.

	inline static public function createCustomSave(name:String, ?data:Dynamic):Void
	{
		contents.customData.createCustomSave(name, data);
	}

	inline static public function changeCustomSaveName(name:String, newName:String):Void
	{
		contents.customData.changeCustomSaveName(name, newName);
	}

	inline static public function setCustomSaveContent(name:String, content:String, data:Dynamic):Void
	{
		contents.customData.setCustomSaveContent(name, content, data);
	}

	inline static public function deleteCustomSave(name:String):Void
	{
		contents.customData.deleteCustomSave(name);
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
	var multithreading:Bool;
	var gpuCaching:Bool;
	var vsync:{adaptive:Bool, enabled:Bool};
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

typedef SaveFile =
{
	var preferences:PreferencesData;
	var graphics:GraphicsData;
	var controls:ControlsData;
	var customData:CustomSaveDataBackend;
}

// For maximum security when handling custom savedata.

private abstract CustomSaveDataBackend(Dynamic)
{
	public function new():Void {}

	inline function get(name:String):Dynamic
	{
		return Reflect.field(this, name);
	}

	inline public function createCustomSave(name:String, ?data:Dynamic):Void
	{
		Reflect.sefField(this, name, data);
	}

	inline public function changeCustomSaveName(name:String, newName:String):Void
	{
		if (get(name) != null && newName != name)
		{
			Reflect.setField(get(name), newName, Reflect.copy(get(name)));
			Reflect.deleteField(this, name);
		}
	}

	inline public function setCustomSaveContent(name:String, content:String, data:Dynamic):Void
	{
		Reflect.setField(get(name), content, data);
	}

	inline public function deleteCustomSave(name:String):Void
	{
		Reflect.deleteField(this, name);
	}
}
