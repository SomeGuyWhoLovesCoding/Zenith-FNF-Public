package tests;

import lime.ui.KeyCode;

@:access(zenith.objects.StaticSprite)
class AtlasTest extends FlxState
{
	public var comboNums:Array<Atlas>;

	var posW:Int = 0;
	var posH:Int = 0;

	override public function create():Void
	{
		super.create();

		FlxG.cameras.bgColor = 0xFF999999;

		comboNums = [
			for (i in 0...10)
			{
				var comboNum:Atlas = new Atlas(Paths.image('ui/comboNums'), 10, 1);
				comboNum.scale.set(0.9, 0.9);
				comboNum.x = 900 - ((comboNum._frame.frame.width * 0.85) * i);
				comboNum.y = 300;
				comboNum.antialiasing = true;
				comboNum;
			}
		];

		Main.game.onKeyDown.on(SignalEvent.KEY_DOWN, function(code:Int, modifier:Int):Void
		{
			if (code == KeyCode.A)
			{
				--posW;

				comboNums[0].updatePosW(posW);
				comboNums[1].updatePosW(posW * 0.1);
				comboNums[2].updatePosW(posW * 0.01);
				comboNums[4].updatePosW(posW * 0.001);
				comboNums[5].updatePosW(posW * 0.0001);
				comboNums[6].updatePosW(posW * 0.00001);
				comboNums[7].updatePosW(posW * 0.000001);
				comboNums[8].updatePosW(posW * 0.0000001);
				comboNums[9].updatePosW(posW * 0.00000001);
			}

			if (code == KeyCode.D)
			{
				++posW;

				comboNums[0].updatePosW(posW);
				comboNums[1].updatePosW(posW * 0.1);
				comboNums[2].updatePosW(posW * 0.01);
				comboNums[4].updatePosW(posW * 0.001);
				comboNums[5].updatePosW(posW * 0.0001);
				comboNums[6].updatePosW(posW * 0.00001);
				comboNums[7].updatePosW(posW * 0.000001);
				comboNums[8].updatePosW(posW * 0.0000001);
				comboNums[9].updatePosW(posW * 0.00000001);
			}
		});
	}

	override function draw():Void
	{
		super.draw();

		for (i in 0...10)
		{
			comboNums[i].draw();
		}
	}
}
