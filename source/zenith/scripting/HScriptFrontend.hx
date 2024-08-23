package zenith.scripting;

#if (SCRIPTING_ALLOWED && hscript)
/**
 * The hscript frontend.
 */
@:publicFields
class HScriptFrontend
{
	var list:Map<String, HScriptFile>;

	inline function new()
	{
		list = new Map<String, HScriptFile>();
	}

	function reloadAllScripts()
	{
		for (key in list.keys())
		{
			reloadScript(key);
		}
	}

	function loadScript(sourcePath:String, key:String, fromDirectory:Bool = false, directoryName:String = "")
	{
		// If the script already exists, overwrite it with the new contents
		if (list.exists(key))
			reloadScript(key);
		else
		{
			list.set(key, new HScriptFile(sourcePath, key, fromDirectory, directoryName));
			#if debug
			trace('HScript with tag $key [$directoryName] loaded');
			trace(sourcePath);
			#end
		}
	}

	inline function removeScript(key:String)
	{
		// If the script is already removed, don't destroy it again

		var file = getScript(key);

		if (file != null)
		{
			file.destroy();
			list.remove(key);

			#if debug
			trace('HScript ${file.directory} with tag $key removed');
			#end
		}
	}

	function loadScriptsFromDirectory(sourcePath:String)
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

	function removeScriptsFromDirectory(sourcePath:String)
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

	inline function getScript(key:String):HScriptFile
	{
		return @:bypassAccessor list[key];
	}

	function reloadScript(key:String)
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

	function callFromAllScripts(func:String, ?arg1:Dynamic, ?arg2:Dynamic, ?arg3:Dynamic, ?arg4:Dynamic, ?arg5:Dynamic)
	{
		for (script in list.keys())
		{
			try
			{
				var f = getScript(script).getVar(func);
				if (f != null)
				{
					f(arg1, arg2, arg3, arg4, arg5);
				}
			}
			catch (e:haxe.Exception)
			{
				error(e);
			}
		}
	}

	static function callFromAllScriptsStatic(func:String, ?arg1:Dynamic, ?arg2:Dynamic, ?arg3:Dynamic, ?arg4:Dynamic, ?arg5:Dynamic)
	{
		Main.hscript.callFromAllScripts(func, arg1, arg2, arg3, arg4, arg5);
	}

	dynamic function error(e:haxe.Exception)
	{
		trace(e.message);
	}
}
#end
