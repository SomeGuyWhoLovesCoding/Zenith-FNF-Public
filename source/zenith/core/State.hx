package zenith.core;

// FlxState with HScript functionality

class State extends FlxState
{
	override function create():Void
	{
		// Scripting shit
		HScriptSystem.loadScriptsFromDirectory('assets/scripts');
		HScriptSystem.callFromAllScripts('create', []);

		super.create();

		HScriptSystem.callFromAllScripts('createPost', []);
	}

	override function update(elapsed:Float):Void
	{
		HScriptSystem.callFromAllScripts('update', [elapsed]);

		super.update(elapsed);

		HScriptSystem.callFromAllScripts('updatePost', [elapsed]);
	}

	override function destroy():Void
	{
		HScriptSystem.callFromAllScripts('destroy', []);

		super.destroy();

		openfl.system.System.gc();

		HScriptSystem.callFromAllScripts('destroyPost', []);
	}
}