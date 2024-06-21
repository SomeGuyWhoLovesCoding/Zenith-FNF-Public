package zenith.submenus;

import flixel.text.FlxText;

using StringTools;

class TitleScreenSubState extends FlxSubState
{
	var optionsTxt:FlxText;
	var optionsArray:Array<String> = ["Main Menu", "Settings"];

	var curSelected:Int = 0;

	public static var instance:TitleScreenSubState;

	override public function create():Void
	{
		super.create();

		instance = this;

		optionsTxt = new FlxText(0, FlxG.height - 200, 0, 'Main Menu       Settings', 24);
		optionsTxt.font = Paths.font('vcr');
		optionsTxt.screenCenter(X);
		optionsTxt.active = false;
		add(optionsTxt);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		optionsTxt.applyMarkup(optionsTxt.text.replace(optionsArray[curSelected], '[]${optionsArray[curSelected]}[]'), [
			new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFFFF00, false, false, 0xFFFFFF00), '[]')
		]);
	}

	public inline function sendSignalLeft():Void
	{
		curSelected--;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
	}

	public inline function sendSignalRight():Void
	{
		curSelected++;
		if (curSelected >= optionsArray.length)
			curSelected = 0;
	}

	public inline function sendSignalEnter():Void
	{
		TitleScreen.alreadyPressedEnter = true;
		TitleScreen.instance.switchState(new MainMenu() /*curSelected == 0 ? new MainMenu() : new SettingsMenu()*/);
	}
}
