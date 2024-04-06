package zenith.core;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

enum abstract SaveContentType(UInt) from UInt to UInt
{
	var PREFERENCES:Int = 0;
	var CONTROLS:Int = 1;
}

typedef GlobalSaveContents =
{
	var controls:Map<String, FlxKey>;
	var preferences:Map<String, Bool>;
}

typedef CustomSave =
{
	var name:String;
	var contents:Map<String, Dynamic>;
}

class SaveDataV1
{
	// Global bullshit //

	public static final defaultControls:Map<String, FlxKey> = [
		"Note_Left" => FlxKey.A, "Note_Down" => FlxKey.S, "Note_Up" => FlxKey.UP, "Note_Right" => FlxKey.RIGHT,
		"UI_Left" => FlxKey.A, "UI_Down" => FlxKey.S, "UI_Up" => FlxKey.W, "UI_Right" => FlxKey.D,
		"Accept" => FlxKey.ENTER, "Backspace" => FlxKey.BACKSPACE, "Reset" => FlxKey.R, "Control" => FlxKey.CONTROL
	];

	public static final defaultPreferences:Map<String, Bool> = [
		"DownScroll" => false, "HideHUD" => false, "NoCharacters" => false, "SmoothHealth" => false, "ExtendCameraBounds" => true
	];

	// These are just shortcuts, don't recommend changing the function code for them

	public static var controls(get, default):Map<String, FlxKey>;
	static function get_controls():Map<String, FlxKey>
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
		for (customSave in (FlxG.save.data.zenithFunkinData.customSaves : Array<CustomSave>) /* Don't make the compiler think the iterator is a dynamic */)
			if (customSave.name == saveData)
				return customSave;

		return null;
	}

	public static function setGlobalSaveContent(saveContentType:SaveContentType, content:String, newContent:Dynamic)
	{
		if (newContent == content)
			return;

		(saveContentType == PREFERENCES ? FlxG.save.data.zenithFunkinData.globalSave.preferences : FlxG.save.data.zenithFunkinData.globalSave.controls).set(content, newContent);
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
		FlxG.save.bind("Zenith-FNF", "VeryExcited");

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