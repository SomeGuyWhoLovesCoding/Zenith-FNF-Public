package zenith;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import sys.FileSystem;

using StringTools;

@:access(zenith.objects.HUDGroup)
@:access(flixel.text.FlxText)
@:final
class Gameplay extends State
{
	private var chartBytesData(default, null):ChartBytesData;

	public var strumlines(default, null):Array<Strumline> = [];

	public var hudGroup(default, null):HUDGroup;

	public var health:Float = 1;

	public var score:Float = 0;
	public var misses:Float = 0;
	public var combo:Float = 0;

	var accuracy_left(default, null):Float = 0;
	var accuracy_right(default, null):Float = 0;

	// Preference stuff
	static public var cpuControlled:Bool = false;
	static public var downScroll:Bool = true;
	static public var hideHUD:Bool = false;
	static public var noCharacters:Bool = false;
	static public var stillCharacters:Bool = false;

	// Song stuff
	static public var SONG:Song;

	// Gameplay stuff
	// For events
	public var curSong:String = 'test';
	public var curDifficulty:String = '';
	public var curStage:String = 'stage';

	public var BF_X:Int = 770;
	public var BF_Y:Int = 100;
	public var DAD_X:Int = 100;
	public var DAD_Y:Int = 100;
	public var GF_X:Int = 400;
	public var GF_Y:Int = 130;

	public var bfGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	// This is used to precache characters before loading in the song, like the change character event.
	public var bfMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var boyfriendCameraOffset:Array<Int> = [0, 0];
	public var opponentCameraOffset:Array<Int> = [0, 0];
	public var girlfriendCameraOffset:Array<Int> = [0, 0];

	public var songSpeedTween(default, null):FlxTween;
	public var songLengthTween(default, null):FlxTween;

	public var songSpeed:Float = 1;
	public var songLength:Float = 0;
	public var cameraSpeed:Float = 1;

	public var generatedMusic:Bool = false;
	public var inCutscene:Bool = false;
	public var startedCountdown:Bool = false;
	public var songEnded:Bool = false;

	public var gfSpeed:Int = 1;

	public var inst:FlxSound;
	public var voices:FlxSound;

	public var gf:Character;
	public var dad:Character;
	public var bf:Character;

	public var gameCamera:FlxCamera;
	public var hudCamera:FlxCamera;

	public var gameCameraZoomTween(default, null):FlxTween;
	public var hudCameraZoomTween(default, null):FlxTween;

	public var defaultCamZoom(default, set):Float;

	public var camFollowPos:FlxObject;
	public var camFollowPosTween(default, null):FlxTween;

	static public var instance:Gameplay;

	public function onKeyDown(keyCode:Int, keyModifier:Int)
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyDown', keyCode, keyModifier);
		#end

		if (generatedMusic && !cpuControlled)
		{
			st = inputKeybinds[keyCode % 1024] ?? NoteskinHandler.idleStrumNote;

			if (!st.active)
			{
				st.handlePress();
			}
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyDownPost', keyCode, keyModifier);
		#end
	}

	public function onKeyUp(keyCode:Int, keyModifier:Int)
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyUp', keyCode, keyModifier);
		#end

		if (generatedMusic && !cpuControlled)
		{
			st = inputKeybinds[keyCode % 1024] ?? NoteskinHandler.idleStrumNote;

			if (st.active)
			{
				st.handleRelease();
			}
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyUpPost', keyCode, keyModifier);
		#end
	}

