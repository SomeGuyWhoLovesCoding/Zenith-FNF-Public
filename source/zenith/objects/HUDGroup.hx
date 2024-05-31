package zenith.objects;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

@:access(zenith.Gameplay)

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

		scoreTxt = new FlxText(0, healthBar.y + (healthBar.height + 2), 0, 'Score: ' + Gameplay.instance.score + ' | Misses: ' + Gameplay.instance.misses + ' | Accuracy: ???', 20);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000);

		timeTxt = new FlxText(0, Gameplay.downScroll ? FlxG.height - 42 : 8, 0, '???', 30);
		timeTxt.setBorderStyle(OUTLINE, 0xFF000000);

		scoreTxt.borderSize = timeTxt.borderSize = 1.25;
		scoreTxt.font = timeTxt.font = Paths.font('vcr');
		scoreTxt.alignment = timeTxt.alignment = "center";
		scoreTxt.active = timeTxt.active = false;

		oppIcon.pixelPerfectPosition = plrIcon.pixelPerfectPosition = healthBar.pixelPerfectPosition = scoreTxt.pixelPerfectPosition = timeTxt.pixelPerfectPosition = false;
		oppIcon.camera = plrIcon.camera = healthBar.camera = scoreTxt.camera = timeTxt.camera = Gameplay.instance.hudCamera;
	}

	public function updateScoreText():Void
	{
		scoreTxt.text = 'Score: ' + Gameplay.instance.score + ' | Misses: ' + Gameplay.instance.misses + ' | Accuracy: ' + (Gameplay.instance.accuracy_right == 0.0 ? '???' :
			Std.int((Gameplay.instance.accuracy_left / Gameplay.instance.accuracy_right) * 10000.0) * 0.01 + '%');

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onUpdateScore');
		#end
	}

	function reloadHealthBar():Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		@:privateAccess {
			healthBar.__left.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(Gameplay.instance.dad.healthColorArray[0], Gameplay.instance.dad.healthColorArray[1], Gameplay.instance.dad.healthColorArray[2]));
			healthBar.__right.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(Gameplay.instance.bf.healthColorArray[0], Gameplay.instance.bf.healthColorArray[1], Gameplay.instance.bf.healthColorArray[2]));
		}
	}

	function updateIcons():Void
	{
		plrIcon.animation.curAnim.curFrame = healthBar.value < 0.4 ? 1 : 0;
		oppIcon.animation.curAnim.curFrame = healthBar.value > 1.6 ? 1 : 0;
	}

	override public function update(elapsed:Float):Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		scoreTxt.screenCenter(X);
		timeTxt.screenCenter(X);

		oppIcon.x = healthBar.width * (1 - (healthBar.value / healthBar.maxValue) + 0.5) - 75.0;
		plrIcon.x = oppIcon.x + 105.0;

		healthBar.value = FlxMath.lerp(healthBar.value, FlxMath.bound(Gameplay.instance.health, 0.0, healthBar.maxValue), SaveData.contents.preferences.smoothHealth ? 0.08 : 1.0);

		if (Gameplay.instance.startedCountdown)
		{
			timeTxt.text = Utils.formatTime(Gameplay.instance.songLength - Main.conductor.songPosition, true, true);
		}

		updateIcons();

		oppIcon.update(elapsed);
		plrIcon.update(elapsed);
		healthBar.update(elapsed);
		scoreTxt.update(elapsed);
		timeTxt.update(elapsed);
	}

	override function draw():Void
	{
		healthBar.draw();
		oppIcon.draw();
		plrIcon.draw();
		scoreTxt.draw();
		timeTxt.draw();
	}

	override function destroy():Void
	{
		if (healthBar != null)
			healthBar.destroy();

		if (oppIcon != null)
			oppIcon.destroy();

		if (plrIcon != null)
			plrIcon.destroy();

		if (scoreTxt != null)
			scoreTxt.destroy();

		if (timeTxt != null)
			timeTxt.destroy();
	}
}
