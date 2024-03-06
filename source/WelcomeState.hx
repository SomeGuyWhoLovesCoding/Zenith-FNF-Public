package;

import flixel.text.FlxText;

class WelcomeState extends FlxState
{
	override public function create():Void
	{
		FlxG.sound.playMusic(Paths.music('breakfast'), 0.15);

		var txtStr:String = 'Hey there, welcome to FNF Zenith!' +
			'\n\nPlease type in an existing song name and difficulty using' +
			'\nthe command prompt. Or, you can just type in the song name.' +
			'\n(Just make sure the chart for it exists)' +
		'\n\nThanks for downloading!';

		var txt:FlxText = new FlxText(0, 0, 0, txtStr, 33);
		txt.alignment = "center";
		txt.updateHitbox();
		txt.screenCenter();
		add(txt);

		var txt2:FlxText = new FlxText(2, 0, 0, 'FNF Zenith by SomeGuyWhoLikesFNF', 14);
		txt2.alignment = "left";
		txt2.updateHitbox();
		txt2.y = FlxG.height - (txt2.height - 2);
		txt2.alpha = 0.6;
		add(txt2);

		txt.antialiasing = txt2.antialiasing = true;
		txt.moves = txt2.moves = false;
	}
}