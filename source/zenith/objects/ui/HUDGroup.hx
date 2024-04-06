package zenith.objects.ui;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class HUDGroup extends FlxSpriteGroup
{
	public var oppIcon:HealthIcon;
	public var plrIcon:HealthIcon;
	public var healthBar:HealthBar;
	public var scoreTxt:FlxText;
	public var timeTxt:FlxText;

	public inline function new():Void
	{
		super();

		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		oppIcon = new HealthIcon(Gameplay.instance.dad.healthIcon);
		plrIcon = new HealthIcon(Gameplay.instance.bf.healthIcon, true);

		healthBar = new HealthBar(0, Gameplay.downScroll ? 60 : FlxG.height - 86, [0xFFFF0000], [0xFF00FF00], 600, 24);
		add(healthBar);

		oppIcon.y = plrIcon.y = healthBar.y - 60;

		add(oppIcon);
		add(plrIcon);

		scoreTxt = new FlxText(0, healthBar.y + (healthBar.height + 2), 0, 'Score: ' + Gameplay.instance.score + ' | Misses: ' + Gameplay.instance.misses + ' | Rating: ?', 20);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000);
		add(scoreTxt);

		timeTxt = new FlxText(0, Gameplay.downScroll ? FlxG.height - 42 : 8, 0, '???', 30);
		timeTxt.setBorderStyle(OUTLINE, 0xFF000000);
		timeTxt.alpha = 0;
		add(timeTxt);

		scoreTxt.borderSize = timeTxt.borderSize = 1.25;
		scoreTxt.font = timeTxt.font = Paths.font('vcr');
		scoreTxt.alignment = timeTxt.alignment = "center";
		scoreTxt.active = timeTxt.active = false;

		oppIcon.pixelPerfectPosition = plrIcon.pixelPerfectPosition = healthBar.pixelPerfectPosition = scoreTxt.pixelPerfectPosition = timeTxt.pixelPerfectPosition = false;
		healthBar.antialiasing = scoreTxt.antialiasing = timeTxt.antialiasing = SaveData.contents.preferences.antialiasing;
	}

	private function reloadHealthBar():Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		@:privateAccess {
			healthBar.__left.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(Gameplay.instance.dad.healthColorArray[0], Gameplay.instance.dad.healthColorArray[1], Gameplay.instance.dad.healthColorArray[2]));
			healthBar.__right.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(Gameplay.instance.bf.healthColorArray[0], Gameplay.instance.bf.healthColorArray[1], Gameplay.instance.bf.healthColorArray[2]));
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (Gameplay.hideHUD || Gameplay.noCharacters)
			return;

		healthBar.screenCenter(X);
		scoreTxt.screenCenter(X);
		timeTxt.screenCenter(X);

		oppIcon.x = healthBar.width * (1 - (healthBar.value / healthBar.maxValue) + 0.5) - 75;
		plrIcon.x = oppIcon.x + 105;

		healthBar.value = inline FlxMath.lerp(healthBar.value, inline FlxMath.bound(Gameplay.instance.health, 0, healthBar.maxValue), SaveData.contents.preferences.smoothHealth ? 0.08 : 1);

		scoreTxt.text = 'Score: ' + Gameplay.instance.score + ' | Misses: ' + Gameplay.instance.misses + ' | Rating: ?';

		if (Gameplay.instance.startedCountdown)
		{
			if (timeTxt.alpha != 1)
				timeTxt.alpha += elapsed * 6;
			timeTxt.text = inline flixel.util.FlxStringUtil.formatTime(Gameplay.instance.songLength - Conductor.songPosition, true, false);
		}

		plrIcon.animation.curAnim.curFrame = healthBar.value < 0.4 ? 1 : 0;
		oppIcon.animation.curAnim.curFrame = healthBar.value > 1.6 ? 1 : 0;

		super.update(elapsed);
	}
}