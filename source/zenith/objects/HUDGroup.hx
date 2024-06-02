package zenith.objects;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

@:access(zenith.Gameplay)
@:access(zenith.objects.HealthBar)

class HUDGroup extends FlxBasic
{
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

		healthBar = new HealthBar(0, Gameplay.downScroll ? 60.0 : FlxG.height - 86.0, [0xFFFF0000], [0xFF00FF00], 600, 24);
		healthBar.screenCenter(X);

		oppIcon = new HealthIcon(Gameplay.instance.dad.healthIcon);
		plrIcon = new HealthIcon(Gameplay.instance.bf.healthIcon, true);

		oppIcon.y = plrIcon.y = healthBar.y - 60.0;

		scoreTxt = new FlxText(0, (healthBar.y + healthBar.height) + 2, 0, 'Score: ' + Gameplay.instance.score + ' | Misses: ' + Gameplay.instance.misses + ' | Accuracy: ???', 20);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000);
		scoreTxt.screenCenter(X);

		timeTxt = new FlxText(0, Gameplay.downScroll ? FlxG.height - 42 : 8, 0, '???', 30);
		timeTxt.setBorderStyle(OUTLINE, 0xFF000000);
		timeTxt.screenCenter(X);

		scoreTxt.borderSize = timeTxt.borderSize = 1.25;
		scoreTxt.font = timeTxt.font = Paths.font('vcr');
		scoreTxt.alignment = timeTxt.alignment = "center";
		scoreTxt.active = timeTxt.active = false;

		oppIcon.pixelPerfectPosition = plrIcon.pixelPerfectPosition = healthBar.pixelPerfectPosition = scoreTxt.pixelPerfectPosition = timeTxt.pixelPerfectPosition = false;
		oppIcon.camera = plrIcon.camera = healthBar.camera = scoreTxt.camera = timeTxt.camera = Gameplay.instance.hudCamera;

		timeTxt.visible = false;
	}

	public function updateScoreText():Void
	{
		if (scoreTxt != null)
		{
			scoreTxt.text = 'Score: ' + Gameplay.instance.score + ' | Misses: ' + Gameplay.instance.misses + ' | Accuracy: ' + (Gameplay.instance.accuracy_right == 0.0 ? '???' :
				Std.int((Gameplay.instance.accuracy_left / Gameplay.instance.accuracy_right) * 10000.0) * 0.01 + '%');
			scoreTxt.screenCenter(X);

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onUpdateScore');
			#end
		}
	}

	function reloadHealthBar():Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		if (healthBar != null)
		{
			healthBar.__left.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(Gameplay.instance.dad.healthColorArray[0], Gameplay.instance.dad.healthColorArray[1], Gameplay.instance.dad.healthColorArray[2]));
			healthBar.__right.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(Gameplay.instance.bf.healthColorArray[0], Gameplay.instance.bf.healthColorArray[1], Gameplay.instance.bf.healthColorArray[2]));
		}
	}

	function updateIcons():Void
	{
		if (oppIcon != null)
		{
			oppIcon.x = healthBar.width * (1.0 - (healthBar.value / healthBar.maxValue) + 0.5) - 75.0;
			oppIcon.animation.curAnim.curFrame = healthBar.value > 1.6 ? 1 : 0;
			
			if (plrIcon != null)
			{
				plrIcon.animation.curAnim.curFrame = healthBar.value < 0.4 ? 1 : 0;
				plrIcon.x = oppIcon.x + 105.0;
			}
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		if (healthBar != null)
		{
			healthBar.value = FlxMath.lerp(healthBar.value, FlxMath.bound(Gameplay.instance.health, 0.0, healthBar.maxValue), SaveData.contents.preferences.smoothHealth ? 0.08 : 1.0);
			healthBar.update(elapsed);
		}

		if (timeTxt != null && Gameplay.instance.startedCountdown)
		{
			timeTxt.text = Utils.formatTime(Gameplay.instance.songLength - Main.conductor.songPosition, true, true);
			timeTxt.screenCenter(X);
			timeTxt.update(elapsed);
		}

		updateIcons();
	}

	override function draw():Void
	{
		if (healthBar != null)
			healthBar.draw();

		if (oppIcon != null)
			oppIcon.draw();

		if (oppIcon != null)
			plrIcon.draw();

		if (oppIcon != null)
			scoreTxt.draw();

		if (timeTxt != null && timeTxt.visible)
			timeTxt.draw();
	}
}
