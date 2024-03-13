package zenith.core;

typedef SaveDataFolder =
{
	var name:String,
	var contents:Map<String, Dynamic>
}

class SaveData extends FlxSave
{
	public function new()
	{
		super();

		bind("Zenith-FNF");

		if (null == data.folders)
			data.folders = [];

		if (null == data.globalFolder)
			data.globalFolder = {name: "Zenith-FNF", contents: []};
	}

	public inline function addFolder(folder:String):SaveDataFolder
	{
		data.folders.push({name: folder, contents: []});
	}

	public inline function getFolder(folder:String):SaveDataFolder
	{
		return data.folders.filter(f -> folder == f.name)[0];
	}

	public inline function setFolderContent(content:String, newContents:Dynamic, folder:String = "")
	{
		var folderDestination:String = "";

		if (folder != "")
			folderDestination = folder;

		var saveFolderDestination:SaveDataFolder = getFolder(folderDestination);

		if (null == saveFolderDestination)
			saveFolderDestination = data.globalFolder;

		saveFolderDestination.contents.set(content, newContent);

		data.flush();
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