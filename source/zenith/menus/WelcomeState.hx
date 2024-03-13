package zenith.menus;

import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;

class WelcomeState extends MusicBeatState
{
	override public function create():Void
	{
		super.create();

		FlxG.sound.playMusic(Paths.music('breakfast'), 0.15);

		var bkdr:FlxBackdrop = new FlxBackdrop(Paths.image('other/welcome-grid'));
		bkdr.velocity.set(-20, -20);
		add(bkdr);

		var txtStr:String = 'Hey there, welcome to ' + lime.app.Application.current.meta.get('name') +
			'!\n\nPlease type in an existing song name and difficulty using' +
			'\nthe command prompt. Or, you can just type in the song name.' +
			'\n(Just make sure the chart for it exists)' +
		'\n\nThanks for downloading!';

		var txt:FlxText = new FlxText(0, 0, 0, txtStr, 33);
		txt.alignment = "center";
		txt.updateHitbox();
		txt.screenCenter();
		add(txt);

		var txt2:FlxText = new FlxText(2, 0, 0, 'Zenith by SomeGuyWhoLikesFNF', 14);
		txt2.alignment = "left";
		txt2.updateHitbox();
		txt2.y = FlxG.height - (txt2.height - 2);
		txt2.alpha = 0.6;
		add(txt2);

		bkdr.antialiasing = txt.antialiasing = txt2.antialiasing = true;
		txt.moves = txt2.moves = false;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			//Main.skipTransIn = true;
			MusicBeatState.resetState();
			//trace('a');
		}
	}
}