	override function create()
	{
		instance = this;

		// Preferences stuff

		downScroll = SaveData.contents.preferences.downScroll;
		hideHUD = SaveData.contents.preferences.hideHUD;
		stillCharacters = SaveData.contents.preferences.stillCharacters;

		// Reset gameplay stuff
		FlxG.fixedTimestep = startedCountdown = false;
		songSpeed = 1;

		persistentUpdate = persistentDraw = true;

		gameCamera = new FlxCamera();
		hudCamera = new FlxCamera();

		gameCamera.bgColor.alpha = hudCamera.bgColor.alpha = 0;

		FlxG.cameras.reset(gameCamera);
		FlxG.cameras.add(hudCamera, false);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.pixelPerfectPosition = false;

		FlxG.cameras.setDefaultDrawTarget(gameCamera, true);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		#if !hl
		var songName:String = Sys.args()[0] ?? 'test';
		var songDifficulty:String = Sys.args()[1] ?? 'normal';
		#else
		var songName:String = 'test';
		var songDifficulty:String = 'normal';
		#end

		generateSong(songName, songDifficulty);

		super.create();

		Main.conductor.onStepHit = (curStep:Single) ->
		{
			if (curStep < 0 || songEnded || !startedCountdown || Main.conductor.songPosition < 0)
			{
				return;
			}

			if (Math.abs(_songPos - inst.time) > 5)
			{
				_songPos = inst.time;
			}

			if (SONG.info.needsVoices)
			{
				if (Math.abs(_songPos - voices.time) > 5)
				{
					_songPos = voices.time;
				}

				if (Math.abs(inst.time - voices.time) > 5)
				{
					voices.time = inst.time;
				}
			}
		}

		Main.conductor.onBeatHit = (curBeat:Single) ->
		{
			if (curBeat < 0 || songEnded || !startedCountdown || Main.conductor.songPosition < 0)
			{
				return;
			}

			hudGroup?.oppIcon?.bop();
			hudGroup?.plrIcon?.bop();
			dance(curBeat);
		}

		Main.conductor.onMeasureHit = (curMeasure:Single) ->
		{
			if (curMeasure < 0 || songEnded || !startedCountdown || Main.conductor.songPosition < 0)
			{
				return;
			}

			addCameraZoom();
		}
	}

	override function update(elapsed:Float)
	{
		if (generatedMusic)
		{
			health = FlxMath.bound(health, 0, hudGroup?.healthBar?.maxValue ?? 2);

			if (!songEnded)
			{
				chartBytesData.update();
			}

			if (!inCutscene)
			{
				_songPos += elapsed * 1000;
				Main.conductor.songPosition = _songPos;
			}

			if (_songPos >= 0 && !startedCountdown)
			{
				startSong();
			}

			super.update(elapsed);
		}
	}

	override function draw()
	{
		super.draw();

		var strums = strumlines;
		var len = strums.length;

		for (i in 0...len)
		{
			strums[i].draw();
		}

		var hud = hudGroup;

		if (hud != null)
		{
			hud.draw();
		}
	}

	var loadingTimestamp:Float = 0;

