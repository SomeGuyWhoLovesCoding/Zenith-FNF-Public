package zenith.core;

import lime.ui.KeyCode;
import sys.io.File;
import haxe.ds.StringMap;

class SaveData
{
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
		customData: new StringMap<StringMap<Dynamic>>()
	};

	static public function reloadSave():Void
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

	static public function saveContent():Void
	{
		File.saveContent('savedata.sav', haxe.Serializer.run(contents : SaveFile));
	}

	inline static public function createCustomSave(sav:String):Void
	{
		if (contents.customData[sav] == null)
		{
			contents.customData[sav] = new StringMap<Dynamic>();
		}
	}

	inline static public function changeCustomSaveName(sav:String, name:String):Void
	{
		if (contents.customData[name] == null)
		{
			contents.customData[name] = contents.customData[sav].copy();
			deleteCustomSave(sav);
		}
	}

	inline static public function setDataFromCustomSave(sav:String, data:String, content:Dynamic):Void
	{
		if ((s = contents.customData[sav]) != null)
		{
			s[data] = content;
		}
	}

	inline static public function deleteCustomSave(sav:String):Void
	{
		if ((s = contents.customData[sav]) != null)
		{
			s.clear();
			s = null;
			contents.customData.remove(sav);
		}
	}

	var s(default, null):StringMap<Dynamic>;
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
	var customData:StringMap<StringMap<Dynamic>>;
}
