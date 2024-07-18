package zenith.scripting;

#if (SCRIPTING_ALLOWED && hscript)
import hscript.Interp;
import hscript.Parser;

class HScriptFile
{
	public var stringCode(default, null):String = '';
	public var key(default, null):String = '';
	public var path(default, null):String = '';
	public var isFromDirectory(default, null):Bool = false;
	public var directory(default, null):String;
	public var interp(default, null):Interp;
	public var parser(default, null):Parser;

	public var mTime(default, null):Float;

	public function new(sourcePath:String, sourceKey:String, fromDirectory:Bool = false, directoryName:String = ''):Void
	{
		isFromDirectory = fromDirectory;
		directory = directoryName;
		create(sourcePath, sourceKey);
	}

	inline public function getVar(variable:String)
	{
		return interp.variables.get(variable);
	}

	inline public function setVar(variable:String, value:Dynamic = null)
	{
		return interp.variables.set(variable, value);
	}

	public function overwrite(sourcePath:String = ""):Void
	{
		// No need to overwrite the file if the contents are the same as the modified contents
		if (stringCode != sys.io.File.getContent(path))
		{
			destroy();

			if (sourcePath != "")
				path = sourcePath;

			create(path, key);

			#if debug
			trace('HScript $directory with tag [$key] overwritten');
			#end
		}
	}

	private function create(sourcePath:String, sourceKey:String):Void
	{
		try
		{
			mTime = sys.FileSystem.stat(path = sourcePath).mtime.getTime();

			interp = new Interp();
			interp.variables.set('Main', Main);
			interp.variables.set('this', Main.hscript);
			interp.variables.set('Gameplay', Gameplay);
			interp.variables.set('game', Gameplay.instance);
			interp.variables.set('Utils', Utils);
			interp.variables.set('Conductor', Conductor);
			interp.variables.set('NoteObject', NoteObject);
			interp.variables.set('SaveData', SaveData);
			interp.variables.set('StringTools', StringTools);
			interp.variables.set('Paths', Paths);
			interp.variables.set('FlxG', FlxG);
			interp.variables.set('FlxSprite', FlxSprite);
			interp.variables.set('FlxCamera', FlxCamera);
			interp.variables.set('FlxTimer', FlxTimer);
			interp.variables.set('FlxTween', flixel.tweens.FlxTween);
			interp.variables.set('FlxEase', flixel.tweens.FlxEase);
			interp.variables.set('FlxSound', FlxSound);
			interp.variables.set('Math', Math);
			interp.variables.set('Std', Std);
			interp.variables.set('Array', Array);

			// Menus and shit you can modify
			interp.variables.set('TitleScreen', TitleScreen);
			interp.variables.set('TitleScreen', TitleScreen);
			interp.variables.set('MainMenu', MainMenu);
			// interp.variables.set('FreeplayMenu', FreeplayMenu);
			// interp.variables.set('AchievementsMenu', AchievementsMenu);
			// interp.variables.set('CreditsMenu', CreditsMenu);
			// interp.variables.set('SettingsMenu', SettingsMenu);

			parser = new Parser();
			parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

			stringCode = sys.io.File.getContent(path);
			interp.execute(parser.parseString(stringCode, key = sourceKey));

			interp.variables.set('getVar', getVar);
			interp.variables.set('setVar', setVar);
		}
		catch (e:haxe.Exception)
		{
			Main.hscript.error(e);
		}
	}

	inline public function destroy():Void
	{
		interp.variables.clear();
		interp.variables = null;
		interp = null;
		parser = null;
	}
}
#end
