package zenith.objects;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

@:access(flixel.animation.FlxAnimationController)
@:access(flixel.animation.FlxAnimation)
class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0.0;
	public var heyTimer:Float = 0.0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	public var singDuration:Float = 4.0; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0.0, 0.0];
	public var cameraPosition:Array<Float> = [0.0, 0.0];

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, character:String = 'bf', isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Float>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		var characterPath:String = 'characters/' + curCharacter + '.json';

		var path:String = Paths.ASSET_PATH + '/' + characterPath;

		if (!FileSystem.exists(path))
			path = Paths.ASSET_PATH + '/characters/' + DEFAULT_CHARACTER + '.json'; //If a character couldn't be found, change him to BF just to prevent a crash

		var json:CharacterFile = Json.parse(File.getContent(path));

		frames = Paths.getSparrowAtlas(json.image);
		imageFile = json.image;

		if(json.scale != 1.0) {
			jsonScale = json.scale;
			setGraphicSize(Std.int(width * jsonScale));
			updateHitbox();
		}

		positionArray = json.position;
		cameraPosition = json.camera_position;

		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = !!json.flip_x;
		if(json.no_antialiasing) {
			antialiasing = false;
			noAntialiasing = true;
		}

		if(json.healthbar_colors != null && json.healthbar_colors.length > 2)
			healthColorArray = json.healthbar_colors;

		antialiasing = !noAntialiasing && SaveData.contents.preferences.antialiasing;

		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (i in 0...animationsArray.length)
			{
				var anim:AnimArray = animationsArray[i];
				var animLoop:Bool = !!anim.loop; //Bruh

				if (anim.indices != null && anim.indices.length > 0)
					animation.addByIndices('' + anim.anim, '' + anim.name, anim.indices, "", anim.fps, animLoop);
				else
					animation.addByPrefix('' + anim.anim, '' + anim.name, anim.fps, animLoop);

				if(anim.offsets != null && anim.offsets.length > 1)
					addOffset('' + anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}
		else
			quickAnimAdd('idle', 'BF idle dance');

		originalFlipX = flipX;

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
			flipX = !flipX;
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;

			if (holdTimer >= Conductor.stepCrochet * 0.00105 * singDuration)
			{
				dance();
				holdTimer = 0;
			}

			// Hey timer stuff
			if (animation.curAnim.name.startsWith('hey'))
			{
				if (heyTimer > 0)
					heyTimer -= elapsed;
				else {
					heyTimer = 0;
					dance();
				}
			}

			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
				playAnim(animation.curAnim.name + '-loop');
		}

		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (danceIdle && (!debugMode && !skipDance && !specialAnim))
		{
			danced = !danced;
			playAnim((danced ? 'danceRight' : 'danceLeft') + idleSuffix);
		}
		else
		{
			if (animation.getByName('idle' + idleSuffix) != null)
				playAnim('idle' + idleSuffix);
		}
	}

	public function playAnim(AnimName:String, special:Bool = false):Void
	{
		specialAnim = special;
		inline animation.play(AnimName, true);

		var daOffset:Array<Float> = animOffsets.get(AnimName);

		if (daOffset != null)
		{
			offset.x = daOffset[0];
			offset.y = daOffset[1];
		}
		else
			offset.x = offset.y = 0.0;

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;

			if(danceIdle)
				calc *= 0.5;
			else
				calc *= 2;

			danceEveryNumBeats = Std.int(Math.max(calc, 1.0));
		}
		settingCharacterUp = false;
	}

	inline public function addOffset(name:String, x:Float = 0, y:Float = 0)
		animOffsets[name] = [x, y];

	inline public function quickAnimAdd(name:String, anim:String)
		animation.addByPrefix(name, anim, 24, false);
}
