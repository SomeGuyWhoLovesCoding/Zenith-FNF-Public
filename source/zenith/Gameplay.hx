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
@:access(zenith.system.NoteSpawner)
@:access(zenith.system.SustainNoteSpawner)
@:access(Stack)
@:access(flixel.text.FlxText)
@:final
class Gameplay extends State
{
	private var chartBytesData(default, null):ChartBytesData;

	public var strumlines(default, null):FlxTypedGroup<Strumline>;
	public var noteSpawner(default, null):NoteSpawner;
	public var sustainNoteSpawner(default, null):SustainNoteSpawner;

	public var hudGroup(default, null):HUDGroup;

	public var health:Single = 1.0;

	public var score:Single = 0.0;
	public var misses:Single = 0.0;
	public var combo:Single = 0.0;

	var accuracy_left(default, null):Single = 0.0;
	var accuracy_right(default, null):Single = 0.0;

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

	public var songSpeed:Single = 1.0;
	public var songLength:Single = 0.0;
	public var cameraSpeed:Float = 1.0;

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
	public var hudCameraBelow:FlxCamera;
	public var hudCamera:FlxCamera;
	public var loadingScreenCamera:FlxCamera;

	public var gameCameraZoomTween(default, null):FlxTween;
	public var hudCameraZoomTween(default, null):FlxTween;

	public var defaultCamZoom(default, set):Float;

	public var camFollowPos:FlxObject;
	public var camFollowPosTween(default, null):FlxTween;

	static public var instance:Gameplay;

	public function onKeyDown(keyCode:Int, keyModifier:Int):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyDown', keyCode, keyModifier);
		#end

		if (generatedMusic && !cpuControlled)
		{
			st = inputKeybinds[keyCode % 1024] ?? Paths.idleStrumNote;

			if (st.isIdle && st.animation?.curAnim?.name != "confirm")
			{
				st.isIdle = false;
				st.playAnim("pressed");
				noteSpawner.handlePress(st);
			}
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyDownPost', keyCode, keyModifier);
		#end
	}

	public function onKeyUp(keyCode:Int, keyModifier:Int):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyUp', keyCode, keyModifier);
		#end

		if (generatedMusic && !cpuControlled)
		{
			st = inputKeybinds[keyCode % 1024] ?? Paths.idleStrumNote;

			if (!st.isIdle && st.animation?.curAnim?.name != "static")
			{
				st.isIdle = true;
				st.playAnim("static");
				sustainNoteSpawner.handleRelease(st);
			}
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyUpPost', keyCode, keyModifier);
		#end
	}

