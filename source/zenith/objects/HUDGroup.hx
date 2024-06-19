package zenith.objects;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

@:access(zenith.Gameplay)
@:access(zenith.objects.HealthBar)
@:access(zenith.objects.StaticSprite)
@:final
class HUDGroup
{
	public var comboNums:Array<Atlas>;
	public var oppIcon:HealthIcon;
	public var plrIcon:HealthIcon;
	public var healthBar:HealthBar;
	public var scoreTxt:FlxText;
	public var timeTxt:FlxText;

	public function new():Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		comboNums = [
			for (i in 0...10)
			{
				var comboNum:Atlas = new Atlas(Paths.image('ui/comboNums'), 10, 1);
				comboNum.scale.set(0.9, 0.9);
				comboNum.x = 900 - ((comboNum._frame.frame.width * 0.85) * i);
				comboNum.y = 300;
				comboNum.antialiasing = true;
				comboNum.camera = Gameplay.instance.hudCamera;
				comboNum.visible = false;
				comboNum;
			}
		];

		oppIcon = new HealthIcon(Gameplay.instance.dad.healthIcon);
		plrIcon = new HealthIcon(Gameplay.instance.bf.healthIcon, true);

		healthBar = new HealthBar(0, Gameplay.downScroll ? 60.0 : FlxG.height - 86.0, [0xFFFF0000], [0xFF00FF00], 600, 24);
		healthBar.top = new FlxSprite().loadGraphic(Paths.image('ui/healthBarBG'));
		healthBar.add(healthBar.top);
		healthBar.screenCenter(X);
		Gameplay.instance.add(healthBar);

		oppIcon.y = plrIcon.y = healthBar.y - 60.0;

		Gameplay.instance.add(oppIcon);
		Gameplay.instance.add(plrIcon);

		scoreTxt = new FlxText(0, healthBar.y
			+ (healthBar.height + 2), 0,
			'Score: '
			+ Gameplay.instance.score
			+ ' | Misses: '
			+ Gameplay.instance.misses
			+ ' | Accuracy: ???', 20);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000);
		Gameplay.instance.add(scoreTxt);

		timeTxt = new FlxText(0, Gameplay.downScroll ? FlxG.height - 42 : 8, 0, '???', 30);
		timeTxt.setBorderStyle(OUTLINE, 0xFF000000);
		Gameplay.instance.add(timeTxt);

		scoreTxt.borderSize = timeTxt.borderSize = 1.25;
		scoreTxt.font = timeTxt.font = Paths.font('vcr');
		scoreTxt.alignment = timeTxt.alignment = "center";
		scoreTxt.active = timeTxt.active = false;

		oppIcon.pixelPerfectPosition = plrIcon.pixelPerfectPosition = healthBar.pixelPerfectPosition = scoreTxt.pixelPerfectPosition = timeTxt.pixelPerfectPosition = false;
		oppIcon.camera = plrIcon.camera = healthBar.camera = scoreTxt.camera = timeTxt.camera = Gameplay.instance.hudCamera;
		oppIcon.alpha = plrIcon.alpha = healthBar.alpha = scoreTxt.alpha = timeTxt.alpha = 0.0;
	}

	public function updateScoreText():Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		scoreTxt.text = 'Score: '
			+ Gameplay.instance.score
			+ ' | Misses: '
			+ Gameplay.instance.misses
			+ ' | Accuracy: '
			+ (Gameplay.instance.accuracy_right == 0.0 ? '???' : Std.int((Gameplay.instance.accuracy_left / Gameplay.instance.accuracy_right) * 10000.0) * 0.01
				+ '%');

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onUpdateScore');
		#end
	}

	function reloadHealthBar():Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		healthBar.__left.makeGraphic(healthBar.__width, healthBar.__height,
			FlxColor.fromRGB(Gameplay.instance.dad.healthColorArray[0], Gameplay.instance.dad.healthColorArray[1], Gameplay.instance.dad.healthColorArray[2]));
		healthBar.__right.makeGraphic(healthBar.__width, healthBar.__height,
			FlxColor.fromRGB(Gameplay.instance.bf.healthColorArray[0], Gameplay.instance.bf.healthColorArray[1], Gameplay.instance.bf.healthColorArray[2]));
	}

	var comboNum(default, null):Atlas;

	public function drawRatings():Void
	{
		for (i in 0...10)
		{
			comboNum = comboNums[i];

			if (comboNum.exists && comboNum.visible)
			{
				comboNum.draw();
			}
		}
	}

	public function updateRatings():Void
	{
		comboNums[0].updatePosW(Gameplay.instance.combo);
		comboNums[0].visible = Gameplay.instance.combo > 0;
		comboNums[1].updatePosW(Gameplay.instance.combo * 0.1);
		comboNums[1].visible = Gameplay.instance.combo > 0;
		comboNums[2].updatePosW(Gameplay.instance.combo * 0.01);
		comboNums[2].visible = Gameplay.instance.combo > 0;
		comboNums[3].updatePosW(Gameplay.instance.combo * 0.001);
		comboNums[3].visible = Gameplay.instance.combo > 999;
		comboNums[4].updatePosW(Gameplay.instance.combo * 0.0001);
		comboNums[4].visible = Gameplay.instance.combo > 9999;
		comboNums[5].updatePosW(Gameplay.instance.combo * 0.00001);
		comboNums[5].visible = Gameplay.instance.combo > 99999;
		comboNums[6].updatePosW(Gameplay.instance.combo * 0.000001);
		comboNums[6].visible = Gameplay.instance.combo > 999999;
		comboNums[7].updatePosW(Gameplay.instance.combo * 0.0000001);
		comboNums[7].visible = Gameplay.instance.combo > 9999999;
		comboNums[8].updatePosW(Gameplay.instance.combo * 0.00000001);
		comboNums[8].visible = Gameplay.instance.combo > 99999999;
		comboNums[9].updatePosW(Gameplay.instance.combo * 0.000000001);
		comboNums[9].visible = Gameplay.instance.combo > 999999999;
	}

	public function updateIcons():Void
	{
		plrIcon.animation.curAnim.curFrame = healthBar.value < 0.4 ? 1 : 0;
		oppIcon.animation.curAnim.curFrame = healthBar.value > 1.6 ? 1 : 0;
	}

	var _timeTxtValue:Float = 0.0;
	public function update():Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		scoreTxt.screenCenter(X);
		timeTxt.screenCenter(X);

		oppIcon.x = healthBar.width * (1 - (healthBar.value / healthBar.maxValue) + 0.5) - 75.0;
		plrIcon.x = oppIcon.x + 105.0;

		healthBar.value = FlxMath.lerp(healthBar.value, FlxMath.bound(Gameplay.instance.health, 0.0, healthBar.maxValue),
			SaveData.contents.preferences.smoothHealth ? FlxG.elapsed * 8.0 : 1.0);

		if (Gameplay.instance.startedCountdown)
		{
			oppIcon.alpha = plrIcon.alpha = healthBar.alpha = scoreTxt.alpha = timeTxt.alpha += (FlxG.elapsed * 8.0) * (1.0 - timeTxt.alpha);
			if (Main.conductor.songPosition - _timeTxtValue > 1000.0)
			{
				_timeTxtValue = Main.conductor.songPosition;
				timeTxt.text = Utils.formatTime(Gameplay.instance.songLength - _timeTxtValue, true, false);
			}
		}
	}
}
