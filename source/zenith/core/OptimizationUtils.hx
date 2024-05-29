// Don't mind this because it's for making the game perform faster with hscript and many other things.
// This is also for cleanup in the gameplay code and other shit.

package zenith.core;

class OptimizationUtils
{
	// The hscript part for which for loops need to be wrapped in a function and shit, which is absolutely for pure optimization.

	public var scriptCall:(String)->(Void) = null;
	public var scriptCallInt:((String), (Int))->(Void) = null;
	public var scriptCallFloat:((String), (Float))->(Void) = null;
	public var scriptCall2Ints:((String), (Int), (Int))->(Void) = null;
	public var scriptCall2Strings:((String), (String), (String))->(Void) = null;
	public var scriptCallEvent:((String), (String), (String), (String), (String), (String))->(Void) = null;

	public var scriptCallNote:((String), (Note))->(Void) = null;
	public var scriptCallSustain:((String), (SustainNote))->(Void) = null;
	public var scriptCallNoteSetup:((String), (Note), Array<(Float)>)->(Void) = null;
	public var scriptCallSustainSetup:((String), (SustainNote), Array<(Float)>)->(Void) = null;

	public var scriptCallCharacter:((String), (Character)->(Void) = null;

	public function initScriptOpts():Void
	{
		scriptCall = (func:(String)) ->
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

		scriptCallInt = (func:(String), a:(Int)) ->
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

		scriptCallFloat = (func:(String), a:(Float)) ->
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

		scriptCall2Ints = (func:(String), a:(Int), b:(Int)) ->
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

		scriptCall2Strings = (func:(String), a:(String), b:(String)) ->
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

		scriptCallEvent = (func:(String), a:(String), b:(String), c:(String), d:(String), e:(String)) ->
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

		scriptCallNote = (func:(String), a:(Note)) ->
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

		scriptCallSustain = (func:(String), a:(SustainNote)) ->
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

		scriptCallNoteSetup = (func:(String), a:(Note), b:Array<(Float)>) ->
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

		scriptCallSustainSetup = (func:(String), a:(SustainNote), b:Array<(Float)>) ->
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

		scriptCallCharacter = (func:(String), a:(Character)) ->
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
	}
}
