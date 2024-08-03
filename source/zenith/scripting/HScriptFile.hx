package zenith.scripting;

import haxe.Int64;
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

	public function new(sourcePath:String, sourceKey:String, fromDirectory:Bool = false, directoryName:String = ''):Void
	{
		isFromDirectory = fromDirectory;
		directory = directoryName;
		generate(sourcePath, sourceKey);
	}

	inline public function getVar(variable:String)
	{
		return @:bypassAccessor interp.variables[variable];
	}

	inline public function setVar(variable:String, ?value:Dynamic)
	{
		return @:bypassAccessor interp.variables[variable] = value;
	}

	public function overwrite(sourcePath:String = ""):Void
	{
		// No need to overwrite the file if the contents are the same as the modified contents
		if (stringCode != sys.io.File.getContent(path))
		{
			destroy();

			if (sourcePath != "")
				path = sourcePath;

			generate(path, key);

			#if debug
			trace('HScript $directory with tag [$key] overwritten');
			#end
		}
	}

	private function generate(sourcePath:String, sourceKey:String):Void
	{
		try
		{
			path = sourcePath;
			mTime = sys.FileSystem.stat(path).mtime.getTime();

			interp = new Interp();
			setVar('Main', Main);
			setVar('this', HScriptFrontend.instance);
			setVar('Gameplay', Gameplay);
			setVar('game', Gameplay.instance);
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
			setVar('TitleScreenSubState', TitleScreenSubState);
			setVar('MainMenu', MainMenu);
			// setVar('FreeplayMenu', FreeplayMenu);
			// setVar('AchievementsMenu', AchievementsMenu);
			// setVar('CreditsMenu', CreditsMenu);
			// setVar('SettingsMenu', SettingsMenu);

			parser = new Parser();
			parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

			stringCode = sys.io.File.getContent(path);

			key = sourceKey;
			interp.execute(parser.parseString(stringCode, key));

			setVar('getVar', getVar);
			setVar('setVar', setVar);

			// Here it goes

			createPre = interp.variables["createPre"];
			create = interp.variables["create"];
			createPost = interp.variables["createPost"];
			updatePre = interp.variables["updatePre"];
			update = interp.variables["update"];
			updatePost = interp.variables["updatePost"];
			dest = interp.variables["destroy"];
			destroyPost = interp.variables["destroyPost"];
			stepHit = interp.variables["stepHit"];
			beatHit = interp.variables["beatHit"];
			measureHit = interp.variables["measureHit"];
			generateSong = interp.variables["generateSong"];
			generateSongPost = interp.variables["generateSongPost"];
			startCountdown = interp.variables["startCountdown"];
			startSong = interp.variables["startSong"];
			boot = interp.variables["boot"];

			keyDown = interp.variables["keyDown"];
			keyDownPost = interp.variables["keyDownPost"];
			keyUp = interp.variables["keyUp"];
			keyUpPost = interp.variables["keyUpPost"];
			updateScore = interp.variables["updateScore"];
			setupNoteData = interp.variables["setupNoteData"];
			setupSustainData = interp.variables["setupSustainData"];
			hitNote = interp.variables["hitNote"];
			hitNotePost = interp.variables["hitNotePost"];
			missNote = interp.variables["missNote"];
			missNotePost = interp.variables["missNotePost"];
			hold = interp.variables["hold"];
			holdPost = interp.variables["holdPost"];
			release = interp.variables["release"];
			releasePost = interp.variables["releasePost"];
		}
		catch (e:haxe.Exception)
		{
			HScriptFrontend.error(e);
		}
	}

	inline public function destroy():Void
	{
		interp.variables.clear();
		interp.variables = null;
		interp = null;
		parser = null;
	}

	// A wall of long lines which is why this is at the bottom
	//// HSCRIPT CALLS
	// State-wise calls
	private var createPre:Void->Void;
	private var create:Void->Void;
	private var createPost:Void->Void;
	private var updatePre:Float->Void;
	private var update:Float->Void;
	private var updatePost:Float->Void;
	private var dest:Void->Void;
	private var destroyPost:Void->Void;
	private var stepHit:Float->Void;
	private var beatHit:Float->Void;
	private var measureHit:Float->Void;
	private var generateSong:String->String->Void;
	private var generateSongPost:String->String->Void;
	private var startCountdown:Void->Void;
	private var startSong:Void->Void;
	private var endSong:Void->Void;
	private var boot:Void->Void;
	// Gameplay-wise calls
	private var keyDown:Int->Int->Void;
	private var keyDownPost:Int->Int->Void;
	private var keyUp:Int->Int->Void;
	private var keyUpPost:Int->Int->Void;
	private var updateScore:Void->Void;
	private var setupNoteData:NoteObject->Void;
	private var setupSustainData:NoteObject->Void;
	private var hitNote:Int->Void;
	private var hitNotePost:Int->Void;
	private var missNote:Int->Void;
	private var missNotePost:Int->Void;
	private var hold:Int->Void;
	private var holdPost:Int->Void;
	private var release:Int->Void;
	private var releasePost:Int->Void;
}
#end
