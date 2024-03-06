package;

class HealthIcon extends FlxSprite
{
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;

		changeIcon(char);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function swapOldIcon() {
		if(isOldIcon = !isOldIcon)
			changeIcon('bf-old');
		else
			changeIcon('bf');
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String) {
		if(this.char != char) {
			var name:String = 'icons/' + char;
			if(!sys.FileSystem.exists(Paths.ASSET_PATH + '/images/' + name + '.png')) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!sys.FileSystem.exists(Paths.ASSET_PATH + '/images/' + name + '.png')) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:Dynamic = Paths.ASSET_PATH + '/images/' + name + '.png';

			loadGraphic(file); //Load stupidly first for getting the file size
			loadGraphic(file, true, Math.floor(width * 0.5), Math.floor(height)); //Then load it fr
			iconOffsets[0] = (width - 150) * 0.5;
			iconOffsets[1] = (width - 150) * 0.5;
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

	public function getCharacter():String {
		return char;
	}
}
