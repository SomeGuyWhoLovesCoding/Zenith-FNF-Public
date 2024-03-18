package zenith.menus.submenus;

import flixel.text.FlxText;

using StringTools;

class TitleScreenSubState extends FlxSubState
{
	var textSelection:FlxText;
	var textSelectionArray:Array<String> = ["Main Menu", "Options"];

	var curSelected:Int = 0;

	public static var instance:TitleScreenSubState;

	override public function create():Void
	{
		super.create();

		instance = this;

		textSelection = new FlxText(0, FlxG.height - 200, 0, 'Main Menu   Options', 24);
		textSelection.font = Paths.font('vcr');
		textSelection.screenCenter(X);
		add(textSelection);

		//trace("Test");
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		textSelection.applyMarkup(textSelection.text.replace(textSelectionArray[curSelected], '[]${textSelectionArray[curSelected]}[]'),
		[new FlxTextFormatMarkerPair(
			new FlxTextFormat(0xFFFFFF00, false, false, 0xFFFFFF00), '[]')
		]);
	}

	public inline function sendSignalLeft():Void
	{
		curSelected--;
		if (curSelected < 0)
			curSelected = textSelectionArray.length - 1;
	}

	public inline function sendSignalRight():Void
	{
		curSelected++;
		if (curSelected >= textSelectionArray.length)
			curSelected = 0;
	}

	public function sendSignalEnter():Void
	{
		trace('Test $curSelected');
	}
}