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
	public var comboNums:Array<FlxSprite>;
	public var oppIcon:HealthIcon;
	public var plrIcon:HealthIcon;
	public var healthBar:HealthBar;
	public var scoreTxt:FlxText;
	public var timeTxt:FlxText;

	public function new()
	{
		super();

		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		comboNums = [
			for (i in 0...10)
			{
				var comboNum:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/comboNums'), true, 94, 119);
				comboNum.scale.set(0.9, 0.9);
				comboNum.x = 900 - ((comboNum.width * 0.85) * i);
				comboNum.y = 350;
				comboNum.camera = Gameplay.instance.hudCamera;
				comboNum.active = @:bypassAccessor comboNum.moves = false;
				comboNum.animation.add('preview', [for (i in 0...10) i], 0);
				comboNum.animation.play('preview');
				comboNum;
			}
		];

		oppIcon = new HealthIcon(Gameplay.instance.dad.healthIcon);
		plrIcon = new HealthIcon(Gameplay.instance.bf.healthIcon, true);

		healthBar = new HealthBar(0, Gameplay.downScroll ? 60 : FlxG.height - 86, [0xFFFF0000], [0xFF00FF00], 600, 24);
		healthBar.top = new FlxSprite().loadGraphic(Paths.image('ui/healthBarBG'));
		healthBar.add(healthBar.top);
		healthBar.screenCenter(X);
		add(healthBar);

		oppIcon.y = plrIcon.y = healthBar.y - 60;
		oppIcon.parent = plrIcon.parent = healthBar;

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
		oppIcon.alpha = plrIcon.alpha = healthBar.alpha = scoreTxt.alpha = timeTxt.alpha = 0.;
		oppIcon.moves = plrIcon.moves = scoreTxt.active = timeTxt.active = scoreTxt.moves = timeTxt.moves = false;

		active = false;
	}

	public function updateScoreText()
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		scoreTxt.text = 'Score: '
			+ Gameplay.instance.score
			+ ' | Misses: '
			+ Gameplay.instance.misses
			+ ' | Accuracy: '
			+ (Gameplay.instance.accuracy_right == 0 ? '???' : Std.int((Gameplay.instance.accuracy_left / Gameplay.instance.accuracy_right) * 10000) * 0.01
				+ '%');

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onUpdateScore');
		#end
	}

	function reloadHealthBar()
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		healthBar.__left.makeGraphic(healthBar.__width, healthBar.__height,
			FlxColor.fromRGB(Gameplay.instance.dad.healthColorArray[0], Gameplay.instance.dad.healthColorArray[1], Gameplay.instance.dad.healthColorArray[2]));
		healthBar.__right.makeGraphic(healthBar.__width, healthBar.__height,
			FlxColor.fromRGB(Gameplay.instance.bf.healthColorArray[0], Gameplay.instance.bf.healthColorArray[1], Gameplay.instance.bf.healthColorArray[2]));
	}

	var comboNum(default, null):FlxSprite;

	public function updateRatings()
	{
		var combo = Gameplay.instance.combo;
		for (i in 0...10)
		{
			if (combo <= Math.pow(10, i) && (combo == 0 || i > 2))
			{
				break;
			}

			comboNum = comboNums[i];
			comboNum.animation.curAnim.curFrame = Std.int(combo / Math.pow(10, i)) % 10;
			comboNum.y = 320;
			comboNum.alpha = 1;
		}
	}

	inline public function updateIcons()
	{
		plrIcon.animation.curAnim.curFrame = healthBar.value < 0.4 ? 1 : 0;
		oppIcon.animation.curAnim.curFrame = healthBar.value > 1.6 ? 1 : 0;
	}

	var _timeTxtValue:Float = 0;
	override function draw()
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		scoreTxt.screenCenter(X);
		timeTxt.screenCenter(X);

		healthBar.value = FlxMath.lerp(healthBar.value, FlxMath.bound(Gameplay.instance.health, 0, healthBar.maxValue),
			SaveData.contents.preferences.smoothHealth ? FlxG.elapsed * 8 : 1);

		if (Gameplay.instance.startedCountdown)
		{
			oppIcon.alpha = plrIcon.alpha = healthBar.alpha = scoreTxt.alpha = timeTxt.alpha += (FlxG.elapsed * 8) * (1 - timeTxt.alpha);
			if (Main.conductor.songPosition - _timeTxtValue > 1000)
			{
				_timeTxtValue = Main.conductor.songPosition;
				timeTxt.text = Utils.formatTime(FlxMath.bound(Gameplay.instance.songLength - _timeTxtValue, 0, Gameplay.instance.songLength), true, false);
			}
		}

		var combo = Gameplay.instance.combo;
		for (i in 0...10)
		{
			if (combo <= Math.pow(10, i) && (combo == 0 || i > 2))
			{
				break;
			}

			comboNum = comboNums[i];
			comboNum.y = FlxMath.lerp(comboNum.y, 350, FlxG.elapsed * 8);
			comboNum.alpha = FlxMath.lerp(comboNum.alpha, 0, FlxG.elapsed * 4);
			comboNum.draw();
		}

		super.draw();
	}

	override function update(elapsed:Float) {}
}
