// Don't mind this because it's for making the game perform faster with hscript and many other things.
// This is also for cleanup in the gameplay code and other shit.

package zenith.core;

class OptimizationUtils
{
	public function new():Void {}

	// The hscript part for which for loops need to be wrapped in a function and shit, which is absolutely for pure optimization.

	public function scriptCall(func:(String)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))();
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallInt(func:(String), a:(Int)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallFloat(func:(String), a:(Float)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCall2Ints(func:(String), a:(Int), b:(Int)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a, b);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCall2Strings(func:(String), a:(String), b:(String)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a, b);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallEvent(func:(String), a:(String), b:(String), c:(String), d:(String), e:(String)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a, b, c, d, e);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallNote(func:(String), a:(Note)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallSustain(func:(String), a:(SustainNote)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallNoteSetup(func:(String), a:(Note), b:Array<(Float)>):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a, b);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallSustainSetup(func:(String), a:(SustainNote), b:Array<(Float)>):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a, b);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	public function scriptCallCharacter(func:(String), a:(Character)):Void
	{
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists(func))
					(scriptList.get(script).interp.variables.get(func))(a);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
	}

	// Benchmarks

	/*public var callCall:(Int)->(Void);

	function callCallF(a:Int):Void
	{
		a++;
	}*/

	// Functions won LMAO
	/*callCall = (a:Int) ->
	{
		a++;
	}

	var timeStamp = Sys.time();

	for (i in 0...1000000000)
	{
		callCall(i);
	}

	trace('Callback vars: ${Sys.time() - timeStamp}');

	var timeStamp2 = Sys.time();

	for (i in 0...1000000000)
	{
		callCallF(i);
	}

	trace('Functions vars: ${Sys.time() - timeStamp2}');*/
}
