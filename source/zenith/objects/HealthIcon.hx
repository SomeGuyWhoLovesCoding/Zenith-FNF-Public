package zenith.objects;

import flixel.math.FlxRect;
import flixel.math.FlxMath;

@:access(flixel.FlxGame)
class HealthIcon extends FlxSprite
{
	public var isPlayer:Bool = false;
	public var char:String = '';
	public var parent:HealthBar;

	var _scaleA(default, null):Float = 1.0;
	var _scaleB(default, null):Float = 1.0;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		changeIcon(char);
	}

	private var iconOffsets(default, null):Array<Float> = [0.0, 0.0];

	public function changeIcon(char:String):Void
	{
		// Finally revamp the icon check shit
		var file:String = Paths.ASSET_PATH + '/images/ui/icons/$char.png';

		if (!sys.FileSystem.exists(file))
		{
			trace("Character icon image \"" + char + "\" doesn't exist!");
			file = Paths.ASSET_PATH + '/images/ui/icons/' + (char = 'face') + '.png';

			// This is alright I guess
			if (!sys.FileSystem.exists(file))
			{
				trace("Face icon image doesn't exist! Let's throw a null object reference error.");
				throw "Null Object Reference";
			}
		}

		if (this.char != char)
		{
			loadGraphic(file); // Get the file size of the graphic
			loadGraphic(file, true, Std.int(width * 0.5), Std.int(height)); // Then load it with the animation frames
			iconOffsets[0] = (width - 150.0) * 0.5;
			iconOffsets[1] = (height - 150.0) * 0.5;

			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);

			this.char = char;
			active = moves = false;
		}
	}

	override function updateHitbox()
	{
		width = (scale.x < 0.0 ? -scale.x : scale.x) * frameWidth;
		height = (scale.y < 0.0 ? -scale.y : scale.y) * frameHeight;
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
		centerOffsets();
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		if (clipRect != null)
		{
			clipRect.put();
		}

		return clipRect = rect;
	}

	inline public function bop():Void
	{
		_scaleA = 1.1;
		_scaleB = 0.125;
	}

	override function update(elapsed:Float):Void {}

	override function draw():Void
	{
		super.draw();

		if (FlxG.game._lostFocus && FlxG.autoPause)
		{
			return;
		}

		_scaleB = FlxMath.lerp(_scaleB, 0.0, FlxG.elapsed * 8.0);
		scale.x = scale.y = _scaleA + _scaleB;
		_scaleA -= (_scaleA - 1.0) * (60.0 * FlxG.elapsed);

		if (isPlayer)
			x = (parent.x + (parent.width * (1.0 - (parent.value / parent.maxValue))) + (150.0 * scale.x - 150.0) * 0.5) - 22.0;
		else
			x = (parent.x + (parent.width * (1.0 - (parent.value / parent.maxValue))) - (150.0 * scale.x) * 0.5) - 22.0 * 2.0;

		y = parent.y - (60.0 / scale.y);
	}
}