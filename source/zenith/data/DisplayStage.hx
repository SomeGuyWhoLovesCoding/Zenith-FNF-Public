package zenith.data;

import flixel.group.FlxGroup;

class DisplayStage
{
	private static var stageCollection:FlxGroup;

	public static function loadStage(stage:String = 'stage'):Void
	{
		var game:Gameplay = Gameplay.instance;

		if (stage == null || stage == '') // Fix stage (For vanilla charts)
			stage = 'stage';

		switch (stage)
		{
			case 'stage': // Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				game.add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				game.add(stageFront);

				var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
				stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
				stageLight.updateHitbox();
				game.add(stageLight);
				var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
				stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
				stageLight.updateHitbox();
				stageLight.flipX = true;
				game.add(stageLight);

				var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				game.add(stageCurtains);

			// Hardcode your stage here:
		}
	}
}