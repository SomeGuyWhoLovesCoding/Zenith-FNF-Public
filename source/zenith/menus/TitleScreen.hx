package zenith.menus;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import lime.ui.KeyCode;

typedef TitleConfigurations =
{
	var bpm:Float;
	var titleImage:String;
	var titleImageScale:Float;
	var titleBG:String;
	var titleBGScale:Float;
}

class TitleScreen extends State
{
	public var introTexts:Array<Array<String>> = [
		['Just a nice little walk', 'to the park', 'Yay!!!'],
		['Beep boop', 'Boop bah boop', 'Bee'],
		['What\'s up!', 'How\'s it going?', 'Are you tired?'],
		['What da dog doin?', '', ''],
		['Finally', 'finished', 'this']
	];

	public var titleBG:FlxSprite;
	public var titleImage:FlxSprite;

	static public var titleConfig:TitleConfigurations;
	static public var initialized:Bool = false;
	static public var instance:TitleScreen;

	override public function create():Void
	{
		instance = this;

		Main.skipTransOut = persistentDraw = persistentUpdate = true;

		// Initialize the title configurations before starting the intro
		if (null == titleConfig)
			titleConfig = haxe.Json.parse(sys.io.File.getContent(Paths.ASSET_PATH + '/music/menus/titleConfig.json'));

		inSubMenu = alreadyPressedEnter = false;

		loadTitleScreenShit();
		titleBG.visible = titleImage.visible = initialized;

		Main.game.onKeyDown.add(onKeyDown);

		super.create();

		Main.conductor.onBeatHit = (curBeat:Float) ->
		{
			cameraZoomTween?.cancel();

			FlxG.camera.zoom = 1.0085;
			cameraZoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, Main.conductor.crochet * 0.00175, {ease: FlxEase.quintOut});

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
	}

	override function destroy():Void
	{
		Main.game.onKeyDown.remove(onKeyDown);
		super.destroy();
	}

	private function loadTitleScreenShit():Void
	{
		var titleScreenFile:String = '${Paths.ASSET_PATH}/music/menus/title.ogg';

		if (!sys.FileSystem.exists(titleScreenFile))
		{
			throw "Title screen audio file not found: " + titleScreenFile;
			return;
		}

		if (!initialized)
		{
			FlxG.sound.playMusic(Paths.sound('music/menus/title'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);

			Main.conductor.bpm = titleConfig.bpm;
			Main.conductor.reset();
		}
		else
		{
			FlxG.camera.flash(0xFFFFFFFF, 0.75, null, true);
			FlxG.camera.zoom = 1.0085;
		}

		titleBG = new FlxSprite().loadGraphic(Paths.image(titleConfig.titleBG));
		titleBG.scale.x = titleBG.scale.y = titleConfig.titleBGScale;
		titleBG.updateHitbox();
		add(titleBG);

		titleImage = new FlxSprite().loadGraphic(Paths.image(titleConfig.titleImage));
		titleImage.scale.x = titleImage.scale.y = titleConfig.titleImageScale;
		titleImage.updateHitbox();
		titleImage.screenCenter();
		add(titleImage);

		cameraZoomTween?.cancel();

		FlxG.camera.zoom = 1.0085;
		cameraZoomTween = FlxTween.tween(FlxG.camera, {zoom: 1.0}, Main.conductor.crochet * 0.00175, {ease: FlxEase.quintOut});

		if (!initialized)
		{
			tempIntroText = introTexts[FlxG.random.int(0, introTexts.length - 1)];

			titleText = new FlxText(0, 0, 0, '', 36);
			titleText.font = Paths.font('vcr');
			titleText.alignment = "center";
			titleText.screenCenter();
			titleText.antialiasing = SaveData.contents.graphics.antialiasing;
			titleText.active = false;
			add(titleText);
		}

		titleBG.antialiasing = titleImage.antialiasing = SaveData.contents.graphics.antialiasing;
	}

	override public function update(elapsed:Float):Void
	{
		Main.conductor.songPosition = (FlxG.sound?.music?.time : Single); // HL moment

		super.update(elapsed);
	}

	var cameraZoomTween:FlxTween;
	var tempIntroText:Array<String> = [];

	public var titleText:FlxText;

	private function makeTitleText(text:String):Void
	{
		if (null != titleText)
		{
			titleText.text = text;
			titleText.screenCenter();
		}
	}

	private function addTitleText(text:String):Void
	{
		if (null != titleText && text != '' /* For intro text 4 */)
		{
			titleText.text += '\n' + text;
			titleText.screenCenter();
		}
	}

	private function deleteTitleText():Void
	{
		if (null != titleText)
		{
			titleText.text = '';
			titleText.screenCenter();
		}
	}

	private function skipIntro(skipIntroMusicInstantly:Bool = false):Void
	{
		if (skipIntroMusicInstantly)
		{
			FlxG.sound?.music?.fadeTween?.cancel();
			FlxG.sound.music.volume = 1.0;
			FlxG.sound.music.time = Main.conductor.crochet * 16.0;
		}

		deleteTitleText();
		remove(titleText);

		titleBG.visible = titleImage.visible = initialized = true;

		FlxG.camera.flash(0xFFFFFFFF, 0.75, null, true);
		FlxG.camera.zoom = 1.0085;

		cameraZoomTween?.cancel();
		cameraZoomTween = FlxTween.tween(FlxG.camera, {zoom: 1.0}, Main.conductor.crochet * 0.001, {ease: FlxEase.quintOut});
	}

	static public var inSubMenu:Bool = false;
	static public var alreadyPressedEnter:Bool = false;

	function onKeyDown(keyCode:Int, keyModifier:Int):Void
	{
		if (alreadyPressedEnter)
		{
			return;
		}

		if (SaveData.contents.controls.ACCEPT == keyCode)
		{
			if (inSubMenu)
				TitleScreenSubState.instance.sendSignalEnter();
			else
			{
				if (!initialized)
				{
					skipIntro(true);
					return;
				}

				openSubState(new TitleScreenSubState());
				inSubMenu = true;
			}
		}

		if (!inSubMenu)
			return;

		if (SaveData.contents.controls.LEFT == keyCode)
			TitleScreenSubState.instance.sendSignalLeft();

		if (SaveData.contents.controls.RIGHT == keyCode)
			TitleScreenSubState.instance.sendSignalRight();

		if (SaveData.contents.controls.BACK == keyCode)
		{
			closeSubState();
			inSubMenu = false;
		}
	}
}