	override function create():Void
	{
		Paths.initNoteShit(); // Do NOT remove this or the game will crash

		instance = this;

		// Preferences stuff

		downScroll = SaveData.contents.preferences.downScroll;
		hideHUD = SaveData.contents.preferences.hideHUD;
		stillCharacters = SaveData.contents.preferences.stillCharacters;

		// Reset gameplay stuff
		FlxG.fixedTimestep = startedCountdown = false;
		songSpeed = 1.0;

		persistentUpdate = persistentDraw = true;

		gameCamera = new FlxCamera();
		hudCameraBelow = new FlxCamera();
		hudCamera = new FlxCamera();
		loadingScreenCamera = new FlxCamera();

		gameCamera.bgColor.alpha = hudCameraBelow.bgColor.alpha = hudCamera.bgColor.alpha = loadingScreenCamera.bgColor.alpha = 0;

		FlxG.cameras.reset(gameCamera);
		FlxG.cameras.add(hudCameraBelow, false);
		FlxG.cameras.add(hudCamera, false);
		FlxG.cameras.add(loadingScreenCamera, false);

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

	override function update(elapsed:Float):Void
	{
		if (generatedMusic)
		{
			health = FlxMath.bound(health, 0.0, (hudGroup?.healthBar?.maxValue) ?? 2.0);

			hudCameraBelow.x = hudCamera.x;
			hudCameraBelow.y = hudCamera.y;
			hudCameraBelow.angle = hudCamera.angle;
			hudCameraBelow.alpha = hudCamera.alpha;
			hudCameraBelow.zoom = hudCamera.zoom;

			if (!songEnded)
			{
				chartBytesData.update();
			}

			if (!inCutscene)
			{
				_songPos += elapsed * 1000.0;
				Main.conductor.songPosition = _songPos;
			}

			if (_songPos >= 0 && !startedCountdown)
			{
				startSong();
			}

			super.update(elapsed);
		}
	}

	var initialStrumWidth:Single = 112.0;
	var initialStrumHeight:Single = 112.0;

	var loadingTimestamp = 0.0;

	function generateSong(name:String, diff:String):Void
	{
		loadingTimestamp = haxe.Timer.stamp();

		curSong = name;
		curDifficulty = diff;

		FlxG.maxElapsed = FlxG.elapsed;

		chartBytesData = new ChartBytesData(curSong, curDifficulty);

		// What happens if you load a song with a bpm of under 10? Limit it.
		Main.conductor.bpm = SONG.info.bpm = Math.max(SONG.info.bpm, 10.0);
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
				camera_speed: 1.0
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
		inst.loadEmbedded(Paths.inst(SONG.song));

		inst.onComplete = endSong;
		FlxG.sound.list.add(inst);
		inst.looped = false;

		if (SONG.info.needsVoices)
		{
			voices = new FlxSound();
			voices.loadEmbedded(Paths.voices(SONG.song));
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

	function generateSongPost():Void
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

		sustainNoteSpawner = new SustainNoteSpawner();

		noteSpawner = new NoteSpawner();

		strumlines = new FlxTypedGroup<Strumline>();
		add(strumlines);
		add(sustainNoteSpawner);

		add(noteSpawner);

		for (i in 0...strumlineCount)
			generateStrumline(i);

		if (downScroll)
			Utils.strumlineChangeDownScroll();

		if (!hideHUD)
		{
			hudGroup = new HUDGroup();
			hudGroup.reloadHealthBar();
			add(hudGroup);
		}

		noteSpawner.camera = strumlines.camera = sustainNoteSpawner.camera = hudCamera;

		var timeTakenToLoad:Single = haxe.Timer.stamp() - loadingTimestamp;

		trace('Loading finished! Took ${Utils.formatTime(timeTakenToLoad * 1000.0, true, true)} to load.');

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

	public function generateStrumline(player:Int = 0):Void
	{
		// If the array's length is not above or equal to the strumline count, compensate for it
		while (playablelineConfiguration.length <= strumlineCount)
		{
			playablelineConfiguration.push(false);
		}

		strumlines.add(new Strumline(4, player, playablelineConfiguration[player]));
	}

	// This is good for now
	public function introHandler(tick:Int):Void
	{
		if (tick == 5)
		{
			return;
		}

		addCameraZoom(tick * 0.00375, tick * 0.00375);
	}

	public function dance(beat:Single):Void
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
	public function addCameraZoom(value1:Float = 0.015, value2:Float = 0.03):Void
	{
		if (songEnded)
		{
			return;
		}

		gameCameraZoomTween?.cancel();
		hudCameraZoomTween?.cancel();

		FlxG.camera.zoom += value1;
		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, defaultCamZoom);
		hudCamera.zoom += value2;
		hudCameraZoomTween = zoomTweenFunction(hudCamera, 1);
	}

	public function resetKeybinds(?customBinds:Array<Array<Int>>):Void
	{
		final playerStrum = strumlines.members[1]; // Prevent redundant array access
		final binds = customBinds ?? SaveData.contents.controls.GAMEPLAY_BINDS;

		inputKeybinds.resize(0);

		for (i in 0...1024)
		{
			inputKeybinds.push(Paths.idleStrumNote);
		}

		for (i in 0...binds.length)
		{
			for (j in 0...binds[i].length)
			{
				inputKeybinds[binds[i][j] % 1024] = playerStrum.members[i];
			}
		}
	}

	private function startCountdown():Void
	{
		if (songEnded)
		{
			return;
		}

		addCameraZoom();
		resetKeybinds();

		var swagCounter = 0;
		_songPos = (-Main.conductor.crochet * 5.0);
		Main.conductor.songPosition = _songPos;

		new flixel.util.FlxTimer().start(Main.conductor.crochet * 0.001, (?timer) ->
		{
			if (swagCounter != 4)
				FlxG.sound.play(Paths.sound('sounds/intro' + (swagCounter != 3 ? Std.string(3 - swagCounter) : 'Go')), 0.6);

			swagCounter++;
			introHandler(swagCounter);
			dance(swagCounter);
		}, 4);

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('startCountdown');
		#end
	}

	private function startSong():Void
	{
		if (songEnded)
		{
			return;
		}

		inst?.play();
		songLength = inst?.length ?? 0.0;

		voices?.play();

		// Just wished that null safe field access allowed modifying the variable...
		// Had to do set_visible(true) instead of visible = true to compensate for it
		hudGroup?.timeTxt?.set_text(Utils.formatTime(Gameplay.instance.songLength, true, false));

		startedCountdown = true;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('startSong');
		#end

		addCameraZoom();
		dance(0.0);
	}

	public function endSong():Void
	{
		if (songEnded)
		{
			return;
		}

		voices?.stop();

		switchState(new WelcomeState());

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('endSong');
		#end

		songEnded = true;
	}

	// Camera functions
	var _mp(default, null):FlxPoint;
	var _cpx(default, null):Single;
	var _cpy(default, null):Single;

	private function moveCamera(whatCharacter:(Character)):Void
	{
		camFollowPosTween?.cancel();

		if (!noCharacters)
		{
			_mp?.put();

			_mp = whatCharacter.getMidpoint();
			_cpx = whatCharacter.cameraPosition[0];
			_cpy = whatCharacter.cameraPosition[1];

			if (null != whatCharacter)
			{
				camFollowPosTween = FlxTween.tween(camFollowPos, {
					x: whatCharacter == gf ? _mp.x + _cpx + girlfriendCameraOffset[0] : whatCharacter == bf ? (_mp.x - 100.0) - _cpx
						- boyfriendCameraOffset[0] : (_mp.x + 150.0) + _cpx + opponentCameraOffset[0],
					y: whatCharacter == gf ? _mp.y + _cpy + girlfriendCameraOffset[1] : whatCharacter == bf ? (_mp.y - 100.0) + _cpy
						+ boyfriendCameraOffset[1] : (_mp.y - 100.0) + _cpy + opponentCameraOffset[1]
				}, 1.2 * cameraSpeed, {ease: FlxEase.expoOut});
			}
		}

		#if SCRIPTING_ALLOWEDA
		Main.hscript.callFromAllScripts('moveCamera', whatCharacter);
		#end
	}

	private function zoomTweenFunction(cam:FlxCamera, amount:Float = 1.0):FlxTween
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
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			char.x = GF_X;
			char.y = GF_Y;

			gf?.set_active(gf?.set_visible(false));
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var inputKeybinds:Array<StrumNote> = new Array<StrumNote>();

	var st(default, null):StrumNote;
	var _songPos(default, null):Single = -5000.0;

	public function changeScrollSpeed(newSpeed:Single, tweenDuration:Single = 1.0):Void
	{
		songSpeedTween?.cancel();

		var newValue = SONG.info.speed * newSpeed;

		if (tweenDuration <= 0.0)
			songSpeed = newValue;
		else
			songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, tweenDuration, {ease: FlxEase.quintOut});
	}

	public function changeSongLength(newLength:Single, tween:Bool = false):Void
	{
		songLengthTween?.cancel();

		if (tween)
			songLengthTween = FlxTween.tween(this, {songLength: newLength * 1000.0}, 1.0, {ease: FlxEase.quintOut});
		else
			songLength = newLength * 1000.0;
	}

	public var paused:Bool = false;
}
