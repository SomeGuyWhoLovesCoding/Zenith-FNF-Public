package;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;

class HUDGroup extends FlxSpriteGroup
{
	public var oppIcon:HealthIcon;
	public var plrIcon:HealthIcon;
	public var healthBar:HealthBar;
	public var scoreTxt:FlxText;
	public var timeTxt:FlxText;

	public function new():Void
	{
		super();

		if (PlayState.hideHUD)
			return;

		oppIcon = new HealthIcon(PlayState.instance.dad.curCharacter);
		plrIcon = new HealthIcon(PlayState.instance.bf.curCharacter, true);

		healthBar = new HealthBar(0, PlayState.downScroll ? 60 : FlxG.height - 86, [0xFFFF0000], [0xFF00FF00], 600, 24);
		healthBar.screenCenter(X);
		add(healthBar);

		oppIcon.y = plrIcon.y = healthBar.y - 60;

		add(oppIcon);
		add(plrIcon);

		scoreTxt = new FlxText(0, healthBar.y + (healthBar.height + 2), 0, 'Score: ' + PlayState.instance.score + ' | Misses: 0 | Rating: ?', 20);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000);
		scoreTxt.screenCenter(X);
		add(scoreTxt);

		timeTxt = new FlxText(0, PlayState.downScroll ? FlxG.height - 42 : 8, 0, '???', 30);
		timeTxt.setBorderStyle(OUTLINE, 0xFF000000);
		timeTxt.screenCenter(X);
		timeTxt.alpha = 0;
		add(timeTxt);

		scoreTxt.borderSize = timeTxt.borderSize = 1.25;
		scoreTxt.font = timeTxt.font = Paths.font('vcr');
		scoreTxt.alignment = timeTxt.alignment = "center";
		scoreTxt.antialiasing = timeTxt.antialiasing = true;
		scoreTxt.active = timeTxt.active = false;

		oppIcon.pixelPerfectPosition = plrIcon.pixelPerfectPosition = healthBar.pixelPerfectPosition = scoreTxt.pixelPerfectPosition = timeTxt.pixelPerfectPosition = false;
	}

	private function reloadHealthBar():Void
	{
		@:privateAccess {
			healthBar.__left.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]));
			healthBar.__right.makeGraphic(healthBar.__width, healthBar.__height, FlxColor.fromRGB(PlayState.instance.bf.healthColorArray[0], PlayState.instance.bf.healthColorArray[1], PlayState.instance.bf.healthColorArray[2]));
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (PlayState.hideHUD)
			return;

		healthBar.value = FlxMath.lerp(healthBar.value, PlayState.instance.health, 0.08);

		oppIcon.x = healthBar.width * (1 - (healthBar.value / healthBar.maxValue) + 0.5) - 75;
		plrIcon.x = oppIcon.x + 105;

		scoreTxt.text = 'Score: ' + PlayState.instance.score + ' | Misses: 0 | Rating: ?';
		scoreTxt.screenCenter(X);

		if (PlayState.instance.startedCountdown)
		{
			if (timeTxt.alpha != 1)
				timeTxt.alpha += elapsed * 6;
			timeTxt.text = flixel.util.FlxStringUtil.formatTime(PlayState.instance.songLength - Conductor.songPosition, true, false);
			timeTxt.screenCenter(X);
		}

		plrIcon.animation.curAnim.curFrame = healthBar.value < 0.4 ? 1 : 0;
		oppIcon.animation.curAnim.curFrame = healthBar.value > 1.6 ? 1 : 0;
	}
}