package zenith.core;

// FlxState with crash handling and HScript functionality

@:access(zenith.Game)

class State extends FlxState
{
	override function create():Void
	{
		try
		{
			Main.game.updateElapsed();

			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			HScriptSystem.loadScriptsFromDirectory('assets/scripts');

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

			Main.game.updateElapsed();
		}
		catch (e)
		{
			throw e;
		}
	}

	override function update(elapsed:Float):Void
	{
		try
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
		catch (e)
		{
			throw e;
		}
	}

	override function destroy():Void
	{
		try
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

			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();
		}
		catch (e)
		{
			throw e;
		}
	}
}