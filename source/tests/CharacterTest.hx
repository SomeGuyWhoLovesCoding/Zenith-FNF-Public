package tests;

using StringTools;

class CharacterTest extends MusicBeatState
{
	private var char(default, null):Character;

	private var keys(default, null):Array<flixel.input.keyboard.FlxKey> = [LEFT, DOWN, UP, RIGHT, SPACE];

	private var singAnims(default, null):Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'hey'];

	override public function create():Void
	{
		super.create();

		char = new Character(50, 50, 'bf', true);
		add(char);

		FlxG.sound.playMusic(Paths.inst('test'));
		Conductor.changeBPM(150);
	}

	override public function update(elapsed:Float):Void
	{
		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
		for (i in 0...keys.length)
		{
			if (FlxG.keys.anyJustPressed([keys[i]]))
			{
				char.playAnim(singAnims[i], true);
				if (singAnims[i] == 'hey')
					char.heyTimer = 0.6;
			}
			if (FlxG.keys.anyPressed([keys[i]]))
			{ // Make BF hold
				char.holdTimer = 0;
			}
		}
	}

	override function beatHit():Void
	{
		if (curBeat % 2 == 0 && (!char.animation.curAnim.name.startsWith('sing') && char.animation.curAnim.finished))
			char.dance();
		super.beatHit();
	}
}
