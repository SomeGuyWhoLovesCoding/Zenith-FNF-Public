package zenith.objects;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

/**
 * The hud group.
 */
@:access(zenith.Gameplay)
@:access(zenith.objects.HealthBar)
@:access(flixel.FlxSprite)
@:final
@:publicFields
class HUDGroup extends FlxSpriteGroup
{
	var comboNums:Array<FlxSprite>;
	var oppIcon:HealthIcon;
	var plrIcon:HealthIcon;
	var healthBar:HealthBar;
	var scoreTxt:FlxText;
	var timeTxt:FlxText;

	function new()
	{
		super();

		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		comboNums = [
			for (i in 0...10)
			{
				var comboNum = new FlxSprite().loadGraphic(AssetManager.image('ui/comboNums'), true, 94, 119);
				comboNum.scale.set(0.9, 0.9);
				comboNum.x = 900 - ((comboNum.width * 0.85) * i);
				comboNum.y = 350;
				comboNum.camera = Gameplay.instance.hudCamera;
				comboNum.active = @:bypassAccessor comboNum.moves = false;
				comboNum.animation.add('preview', [for (i in 0...10) i], 0);
				comboNum.animation.play('preview');
				comboNum.alpha = 0;
				comboNum;
			}
		];

		oppIcon = new HealthIcon(Gameplay.instance.dad.healthIcon);
		plrIcon = new HealthIcon(Gameplay.instance.bf.healthIcon, true);

		healthBar = new HealthBar(0, Gameplay.downScroll ? 60 : FlxG.height - 86, [0xFFFF0000], [0xFF00FF00], 600, 24);
		healthBar.top = new FlxSprite().loadGraphic(AssetManager.image('ui/healthBarBG'));
		healthBar.add(healthBar.top);
		@:bypassAccessor healthBar.screenCenter(X);
		add(healthBar);

		@:bypassAccessor oppIcon.y = plrIcon.y = healthBar.y - 60;
		oppIcon.parent = plrIcon.parent = healthBar;

		add(oppIcon);
		add(plrIcon);

		scoreTxt = new FlxText(0, @:bypassAccessor healthBar.y
			+ (@:bypassAccessor healthBar.height + 2), 0,
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
		scoreTxt.font = timeTxt.font = AssetManager.font('vcr');
		scoreTxt.alignment = timeTxt.alignment = "center";

		oppIcon.camera = plrIcon.camera = healthBar.camera = scoreTxt.camera = timeTxt.camera = Gameplay.instance.hudCamera;

		@:bypassAccessor
		{
			oppIcon.alpha = plrIcon.alpha = healthBar.alpha = scoreTxt.alpha = timeTxt.alpha = 0;
			oppIcon.moves = plrIcon.moves = scoreTxt.active = timeTxt.active = scoreTxt.moves = timeTxt.moves = false;
			active = moves = false;
		}
	}

	function updateScoreText()
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		var game = Gameplay.instance;

		scoreTxt.text = 'Score: '
			+ game.score
			+ ' | Misses: '
			+ game.misses
			+ ' | Accuracy: '
			+ (game.accuracy_right == 0 ? '???' : Math.floor((game.accuracy_left / game.accuracy_right) * 10000) * 0.01 + '%');

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onUpdateScore');
		#end
	}

	function reloadHealthBar()
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		var game = Gameplay.instance;
		var dad = game.dad;
		var bf = game.bf;

		healthBar.__left.makeGraphic(healthBar.__width, healthBar.__height,
			FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
		healthBar.__right.makeGraphic(healthBar.__width, healthBar.__height,
			FlxColor.fromRGB(bf.healthColorArray[0], bf.healthColorArray[1], bf.healthColorArray[2]));
	}

	function updateRatings()
	{
		var combo = Gameplay.instance.combo;

		if (combo == 0)
		{
			return;
		}

		for (i in 0...10)
		{
			var pow = Tools.powerOf10_32[i];

			if (combo <= pow && i > 2)
			{
				break;
			}

			var comboNum = comboNums[i];
			comboNum.animation.curAnim.curFrame = Math.floor(combo / pow) % 10;
			@:bypassAccessor comboNum.y = 320;
			comboNum.alpha = 1;
		}
	}

	inline function updateIcons()
	{
		plrIcon.animation.curAnim.curFrame = healthBar.value < 0.4 ? 1 : 0;
		oppIcon.animation.curAnim.curFrame = healthBar.value > 1.6 ? 1 : 0;
	}

	private var _timeTxtValue:Float = 0;

	override function draw()
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		@:bypassAccessor
		{
			scoreTxt.screenCenter(X);
			timeTxt.screenCenter(X);
		}

		var game = Gameplay.instance;

		healthBar.value = FlxMath.lerp(healthBar.value, FlxMath.bound(game.health, 0, healthBar.maxValue),
			SaveData.contents.preferences.smoothHealth ? FlxG.elapsed * 8 : 1);

		if (game.startedCountdown)
		{
			oppIcon.alpha = plrIcon.alpha = healthBar.alpha = scoreTxt.alpha = timeTxt.alpha += (FlxG.elapsed * 8) * (1 - timeTxt.alpha);
			if (Main.conductor.songPosition - _timeTxtValue > 1000)
			{
				_timeTxtValue = Main.conductor.songPosition;
				timeTxt.text = Tools.formatTime(FlxMath.bound(game.songLength - _timeTxtValue, 0, game.songLength), true, false);
			}
		}

		super.draw();

		var combo = game.combo;

		if (combo == 0)
		{
			return;
		}

		for (i in 0...10)
		{
			if (combo <= Tools.powerOf10_32[i] && i > 2)
			{
				break;
			}

			var comboNum = comboNums[i];
			@:bypassAccessor comboNum.y = FlxMath.lerp(comboNum.y, 350, FlxG.elapsed * 9);
			comboNum.alpha = FlxMath.lerp(comboNum.alpha, 0, FlxG.elapsed * 4);
			comboNum.draw();
		}
	}

	override function update(elapsed:Float) {}
}