	function generateSong(name:String, diff:String)
	{
		loadingTimestamp = haxe.Timer.stamp();

		curSong = name;
		curDifficulty = diff;

		FlxG.maxElapsed = FlxG.elapsed;

		chartBytesData = new ChartBytesData(curSong, curDifficulty);

		NoteskinHandler.reload(chartBytesData.global_noteskin);

		// What happens if you load a song with a bpm of under 10? Limit it.
		Main.conductor.bpm = SONG.info.bpm = Math.max(SONG.info.bpm, 10);
		Main.conductor.reset();

		strumlineCount == SONG.info.strumlines ? 2 : SONG.info.strumlines;

		songSpeed = SONG.info.speed;

		curStage = SONG.info.stage ?? 'stage';

		if (curStage == '') // For vanilla charts
			curStage = 'stage';

		var stageData:StageData.StageFile = StageData.getStageFile(curStage);

		if (null == stageData) // Stage doesn't exist, create a dummy stage to prevent crashing
		{
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		FlxG.camera.zoom = defaultCamZoom = stageData.defaultZoom;

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		cameraSpeed = stageData?.camera_speed;
		boyfriendCameraOffset = stageData?.camera_boyfriend;
		opponentCameraOffset = stageData?.camera_opponent;
		girlfriendCameraOffset = stageData?.camera_girlfriend;

		if (!noCharacters)
		{
			gf = new Character(0, 0, SONG.info.spectator);
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
			gfGroup.add(gf);

			dad = new Character(0, 0, SONG.info.player2);
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
			dadGroup.add(dad);

			bf = new Character(0, 0, SONG.info.player1, true);
			bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
			bfGroup.add(bf);
		}

		inst = new FlxSound();
		inst.loadEmbedded(AssetManager.inst(SONG.song));

		inst.onComplete = endSong;
		FlxG.sound.list.add(inst);
		inst.looped = false;

		if (SONG.info.needsVoices)
		{
			voices = new FlxSound();
			voices.loadEmbedded(AssetManager.voices(SONG.song));
			FlxG.sound.list.add(voices);
			voices.looped = false;
		}

		// Finish off stage creation and add characters finally

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('createStage', curSong, curDifficulty);
		#end

		if (!noCharacters && curStage == 'stage')
		{
			var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
			add(bg);

			var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			add(stageFront);

			var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			add(stageLight);

			var stageLight2:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
			stageLight2.setGraphicSize(Std.int(stageLight2.width * 1.1));
			stageLight2.updateHitbox();
			stageLight2.flipX = true;
			add(stageLight2);

			var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			add(stageCurtains);
		}

		generateSongPost();
	}

	function generateSongPost()
	{
		add(gfGroup);
		add(dadGroup);
		add(bfGroup);

		startCharacterPos(gf, false);
		startCharacterPos(dad, true);
		startCharacterPos(bf, false);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('createStagePost', curSong, curDifficulty);
		#end

		// Now time to load the UI and shit

		for (i in 0...strumlineCount)
			generateStrumline(i);

		if (downScroll)
			Tools.strumlineChangeDownScroll();

		if (!hideHUD)
		{
			hudGroup = new HUDGroup();
			hudGroup.reloadHealthBar();
			hudGroup.camera = hudCamera;
		}

		var timeTakenToLoad:Single = haxe.Timer.stamp() - loadingTimestamp;

		trace('Loading finished! Took ${Tools.formatTime(timeTakenToLoad * 1000, true, true)} to load.');

		if (!noCharacters)
		{
			camFollowPos.setPosition(gf.getMidpoint().x
				+ gf.cameraPosition[0]
				+ girlfriendCameraOffset[0],
				gf.getMidpoint().y
				+ gf.cameraPosition[1]
				+ girlfriendCameraOffset[1]);

			moveCamera(dad);
		}

		generatedMusic = true;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('generateSong', curSong, curDifficulty);
		#end

		openfl.system.System.gc(); // Free up inactive memory

		startCountdown();

		FlxG.autoPause = true;
	}

	static public var strumlineCount:Int = 2;
	static public var playablelineConfiguration:Array<Bool> = [false, true];

	public function generateStrumline(player:Int = 0)
	{
		// If the array's length is not above or equal to the strumline count, compensate for it
		while (playablelineConfiguration.length <= strumlineCount)
		{
			playablelineConfiguration.push(false);
		}

		var strumline = new Strumline(4, player, playablelineConfiguration[player]);
		strumline.targetCharacter = !strumline.playable ? dad : bf;
		strumlines.push(strumline);
	}

	// This is good for now
	public function introHandler(tick:Int)
	{
		if (tick == 5)
		{
			return;
		}

		addCameraZoom(tick * 0.00375, tick * 0.00375);
	}

	public function dance(beat:Float)
	{
		if (!noCharacters)
		{
			if (null != gf
				&& !gf.stunned
				&& 0 == beat % Math.round(gfSpeed * gf.danceEveryNumBeats)
				&& !gf.animation.curAnim?.name.startsWith("sing"))
				gf.dance();

			if (null != dad
				&& !dad.stunned
				&& 0 == beat % dad.danceEveryNumBeats
				&& !dad.animation.curAnim?.name.startsWith('sing')
				&& dad.animation.curAnim.finished)
				dad.dance();

			if (null != bf
				&& !bf.stunned
				&& 0 == beat % bf.danceEveryNumBeats
				&& !bf.animation.curAnim?.name.startsWith('sing')
				&& bf.animation.curAnim.finished)
				bf.dance();
		}
	}

	// For hscript
	public function addCameraZoom(value1:Float = 0.015, value2:Float = 0.03)
	{
		if (songEnded)
		{
			return;
		}

		if (gameCameraZoomTween != null)
		{
			gameCameraZoomTween.cancel();
		}

		if (hudCameraZoomTween != null)
		{
			hudCameraZoomTween.cancel();
		}

		FlxG.camera.zoom += value1;
		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, defaultCamZoom);
		hudCamera.zoom += value2;
		hudCameraZoomTween = zoomTweenFunction(hudCamera, 1);
	}

	public function resetKeybinds(?customBinds:Array<Array<Int>>)
	{
		final playerStrum = strumlines[1]; // Prevent redundant array access
		final binds = customBinds ?? SaveData.contents.controls.GAMEPLAY_BINDS;

		inputKeybinds.resize(0);

		for (i in 0...1024)
		{
			inputKeybinds.push(NoteskinHandler.idleStrumNote);
		}

		for (i in 0...binds.length)
		{
			for (j in 0...binds[i].length)
			{
				inputKeybinds[binds[i][j] % 1024] = playerStrum.members[i];
			}
		}
	}

