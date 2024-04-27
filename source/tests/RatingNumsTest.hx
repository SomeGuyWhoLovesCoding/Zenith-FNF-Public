package tests;

import flixel.graphics.frames.FlxFrame;
import lime.ui.KeyCode;

@:access(zenith.objects.StaticSprite)

class RatingNumsTest extends FlxState
{
	var comboPopup1:StaticSprite;
	var comboPopup2:StaticSprite;
	var comboNumFrames:Array<FlxFrame> = [];

	var index:Int = 0;

	override public function create():Void
	{
		super.create();

		FlxG.cameras.bgColor = 0xFF999999;

		for (i in 0...10)
			comboNumFrames.push(new StaticSprite().loadGraphic(Paths.image('ui/num$i'))._frame);

		comboPopup1 = new StaticSprite();
		comboPopup2 = new StaticSprite();

		comboPopup1.setFrame(comboNumFrames[Std.int(Math.abs(index % 10))]);
		comboPopup2.setFrame(comboNumFrames[Std.int(Math.abs(index % 100) * 0.1)]);

		comboPopup1.x = comboPopup1.y = comboPopup2.y = 30.0;
		comboPopup2.x = comboPopup1.x + comboPopup1.width;

		add(comboPopup1);
		add(comboPopup2);

		Game.onKeyDown.on(SignalEvent.KEY_DOWN, (code:Int, modifier:Int) ->
		{
			if (code == KeyCode.A)
			{
				index--;
				comboPopup1.setFrame(comboNumFrames[Std.int(Math.abs(index % 10.0))]);
				comboPopup2.setFrame(comboNumFrames[Std.int(Math.abs((index * 0.1) % 10.0))]);
			}

			if (code == KeyCode.D)
			{
				index++;
				comboPopup1.setFrame(comboNumFrames[Std.int(Math.abs(index % 10.0))]);
				comboPopup2.setFrame(comboNumFrames[Std.int(Math.abs((index * 0.1) % 10.0))]);
			}
		});
	}
}