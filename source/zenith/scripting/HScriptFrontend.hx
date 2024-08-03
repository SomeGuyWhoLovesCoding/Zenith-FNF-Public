package zenith.scripting;

#if (SCRIPTING_ALLOWED && hscript)
class HScriptFrontend
{
	public var list:Map<String, HScriptFile> = new Map<String, HScriptFile>();

	static public var instance:HScriptFrontend = new HScriptFrontend();

	public function new() {}

	public function reloadAllScripts()
	{
		for (key in list.keys())
		{
			reloadScript(key);
		}
	}

	public function loadScript(sourcePath:String, key:String, fromDirectory:Bool = false, directoryName:String = "")
	{
		// If the script already exists, overwrite its contents
		if (list.exists(key))
			reloadScript(key);
		else
		{
			@:bypassAccessor list[key] = new HScriptFile(sourcePath, key, fromDirectory, directoryName);
			#if debug
			trace('HScript with tag $key [$directoryName] loaded');
			trace(sourcePath);
			#end
		}
	}

	public function removeScript(key:String)
	{
		var file = getScript(key);

		// If the script is already removed, early return
		if (file == null)
		{
			return;
		}

		file.destroy();
		list.remove(key);

		#if debug
		trace('HScript ${file.directory} with tag $key removed');
		#end
	}

	public function loadScriptsFromDirectory(sourcePath:String)
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
				trace('HScripts reloaded from directory "$sourcePath"');
				#end
			}
		}
		catch (e:haxe.Exception)
		{
			error(e);
		}
	}

	public function removeScriptsFromDirectory(sourcePath:String)
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

	inline public function getScript(key:String):HScriptFile
	{
		return @:bypassAccessor list[key];
	}

	public function reloadScript(key:String)
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

	public function callFromAllScripts(id:CallID, ?arg1:Any, ?arg2:Any)
	{
		for (script in list.keys())
		{
			HScriptMacros.callFromScript(getScript(script), id, arg1, arg2);
		}
	}

	inline static public function callFromAllScriptsStatic(id:CallID, ?arg1:Any, ?arg2:Any)
	{
		instance.callFromAllScripts(id, arg1, arg2);
	}

	public static dynamic function error(e:haxe.Exception)
	{
		trace(e.message);
	}
}
#end