	private function startCountdown()
	{
		if (songEnded)
		{
			return;
		}

		addCameraZoom();
		resetKeybinds();

		var swagCounter = 0;
		_songPos = (-Main.conductor.crochet * 5);
		Main.conductor.songPosition = _songPos;

		new flixel.util.FlxTimer().start(Main.conductor.crochet * 0.001, (?timer) ->
		{
			if (swagCounter != 4)
				FlxG.sound.play(AssetManager.sound('intro' + (swagCounter != 3 ? Std.string(3 - swagCounter) : 'Go')), 0.6);

			swagCounter++;
			introHandler(swagCounter);
			dance(swagCounter);
		}, 4);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('startCountdown');
		#end
	}

	private function startSong()
	{
		if (songEnded)
		{
			return;
		}

		if (inst != null)
		{
			inst.play();
			songLength = inst.length;
		}
		else
			songLength = 0;

		voices?.play();

		if (hudGroup != null && hudGroup.timeTxt != null)
		{
			hudGroup.timeTxt.text = Tools.formatTime(songLength, true, false);
		}

		startedCountdown = true;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('startSong');
		#end

		addCameraZoom();
		dance(0);
	}

	public function endSong()
	{
		if (songEnded)
		{
			return;
		}

		if (voices != null)
		{
			voices.stop();
		}

		switchState(new WelcomeState());

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('endSong');
		#end

		songEnded = true;
	}

	// Camera functions

	private function moveCamera(whatCharacter:Character)
	{
		camFollowPosTween?.cancel();

		if (!noCharacters)
		{
			var _mp = whatCharacter.getMidpoint();
			var _cpx = whatCharacter.cameraPosition[0];
			var _cpy = whatCharacter.cameraPosition[1];

			if (null != whatCharacter)
			{
				camFollowPosTween = FlxTween.tween(camFollowPos, {
					x: whatCharacter == gf ? _mp.x + _cpx +
					girlfriendCameraOffset[0] : whatCharacter == bf ? (_mp.x - 100) - _cpx - boyfriendCameraOffset[0] : (_mp.x
						+ 150) + _cpx + opponentCameraOffset[0],
					y: whatCharacter == gf ? _mp.y + _cpy + girlfriendCameraOffset[1] : whatCharacter == bf ? (_mp.y - 100) + _cpy +
						boyfriendCameraOffset[1] : (_mp.y
						- 100) + _cpy + opponentCameraOffset[1]
				}, 1.2 * cameraSpeed, {ease: FlxEase.expoOut});
			}
		}

		#if SCRIPTING_ALLOWEDA
		Main.hscript.callFromAllScripts('moveCamera', whatCharacter);
		#end
	}

	private function zoomTweenFunction(cam:FlxCamera, amount:Float = 1):FlxTween
	{
		return FlxTween.tween(cam, {zoom: amount}, 1.2, {ease: FlxEase.expoOut});
	}

	function set_defaultCamZoom(value:Float):Float
	{
		gameCameraZoomTween?.cancel();
		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, value);
		return defaultCamZoom = value;
	}

	function startCharacterPos(char:Character, gfCheck:Bool = false)
	{
		@:bypassAccessor
		{
			if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			{
				char.x = GF_X;
				char.y = GF_Y;

				if (gf != null)
				{
					gf.active = gf.visible = false;
				}
			}

			char.x += char.positionArray[0];
			char.y += char.positionArray[1];
		}
	}

	public var inputKeybinds:Array<StrumNote> = [];

	var st(default, null):StrumNote;
	var _songPos(default, null):Float = -5000;

	public function changeScrollSpeed(newSpeed:Float, tweenDuration:Float = 1)
	{
		if (songSpeedTween != null)
		{
			songSpeedTween.cancel();
		}

		var newValue = SONG.info.speed * newSpeed;

		if (tweenDuration <= 0)
			songSpeed = newValue;
		else
			songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, tweenDuration, {ease: FlxEase.quintOut});
	}

	public function changeSongLength(newLength:Float, tween:Bool = false)
	{
		if (songLengthTween != null)
		{
			songLengthTween.cancel();
		}

		if (tween)
			songLengthTween = FlxTween.tween(this, {songLength: newLength * 1000}, 1, {ease: FlxEase.quintOut});
		else
			songLength = newLength * 1000;
	}

	public var paused:Bool = false;
}
