package zenith.objects;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

@:access(zenith.Gameplay)
@:access(zenith.objects.HealthBar)
@:access(flixel.FlxSprite)
@:final
class HUDGroup extends FlxSpriteGroup
{
	public var comboNums:Array<Atlas>;
	public var oppIcon:HealthIcon;
	public var plrIcon:HealthIcon;
	public var healthBar:HealthBar;
	public var scoreTxt:FlxText;
	public var timeTxt:FlxText;

	public function new():Void
	{
		super();

		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		comboNums = [
			for (i in 0...10)
			{
				var comboNum:Atlas = new Atlas(Paths.image('ui/comboNums'), 10, 1);
				comboNum.scale.set(0.9, 0.9);
				comboNum.x = 900 - ((comboNum._frame.frame.width * 0.85) * i);
				comboNum.y = 350;
				comboNum.antialiasing = true;
				comboNum.camera = Gameplay.instance.hudCamera;
				comboNum.active = comboNum.moves = comboNum.visible = false;
				comboNum;
			}
		];

		oppIcon = new HealthIcon(Gameplay.instance.dad);
		plrIcon = new HealthIcon(Gameplay.instance.bf);
		plrIcon.flipX = true;

		healthBar = new HealthBar(0, Gameplay.downScroll ? 60.0 : FlxG.height - 86.0, [0xFFFF0000], [0xFF00FF00], 600, 24);
		healthBar.top = new FlxSprite().loadGraphic(Paths.image('ui/healthBarBG'));
		healthBar.add(healthBar.top);
		healthBar.screenCenter(X);
		add(healthBar);

		oppIcon.y = plrIcon.y = healthBar.y - 60.0;

		add(oppIcon);
		add(plrIcon);

		scoreTxt = new FlxText(0, healthBar.y
			+ (healthBar.height + 2), 0,
			'Score: '
			+ Gameplay.instance.score
			+ ' | Misses: '
			+ Gameplay.instance.misses
			+ ' | Accuracy: ???', 20);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000);
		add(scoreTxt);

		timeTxt = new FlxText(0, Gameplay.downScroll ? FlxG.height - 42 : 8, 0, '???', 30);
		timeTxt.setBorderStyle(OUTLINE, 0xFF000000);
		add(timeTxt);

		scoreTxt.borderSize = timeTxt.borderSize = 1.25;
		scoreTxt.font = timeTxt.font = Paths.font('vcr');
		scoreTxt.alignment = timeTxt.alignment = "center";

		oppIcon.camera = plrIcon.camera = healthBar.camera = scoreTxt.camera = timeTxt.camera = Gameplay.instance.hudCamera;
		oppIcon.alpha = plrIcon.alpha = healthBar.alpha = scoreTxt.alpha = timeTxt.alpha = 0.0;
		oppIcon.moves = plrIcon.moves = scoreTxt.active = timeTxt.active = scoreTxt.moves = timeTxt.moves = false;

		active = false;
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

	public function updateRatings():Void
	{
		for (i in 0...10)
		{
			comboNum = comboNums[i];
			comboNum.updatePosW(Gameplay.instance.combo / Math.pow(10, i));
			comboNum.visible = Gameplay.instance.combo >= Math.pow(10, i) || (Gameplay.instance.combo != 0 && i < 3);
			comboNum.y = 320;
			comboNum.alpha = 1.0;
		}
	}

	public function updateIcons():Void
	{
		plrIcon.updatePosW(healthBar.value < 0.4 ? 1 : 0);
		oppIcon.updatePosW(healthBar.value > 1.6 ? 1 : 0);
	}

	var _timeTxtValue:Float = 0.0;
	override function draw():Void
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
				timeTxt.text = Utils.formatTime(FlxMath.bound(Gameplay.instance.songLength - _timeTxtValue, 0.0, Gameplay.instance.songLength), true, false);
			}
		}

		for (i in 0...10)
		{
			comboNum = comboNums[i];

			if (!comboNum.visible)
				break;

			comboNum.y = FlxMath.lerp(comboNum.y, 350, FlxG.elapsed * 8.0);
			comboNum.alpha = FlxMath.lerp(comboNum.alpha, 0.0, FlxG.elapsed * 4.0);
			comboNum.draw();
		}

		super.draw();
	}

	override function update(elapsed:Float):Void {}
}
