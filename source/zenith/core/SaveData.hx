package zenith.core;

import flixel.util.FlxSave;
import lime.ui.KeyCode;

enum abstract SaveContentType(Int) from Int to Int
{
	var PREFERENCES:Int = 0;
	var CONTROLS:Int = 1;
}

typedef GlobalSaveContents =
{
	var controls:Map<String, Int>;
	var preferences:Map<String, Bool>;
}

typedef CustomSave =
{
	var name:String;
	var contents:Map<String, Dynamic>;
}

class SaveData
{
	// Global bullshit //

	public static final defaultControls:Map<String, Int> = [
		"Note_Left" => KeyCode.A, "Note_Down" => KeyCode.S, "Note_Up" => KeyCode.UP, "Note_Right" => KeyCode.RIGHT,
		"UI_Left" => KeyCode.A, "UI_Down" => KeyCode.S, "UI_Up" => KeyCode.W, "UI_Right" => KeyCode.D,
		"Accept" => KeyCode.RETURN, "Backspace" => KeyCode.BACKSPACE, "Reset" => KeyCode.R, "Control" => KeyCode.LEFT_CTRL
	];

	public static final defaultPreferences:Map<String, Bool> = [
		"DownScroll" => false, "HideHUD" => false, "NoCharacters" => false, "ExtendCameraBounds" => true
	];

	// These are just shortcuts, don't recommend changing the function code for them

	public static var controls(get, default):Map<String, Int>;
	static function get_controls():Map<String, Int>
	{
		return FlxG.save.data.zenithFunkinData.globalSave.controls;
	}

	public static var preferences(get, default):Map<String, Bool>;
	static function get_preferences():Map<String, Bool>
	{
		return FlxG.save.data.zenithFunkinData.globalSave.preferences;
	}

	/////////////////////

	public static function addCustomSaveData(saveData:String):Void
	{
		FlxG.save.data.zenithFunkinData.customSaves.push({name: saveData, contents: []});
	}

	public static function getCustomSaveData(saveData:String):CustomSave
	{
		for (customSave in (FlxG.save.data.zenithFunkinData.customSaves : Array<CustomSave>) /* Don't make the game think the variable is a dynamic */)
			if (customSave.name == saveData)
				return customSave;
		return null;
	}

	public static function setGlobalSaveContent(saveContentType:SaveContentType, content:String, newContent:Dynamic)
	{
		(saveContentType == PREFERENCES ? FlxG.save.data.zenithFunkinData.globalSave.preferences : FlxG.save.data.zenithFunkinData.globalSave.controls).set(content, newContent);

		if (newContent != content)
			trace((saveContentType == PREFERENCES ? "Preference" : "Keybind") + ' "$content" set to $newContent');

		//data.flush(); This gives a null function pointer, don't uncomment that line
	}

	public static function setSaveContent(content:String, newContent:Dynamic, saveName:String = "")
	{
		var saveFolderDestination:CustomSave = getCustomSaveData(saveName);

		if (null == saveFolderDestination)
			throw 'Save data with name "$saveName" not found!\nMake sure to add it.';

		saveFolderDestination.contents.set(content, newContent);

		//data.flush();
	}

	public static function reloadSave():Void
	{
		FlxG.save.bind("Zenith-FNF", "Zenith-FNF");

		// The global save is a ``GlobalSaveContents``, don't recommend modifying it yourself.
		if (null == FlxG.save.data.zenithFunkinData)
			FlxG.save.data.zenithFunkinData = {globalSave: {controls: defaultControls, preferences: defaultPreferences}, customSaves: []};
	}
}

// Draft code LOL

/*class SaveData
{
	private static var destination:FlxSave;

	public static function getFolder(f:String):SaveDataFolder
	{
		if (destination != null)
			return destination.data.;

		return null;
	}

	public static function setSave(dataf:String, ):Void
	{

	}

	public static function reloadSave():Void
	{
		if (saveDestination == null)
			saveDestination = new FlxSave();

		saveDestination.bind("Zenith-FNF");
	}
}*/