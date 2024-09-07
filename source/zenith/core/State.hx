package zenith.core;

/**
 * A FlxState with hscript slapped into it.
 */
@:publicFields
class State extends FlxState
{
	private var CREATE_PRE = 'createPre';
	private var CREATE = 'create';
	private var CREATE_POST = 'createPost';
	private var UPDATE = 'update';
	private var UPDATE_POST = 'updatePost';
	private var DESTROY = 'destroy';
	private var DESTROY_POST = 'destroyPost';

	override function create()
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.loadScriptsFromDirectory('assets/scripts');

		for (script in Main.hscript.list.keys())
		{
			Main.hscript.list[script].interp.variables.set('curState', Type.getClassName(Type.getClass(FlxG.state)));
		}

		callHScript(CREATE_PRE);
		#end

		Main.startTransition(false, function() {});

		Main.conductor.onStepHit = Main.conductor.onBeatHit = Main.conductor.onMeasureHit = null;
		Main.conductor.reset();

		FlxG.maxElapsed = 0;

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

	override function update(elapsed:Float)
	{
		var delta = elapsed;

		#if SCRIPTING_ALLOWED
		callHScript(UPDATE, delta);
		#end

		super.update(delta);

		#if SCRIPTING_ALLOWED
		callHScript(UPDATE_POST, delta);
		#end
	}

	override function destroy()
	{
		FlxG.maxElapsed = 0;

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

	function switchState(nextState:FlxState)
	{
		Main.startTransition(true, function()
		{
			FlxG.switchState(nextState);
		});
	}

	function resetState()
	{
		Main.startTransition(true, FlxG.resetState);
	}
}
