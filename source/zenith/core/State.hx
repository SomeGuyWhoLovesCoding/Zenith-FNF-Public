package zenith.core;

import flixel.FlxBasic;

// FlxState with crash handling and HScript functionality
@:access(flixel.FlxCamera)
class State extends FlxState
{
	override function create():Void
	{
		try
		{
			#if SCRIPTING_ALLOWED
			HScriptFrontend.instance.loadScriptsFromDirectory('assets/scripts');

			for (script in HScriptFrontend.instance.list.keys())
			{
				HScriptFrontend.instance.list[script].setVar('curState', Type.getClassName(Type.getClass(FlxG.state)));
			}

			callHScript(CREATE_PRE);
			#end

			Main.startTransition(false, function() {});

			Main.conductor.onStepHit = Main.conductor.onBeatHit = Main.conductor.onMeasureHit = null;
			Main.conductor.reset();

			FlxG.maxElapsed = FlxG.elapsed;

			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			#if SCRIPTING_ALLOWED
			callHScript(CREATE);
			#end

			super.create();

			#if SCRIPTING_ALLOWED
			callHScript(CREATE_POST);
			#end

			FlxG.maxElapsed = 0.1;
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
			#if SCRIPTING_ALLOWED
			callHScript(UPDATE, elapsed);
			#end

			super.update(elapsed);

			#if SCRIPTING_ALLOWED
			callHScript(UPDATE_POST, elapsed);
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
			callHScript(DESTROY);
			#end

			super.destroy();

			#if SCRIPTING_ALLOWED
			callHScript(DESTROY_POST);
			#end

			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			FlxG.maxElapsed = 0.1;
		}
		catch (e)
		{
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
