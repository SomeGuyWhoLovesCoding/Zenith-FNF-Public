package zenith.scripting;

#if (SCRIPTING_ALLOWED && hscript)
import hscript.Interp;
import hscript.Parser;

class HScriptFile
{
	public var stringCode(default, null):String = '';
	public var key(default, null):String = '';
	public var path(default, null):String = '';
	public var isFromDirectory(default, null):Bool;
	public var directory(default, null):String;
	public var interp(default, null):Interp;
	public var parser(default, null):Parser;

	public var mTime(default, null):Float;

	public function new(sourcePath:String, sourceKey:String, fromDirectory:Bool = false, directoryName:String = '')
	{
		isFromDirectory = fromDirectory;
		directory = directoryName;
		create(sourcePath, sourceKey);
	}

	inline public function getVar(variable:String)
	{
		return @:bypassAccessor interp.variables[variable];
	}

	inline public function setVar(variable:String, value:Dynamic = null)
	{
		return @:bypassAccessor interp.variables[variable] = value;
	}

	public function overwrite(sourcePath:String = "")
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

	private function create(sourcePath:String, sourceKey:String)
	{
		try
		{
			mTime = sys.FileSystem.stat(path = sourcePath).mtime.getTime();

			interp = new Interp();
			setVar('Main', Main);
			setVar('this', Main.hscript);
			setVar('Gameplay', Gameplay);
			setVar('Tools', Tools);
			setVar('Conductor', Conductor);
			setVar('NoteObject', NoteObject);
			setVar('SaveData', SaveData);
			setVar('StringTools', StringTools);
			setVar('AssetManager', AssetManager);
			setVar('FlxG', FlxG);
			setVar('FlxSprite', FlxSprite);
			setVar('FlxCamera', FlxCamera);
			setVar('FlxTimer', FlxTimer);
			setVar('FlxTween', flixel.tweens.FlxTween);
			setVar('FlxEase', flixel.tweens.FlxEase);
			setVar('FlxSound', FlxSound);
			setVar('Math', Math);
			setVar('Std', Std);
			setVar('Array', Array);

			// Menus and shit you can modify
			setVar('TitleScreen', TitleScreen);
			setVar('TitleScreen', TitleScreen);
			setVar('MainMenu', MainMenu);
			// setVar('FreeplayMenu', FreeplayMenu);
			// setVar('AchievementsMenu', AchievementsMenu);
			// setVar('CreditsMenu', CreditsMenu);
			// setVar('SettingsMenu', SettingsMenu);

			parser = new Parser();
			parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

			stringCode = sys.io.File.getContent(path);
			interp.execute(parser.parseString(stringCode, key = sourceKey));

			setVar('getVar', getVar);
			setVar('setVar', setVar);
		}
		catch (e:haxe.Exception)
		{
			Main.hscript.error(e);
		}
	}

	inline public function destroy()
	{
		interp.variables.clear();
		interp.variables = null;
		interp = null;
		parser = null;
	}
}
#end
