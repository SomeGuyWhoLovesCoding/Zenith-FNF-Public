package zenith.menus;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

class MainMenu extends State
{
	public var bg:FlxSprite;
	public var options:FlxSpriteGroup;

	var optionsArray:Array<String> = ["Story Mode", "Freeplay", "Achievements", "Credits"];

	var curSelected:Int = 0;

	public var watermark:FlxText;

	static public var instance:TitleScreen;

	public var alreadyPressedEnter:Bool = false;

	override function create():Void
	{
		trace("Nice");

		FlxG.camera.zoom = 1.0;

		bg = new FlxSprite().loadGraphic(Paths.image('mainmenu/bg'));
		bg.screenCenter();
		add(bg);

		watermark = new FlxText(0, 0, 0, 'Friday Night Funkin\': Zenith (Version ${lime.app.Application.current.meta.get('version')}) (Github)', 20);
		watermark.setBorderStyle(OUTLINE, 0xFF000000);
		watermark.y = FlxG.height - watermark.size;
		watermark.font = Paths.font('vcr');
		watermark.antialiasing = SaveData.contents.graphics.antialiasing;
		add(watermark);

		onKeyDown = (keyCode:(Int), keyModifier:(Int)) ->
		{
			if (SaveData.contents.controls.ACCEPT == keyCode && !alreadyPressedEnter)
			{
				sendSignalEnter();
				alreadyPressedEnter = true;
				return;
			}

			if (SaveData.contents.controls.BACK == keyCode)
			{
				switchState(new TitleScreen());
			}

			if (SaveData.contents.controls.UP == keyCode)
				sendSignalUp();

			if (SaveData.contents.controls.DOWN == keyCode)
				sendSignalDown();
		}

		Main.game.onKeyDown.on(SignalEvent.KEY_DOWN, onKeyDown);

		super.create();
	}

	override function destroy():Void
	{
		Main.game.onKeyDown.off(SignalEvent.KEY_DOWN, onKeyDown);
		super.destroy();
	}

	public inline function sendSignalEnter():Void
	{
		trace('Test $curSelected');
	}

	public inline function sendSignalUp():Void
	{
		curSelected--;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
	}

	public inline function sendSignalDown():Void
	{
		curSelected++;
		if (curSelected >= optionsArray.length)
			curSelected = 0;
	}

	private var onKeyDown:((Int), (Int)) -> (Void);
}
