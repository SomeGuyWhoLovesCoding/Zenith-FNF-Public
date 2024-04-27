// I think I should combine the combo numbers to a flxtypedgroup cause WHAT THE FUCK! This is hurting readibility if you go to huge numbers

package tests;

import flixel.math.FlxMath;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import lime.ui.KeyCode;

@:access(zenith.objects.StaticSprite)

class RatingNumsTest extends FlxState
{
	var comboPopup1:StaticSprite;
	var comboPopup2:StaticSprite;
	var comboPopup3:StaticSprite;
	var comboPopup4:StaticSprite;
	var comboPopup5:StaticSprite;
	var comboPopup6:StaticSprite;
	var comboPopup7:StaticSprite;
	var comboPopup8:StaticSprite;
	var comboPopup9:StaticSprite;

	var comboNumFrames:Array<FlxFrame> = [];

	var index:Int = 0;

	override public function create():Void
	{
		super.create();

		FlxG.cameras.bgColor = 0xFF999999;

		for (i in 0...10)
			comboNumFrames.push(FlxGraphic.fromBitmapData(Paths.image('ui/num$i')).imageFrame.frame);

		comboPopup1 = new StaticSprite();
		comboPopup2 = new StaticSprite();
		comboPopup3 = new StaticSprite();
		comboPopup4 = new StaticSprite();
		comboPopup5 = new StaticSprite();
		comboPopup6 = new StaticSprite();
		comboPopup7 = new StaticSprite();
		comboPopup8 = new StaticSprite();
		comboPopup9 = new StaticSprite();

		comboPopup1.x = 900.0;
		comboPopup1.y = comboPopup2.y = comboPopup3.y =
			comboPopup4.y = comboPopup5.y = comboPopup6.y =
		comboPopup7.y = comboPopup8.y = comboPopup9.y = 200.0;

		comboPopup2.x = comboPopup1.x - comboPopup1.width;
		comboPopup3.x = comboPopup2.x - comboPopup2.width;
		comboPopup4.x = comboPopup3.x - comboPopup3.width;
		comboPopup5.x = comboPopup4.x - comboPopup4.width;
		comboPopup6.x = comboPopup5.x - comboPopup5.width;
		comboPopup7.x = comboPopup6.x - comboPopup6.width;
		comboPopup8.x = comboPopup7.x - comboPopup7.width;
		comboPopup9.x = comboPopup8.x - comboPopup8.width;

		updatePopup = () ->
		{
			comboPopup1.setFrame(comboNumFrames[Std.int(Math.abs(index % 10))]);
			comboPopup2.setFrame(comboNumFrames[Std.int(Math.abs(index % 100) * 0.1)]);
			comboPopup3.setFrame(comboNumFrames[Std.int(Math.abs(index % 1000) * 0.01)]);
			comboPopup4.setFrame(comboNumFrames[Std.int(Math.abs(index % 10000) * 0.001)]);
			comboPopup5.setFrame(comboNumFrames[Std.int(Math.abs(index % 100000) * 0.0001)]);
			comboPopup6.setFrame(comboNumFrames[Std.int(Math.abs(index % 1000000) * 0.00001)]);
			comboPopup7.setFrame(comboNumFrames[Std.int(Math.abs(index % 10000000) * 0.000001)]);
			comboPopup8.setFrame(comboNumFrames[Std.int(Math.abs(index % 100000000) * 0.0000001)]);
			comboPopup9.setFrame(comboNumFrames[Std.int(Math.abs(index % 1000000000) * 0.00000001)]);
	
			comboPopup2.x = comboPopup1.x - comboPopup1.width;
			comboPopup3.x = comboPopup2.x - comboPopup2.width;
			comboPopup4.x = comboPopup3.x - comboPopup3.width;
			comboPopup5.x = comboPopup4.x - comboPopup4.width;
			comboPopup6.x = comboPopup5.x - comboPopup5.width;
			comboPopup7.x = comboPopup6.x - comboPopup6.width;
			comboPopup8.x = comboPopup7.x - comboPopup7.width;
			comboPopup9.x = comboPopup8.x - comboPopup8.width;
	
			// Why I cover ``index`` with Math.abs: There will be an integer overflow
			var v:Int = FlxMath.absInt(index); // Avoid calling FlxMath.absInt 8 times for less redundancy
			comboPopup4.visible = v >= 1000;
			comboPopup5.visible = v >= 10000;
			comboPopup6.visible = v >= 100000;
			comboPopup7.visible = v >= 1000000;
			comboPopup8.visible = v >= 10000000;
			comboPopup9.visible = v >= 100000000;
		}

		updatePopup();

		add(comboPopup1);
		add(comboPopup2);
		add(comboPopup3);
		add(comboPopup4);
		add(comboPopup5);
		add(comboPopup6);
		add(comboPopup7);
		add(comboPopup8);
		add(comboPopup9);

		Game.onKeyDown.on(SignalEvent.KEY_DOWN, (code:Int, modifier:Int) ->
		{
			index += code == KeyCode.A ? 1 : code == KeyCode.D ? -1 : 0;
			updatePopup();
		});
	}

	var updatePopup:()->(Void); // For better readibility
}