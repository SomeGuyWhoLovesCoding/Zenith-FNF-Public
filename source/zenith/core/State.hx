package zenith.core;

import flixel.FlxBasic;

// FlxState with crash handling and HScript functionality

@:access(flixel.FlxCamera)

class State extends FlxState
{
	var currentUpdateMember:FlxBasic = null;
	var currentDrawMember:FlxBasic = null;

	override function create():Void
	{
		Main.conductor.onStepHit = Main.conductor.onBeatHit = Main.conductor.onMeasureHit = null;

		FlxG.maxElapsed = FlxG.elapsed;

		try
		{
			if (!SaveData.contents.graphics.persistentGraphics)
				openfl.system.System.gc();

			#if SCRIPTING_ALLOWED
			HScriptSystem.loadScriptsFromDirectory('assets/scripts');

			for (script in scriptList.keys())
			{
				scriptList.get(script).interp.variables.set('curState', Type.getClassName(Type.getClass(FlxG.state)));
			}

			Main.optUtils.scriptCall('create');
			#end

			super.create();

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall('createPost');
			#end

			FlxG.maxElapsed = 0.1;
		}
		catch (e)
		{
			FlxG.maxElapsed = 0.1;
			throw e;
		}

		updateMembers = (elapsed:Float) ->
		{
			for (i in 0...members.length)
			{
				currentUpdateMember = members[i];
				if (currentUpdateMember != null && currentUpdateMember.exists && currentUpdateMember.active)
				{
					currentUpdateMember.update(elapsed);
				}
			}
		}

		drawMembers = () ->
		{
			final oldDefaultCameras = FlxCamera._defaultCameras;
			if (_cameras != null)
			{
				FlxCamera._defaultCameras = _cameras;
			}

			for (i in 0...members.length)
			{
				currentDrawMember = members[i];
				if (currentDrawMember != null && currentDrawMember.exists && currentDrawMember.visible)
				{
					currentDrawMember.draw();
				}
			}

			FlxCamera._defaultCameras = oldDefaultCameras;
		}
	}

	override function update(elapsed:Float):Void
	{
		try
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallFloat('update', elapsed);
			#end

			updateMembers(elapsed);

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallFloat('updatePost', elapsed);
			#end
		}
		catch (e)
		{
			throw e;
		}
	}

	override function draw():Void
	{
		drawMembers();
	}

	override function destroy():Void
	{
		FlxG.maxElapsed = FlxG.elapsed;
		try
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall('destroy');
			#end

			super.destroy();

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall('destroyPost');
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

	var updateMembers:(Float)->(Void);
	var drawMembers:()->(Void);

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