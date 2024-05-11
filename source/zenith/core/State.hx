package zenith.core;

// FlxState with HScript functionality

class State extends FlxState
{
	override function create():Void
	{
		// Scripting shit
		HScriptSystem.loadScriptsFromDirectory('assets/scripts');

		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists('create'))
					(scriptList.get(script).interp.variables.get('create'))();
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}

		super.create();

		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists('createPost'))
					(scriptList.get(script).interp.variables.get('createPost'))();
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists('update'))
					(scriptList.get(script).interp.variables.get('update'))(elapsed);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}

		super.update(elapsed);

		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists('updatePost'))
					(scriptList.get(script).interp.variables.get('updatePost'))(elapsed);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	override function destroy():Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists('destroy'))
					(scriptList.get(script).interp.variables.get('destroy'))();
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}

		super.destroy();

		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists('destroyPost'))
					(scriptList.get(script).interp.variables.get('destroyPost'))();
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}

		openfl.system.System.gc();
	}
}