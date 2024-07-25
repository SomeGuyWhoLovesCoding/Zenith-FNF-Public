package zenith.objects;

import flixel.math.FlxRect;
import flixel.math.FlxMath;

@:access(flixel.FlxGame)
class HealthIcon extends FlxSprite
{
	public var isPlayer:Bool;
	public var char:String = '';
	public var parent:HealthBar;

	var _scaleA(default, null):Float = 1;
	var _scaleB(default, null):Float = 1;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		changeIcon(char);
	}

	private var iconOffsets(default, null):Array<Float> = [0, 0];

	public function changeIcon(char:String):Void
	{
		// Finally revamp the icon check shit
		var file:String = 'ui/icons/$char';

		if (!sys.FileSystem.exists(AssetManager.ASSET_PATH + '/images/' + file + '.png'))
		{
			trace("Character icon image \"" + char + "\" doesn't exist!");

			if (!sys.FileSystem.exists(AssetManager.ASSET_PATH + '/images/face.png'))
			{
				trace("Face icon image doesn't exist! Let's throw a null object reference error.");
				throw "Null Object Reference";
			}

			file = 'ui/icons/face';
			char = 'face';
		}

		if (this.char != char)
		{
			loadGraphic(AssetManager.image(file)); // Get the file size of the graphic
			loadGraphic(AssetManager.image(file), true, Std.int(width * 0.5), Std.int(height)); // Then load it with the animation frames
			iconOffsets[0] = (width - 150) * 0.5;
			iconOffsets[1] = (height - 150) * 0.5;

			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);

			this.char = char;
			@:bypassAccessor active = moves = false;
		}
	}

	override function updateHitbox()
	{
		@:bypassAccessor
		{
			width = (scale.x < 0 ? -scale.x : scale.x) * frameWidth;
			height = (scale.y < 0 ? -scale.y : scale.y) * frameHeight;
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
			centerOffsets();
		}
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
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

		@:bypassAccessor
		{
			_scaleB = FlxMath.lerp(_scaleB, 0.0, FlxG.elapsed * 8.0);
			scale.x = scale.y = _scaleA + _scaleB;
			_scaleA -= (_scaleA - 1) * (60 * FlxG.elapsed);
	
			if (isPlayer)
				x = (parent.x + (parent.width * (1 - (parent.value / parent.maxValue))) + (150 * scale.x - 150) * 0.5) - 22;
			else
				x = (parent.x + (parent.width * (1 - (parent.value / parent.maxValue))) - (150 * scale.x) * 0.5) - 22 * 2;
	
			y = parent.y - (60 / scale.y);
		}
	}
}