package zenithFunkin.data;

class SaveData
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
}