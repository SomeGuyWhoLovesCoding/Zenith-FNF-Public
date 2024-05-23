package zenith.core;

// FlxState with crash handling and HScript functionality

class State extends FlxState
{
	override function create():Void
	{
		FlxG.maxElapsed = FlxG.elapsed;

		try
		{
			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			HScriptSystem.loadScriptsFromDirectory('assets/scripts');

			#if SCRIPTING_ALLOWED
			for (script in scriptList.keys())
			{
				try
				{
					scriptList.get(script).interp.variables.set('curState', Type.getClassName(Type.getClass(FlxG.state)));
					if (scriptList.get(script).interp.variables.exists('create'))
						(scriptList.get(script).interp.variables.get('create'))();
				}
				catch (e)
				{
					HScriptSystem.error(e);
				}
			}
			#end

			super.create();

			#if SCRIPTING_ALLOWED
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
			#end

			FlxG.maxElapsed = 0.1;
		}
		catch (e)
		{
			FlxG.maxElapsed = 0.1;
			throw e;
		}
	}

	override function update(elapsed:Float):Void
	{
		try
		{
			#if SCRIPTING_ALLOWED
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
			#end

			super.update(elapsed);

			#if SCRIPTING_ALLOWED
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
			#end
		}
		catch (e)
		{
			throw e;
		}
	}

	override function destroy():Void
	{
		FlxG.maxElapsed = FlxG.elapsed;
		try
		{
			#if SCRIPTING_ALLOWED
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
			#end

			super.destroy();

			#if SCRIPTING_ALLOWED
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
			#end

			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			FlxG.maxElapsed = 0.1;
		}
		catch (e)
		{
			FlxG.maxElapsed = 0.1;
			throw e;
		}
	}
}