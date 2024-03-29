package zenith.objects.ui;

class HealthIcon extends FlxSprite
{
	public var isPlayer:Bool = false;
	public var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		changeIcon(char);
	}

	private var iconOffsets(default, null):Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		// Finally revamp the icon check shit
		var file:String = Paths.ASSET_PATH + '/images/icons/icon-' + char + '.png';

		if (!sys.FileSystem.exists(file))
		{
			trace("Character icon image \"" + char + "\" doesn't exist!");
			file = Paths.ASSET_PATH + '/images/icons/icon-' + (char = 'face') + '.png';

			// This is alright I guess
			if (!sys.FileSystem.exists(file))
			{
				trace("Face icon image doesn't exist! Let's throw a null object reference error.");
				throw "Null Object Reference";
			}
		}

		if(this.char != char)
		{
			loadGraphic(file); // Get the file size of the graphic
			loadGraphic(file, true, Std.int(width * 0.5), Std.int(height)); // Then load it with the animation frames
			iconOffsets[0] = iconOffsets[1] = (width - 150) * 0.5;
			updateHitbox();

			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);

			this.char = char;
			antialiasing = true;
			active = false;
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public inline function getCharacter():String
	{
		return char;
	}
}
