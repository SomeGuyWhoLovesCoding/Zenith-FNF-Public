package zenith.scripting;

import hscript.*;

class HScriptSystem
{
	static public var list:Map<String, HScriptFile>;

	static public function init():Void
	{
		list = new Map<String, HScriptFile>();
	}

	static public function reloadAllScripts():Void
	{
		for (key in list.keys())
		{
			reloadScript(key);
		}
	}

	static public function loadScript(sourcePath:String, key:String, fromDirectory:Bool = false, directoryName:String = ""):Void
	{
		// If the script already exists, overwrite it with the new contents
		if (list.exists(key))
			reloadScript(key);
		else
		{
			list.set(key, new HScriptFile(sourcePath, key, fromDirectory, directoryName));
			#if debug
			trace('HScript "$key" loaded');
			trace(sourcePath);
			#end
		}
	}

	static public function removeScript(key:String):Void
	{
		// If the script is already removed, don't destroy it again

		var file = getScript(key);

		if (file != null)
		{
			file.destroy();
			list.remove(key);

			#if debug
			trace('HScript "$key" removed');
			#end
		}
	}

	static public function loadScriptsFromDirectory(sourcePath:String):Void
	{
		try
		{
			if (sys.FileSystem.exists(sourcePath))
			{
				var directory:Array<String> = sys.FileSystem.readDirectory(sourcePath);

				for (i in 0...directory.length)
				{
					var scriptPath:String = directory[i];
					var path:String = sourcePath + '/' + scriptPath;

					if (StringTools.endsWith(path, '.hx'))
					{
						loadScript(path, StringTools.replace(scriptPath, '.hx', ''), true, sourcePath); // You MUST get the script's filename itself
					}
				}

				#if debug
				trace('HScripts loaded from directory "$sourcePath"');
				#end
			}
		}
		catch (e:haxe.Exception)
		{
			error(e);
		}
	}

	static public function removeScriptsFromDirectory(sourcePath:String):Void
	{
		try
		{
			for (key in list.keys())
			{
				var file = getScript(key);

				if (file != null && (file.isFromDirectory && file.directory == sourcePath))
				{
					removeScript(file.key);
				}
			}

			#if debug
			trace('HScripts removed from directory "$sourcePath"');
			#end
		}
		catch (e:haxe.Exception)
		{
			error(e);
		}
	}

	inline static public function getScript(key:String):HScriptFile
	{
		return list.get(key);
	}

	static public function reloadScript(key:String):Void
	{
		var file = getScript(key);

		if (!sys.FileSystem.exists(file.path))
		{
			removeScript(key); // Clean shit up
		}
		else
		{
			if (file != null && file.mTime != sys.FileSystem.stat(file.path).mtime.getTime())
			{
				file.overwrite();
			}
		}
	}

	static public function callFromAllScripts(func:String, args:Array<Dynamic>):Void
	{
		for (key in list.keys())
		{
			getScript(key).call(func, args);
		}
	}

	static public dynamic function error(e:haxe.Exception):Void
	{
		#if debug
		trace(e.message);
		#end
	}
}