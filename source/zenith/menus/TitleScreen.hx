package zenith.menus;

import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;

typedef TitleConfigurations =
{
	var bpm:Float;
	var titleImage:String;
	var titleBG:String;
}

class TitleScreen extends MusicBeatState
{
	public var introTexts:Array<Array<String>> = [ // 2 dimenstional string array
		['Just a nice little walk', 'to the park', 'Yay!!!'],
		['Beep boop', 'Boop bah boop', 'Bee'],
		['What\'s up!', 'How\'s it going?', 'Are you tired?'],
		['What da dog doin?', '', '']
	];

	public var titleBG:FlxBackdrop;
	public var titleImage:FlxSprite;

	public static var titleConfig:TitleConfigurations;

	public static var initialized:Bool = false;

	override public function create():Void
	{
		super.create();

		persistentDraw = persistentUpdate = true;

		// Initialize the title configurations before starting the intro
		if (null == titleConfig)
			titleConfig = haxe.Json.parse(sys.io.File.getContent(Paths.ASSET_PATH + '/music/menus/titleConfig.json'));

		alreadyPressedEnter = false;

		loadTitleScreenShit();
		titleBG.visible = titleImage.visible = initialized;

		keyEmitter.on(SignalEvent.KEY_DOWN, onKeyDown);
	}

	override function destroy():Void
	{
		keyEmitter.off(SignalEvent.KEY_DOWN, onKeyDown);
		super.destroy();
	}

	private function loadTitleScreenShit():Void
	{
		var titleScreenFile:String = Paths.ASSET_PATH + '/music/menus/title.ogg'; // Avoid usage of string interpolation twice

		if (!sys.FileSystem.exists(titleScreenFile))
		{
			throw "Title screen audio file not found: " + titleScreenFile;
			return;
		}

		if (!initialized)
		{
			FlxG.sound.playMusic(Paths.music('menus/title'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);

			Conductor.changeBPM(titleConfig.bpm);
		}

		titleBG = new FlxBackdrop(Paths.image(titleConfig.titleBG));
		titleBG.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
		titleBG.updateHitbox();
		titleBG.velocity.set(-32, 0);
		add(titleBG);

		titleImage = new FlxSprite().loadGraphic(Paths.image(titleConfig.titleImage));
		titleImage.setGraphicSize(Std.int(FlxG.width * 0.5), Std.int(FlxG.height * 0.5));
		titleImage.updateHitbox();
		titleImage.screenCenter();
		add(titleImage);

		if (null != cameraZoomTween)
			cameraZoomTween.cancel();

		FlxG.camera.zoom = 1.0085;
		cameraZoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet * 0.00175, {ease: FlxEase.quintOut});

		titleBG.antialiasing = titleImage.antialiasing = true;

		if (initialized)
			return;

		tempIntroText = introTexts[FlxG.random.int(0, introTexts.length - 1)];

		titleText = new FlxText(0, 0, 0, '', 36);
		titleText.font = Paths.font('vcr');
		titleText.alignment = "center";
		titleText.screenCenter();
		titleText.antialiasing = true;
		add(titleText);
	}

	override public function update(elapsed:Float):Void
	{
		if (null != FlxG.sound.music)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		// This was for testing save data changes
		/*if (FlxG.keys.justPressed.T)
			SaveData.setGlobalSaveContent(CONTROLS, 'Accept', lime.ui.KeyCode.SPACE);*/
	}

	var cameraZoomTween:FlxTween;
	var tempIntroText:Array<String> = [];
	override function beatHit():Void
	{
		super.beatHit();

		if (null != cameraZoomTween)
			cameraZoomTween.cancel();

		FlxG.camera.zoom = 1.0085;
		cameraZoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet * 0.00175, {ease: FlxEase.quintOut});

		if (!initialized)
		{
			switch (curBeat)
			{
				case 1: makeTitleText('SomeGuyWhoLikesFNF');
				case 2: addTitleText('CoreCat');
				case 3: addTitleText('Presents...');
				case 4: deleteTitleText();
				case 5: makeTitleText('Not associated');
				case 6: addTitleText('with');
				case 7: addTitleText('https://newgrounds.com');
				case 8: deleteTitleText();
				case 9: makeTitleText(tempIntroText[0]);
				case 10: addTitleText(tempIntroText[1]);
				case 11: addTitleText(tempIntroText[2]);
				case 12: deleteTitleText();
				case 13: makeTitleText('Friday Night');
				case 14: addTitleText('Funkin');
				case 15: addTitleText('Zenith');
				case 16:
					deleteTitleText();
					remove(titleText);
					skipIntro();
			}
		}
	}

	var titleText:FlxText;
	private inline function makeTitleText(text:String):Void
	{
		if (null != titleText)
		{
			titleText.text = text;
			titleText.screenCenter();
		}
	}

	private inline function addTitleText(text:String):Void
	{
		if (null != titleText && text != '' /* For intro text 4 */)
		{
			titleText.text += '\n' + text;
			titleText.screenCenter();
		}
	}

	private inline function deleteTitleText():Void
	{
		if (null != titleText)
		{
			titleText.text = '';
			titleText.screenCenter();
		}
	}

	private function skipIntro(skipIntroMusicInstantly:Bool = false):Void
	{
		if (initialized)
			return;

		if (skipIntroMusicInstantly)
		{
			if (null != FlxG.sound.music.fadeTween)
				FlxG.sound.music.fadeTween.cancel();
	
			FlxG.sound.music.volume = 1;
			FlxG.sound.music.time = Conductor.crochet * 16;
		}

		deleteTitleText();
		remove(titleText);
		initialized = true;

		titleBG.visible = titleImage.visible = true;

		FlxG.camera.flash(0xFFFFFFFF, 0.75, null, true);
		FlxG.camera.zoom = 1.0085;

		if (null != cameraZoomTween)
			cameraZoomTween.cancel();

		cameraZoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet * 0.001, {ease: FlxEase.quintOut});
	}

	public static var alreadyPressedEnter:Bool = false;
	inline public function onKeyDown(keyCode:Int):Void
	{
		//trace('Test');

		if (SaveData.controls.get("Accept") == keyCode)
		{
			if (alreadyPressedEnter)
				TitleScreenSubState.instance.sendSignalEnter();
			else
			{
				if (!initialized)
				{
					skipIntro(true);
					return;
				}

				openSubState(new TitleScreenSubState());
				alreadyPressedEnter = true;
			}
		}

		if (!alreadyPressedEnter)
			return;

		if (SaveData.controls.get("UI_Left") == keyCode)
			TitleScreenSubState.instance.sendSignalLeft();

		if (SaveData.controls.get("UI_Right") == keyCode)
			TitleScreenSubState.instance.sendSignalRight();

		if (SaveData.controls.get("Backspace") == keyCode)
		{
			closeSubState();
			alreadyPressedEnter = false;
		}
	}
}