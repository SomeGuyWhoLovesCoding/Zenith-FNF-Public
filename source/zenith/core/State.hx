package zenith.core;

import flixel.FlxBasic;

// FlxState with crash handling and HScript functionality

@:access(flixel.FlxCamera)

class State extends FlxState
{
	static public var crashHandler:Bool = false;

	public function new():Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.loadScriptsFromDirectory('assets/scripts');

		for (script in Main.hscript.list.keys())
		{
			Main.hscript.list[script].interp.variables.set('curState', Type.getClassName(Type.getClass(FlxG.state)));
		}

		Main.hscript.callFromAllScripts('createPre');
		#end

		super();
	}

	override function create():Void
	{
		Main.startTransition(false, null);

		Main.conductor.reset();
		Main.conductor.onStepHit = Main.conductor.onBeatHit = Main.conductor.onMeasureHit = null;

		FlxG.maxElapsed = FlxG.elapsed;

		try
		{
			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('create');
			#end

			super.create();

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('createPost');
			#end

			FlxG.maxElapsed = 0.1;
		}
		catch (e)
		{
			FlxG.maxElapsed = 0.1;
			if (crashHandler)
				throw e;
		}
	}

	override function update(elapsed:Float):Void
	{
		try
		{
			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('update', elapsed);
			#end

			super.update(elapsed);

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('updatePost', elapsed);
			#end
		}
		catch (e)
		{
			if (crashHandler)
				throw e;
		}
	}

	override function destroy():Void
	{
		FlxG.maxElapsed = FlxG.elapsed;
		try
		{
			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('destroy');
			#end

			super.destroy();

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('destroyPost');
			#end

			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			FlxG.maxElapsed = 0.1;
		}
		catch (e)
		{
			FlxG.maxElapsed = 0.1;
			if (crashHandler)
				throw e;
		}
	}

	public function switchState(nextState:FlxState)
	{
		Main.startTransition(true, function()
		{
			FlxG.switchState(nextState);
		});
	}

	public function resetState()
	{
		Main.startTransition(true, FlxG.resetState);
	}
}
