package zenith;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;

import sys.thread.Thread;
import sys.thread.Mutex;

import sys.FileSystem;

using StringTools;

@:access(zenith.objects.HUDGroup)
@:access(zenith.system.NoteSpawner)
@:access(zenith.system.SustainNoteSpawner)
@:access(Stack)

@:final
class Gameplay extends State
{
	public var chartBytesData:ChartBytesData;

	public var strumlines:FlxTypedGroup<Strumline>;
	public var noteSpawner:NoteSpawner;
	public var sustainNoteSpawner:SustainNoteSpawner;

	private var hudGroup(default, null):HUDGroup;
	public var health:Float = 1.0;

	public var score:Float = 0.0;
	public var misses:Float = 0.0;

	var accuracy_left(default, null):Float = 0.0;
	var accuracy_right(default, null):Float = 0.0;

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

	public var songSpeed:Float = 1.0;
	public var songLength:Float = 0.0;
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

		if (inputKeybinds.exists(keyCode) && generatedMusic && !cpuControlled)
		{
			st = inputKeybinds.get(keyCode);

			if (st.isIdle && st.animation.curAnim.name != "confirm")
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

		if (inputKeybinds.exists(keyCode) && generatedMusic && !cpuControlled)
		{
			st = inputKeybinds.get(keyCode);

			if (!st.isIdle && st.animation.curAnim.name != "static")
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
		var songName:String = Sys.args()[0];

		if (null == Sys.args()[0]) // What?
			songName = 'test';

		var songDifficulty:String = Sys.args()[1];

		if (null == Sys.args()[1]) // What?
		{
			songDifficulty = 'normal';
		}
		#else
		var songName:String = 'test';
		var songDifficulty:String = 'normal';
		#end

		generateSong(songName, songDifficulty);

		super.create();

		Main.conductor.onStepHit = (curStep:Float) ->
		{
			if (curStep > 0 && !songEnded && startedCountdown && Main.conductor.songPosition > 0)
			{
				if (inline Math.abs(_songPos - inst.time) > 35)
				{
					_songPos = inst.time;
				}

				if (SONG.info.needsVoices)
				{
					if (inline Math.abs(_songPos - voices.time) > 35)
					{
						_songPos = voices.time;
					}

					if (inline Math.abs(inst.time - voices.time) > 35)
					{
						voices.time = inst.time;
					}
				}
			}
		}

		Main.conductor.onBeatHit = (curBeat:Float) ->
		{
			if (curBeat > 0 && !songEnded && startedCountdown && Main.conductor.songPosition > 0)
			{
				dance(curBeat);
			}
		}

		Main.conductor.onMeasureHit = (curMeasure:Float) ->
		{
			if (curMeasure > 0 && !songEnded && startedCountdown && Main.conductor.songPosition > 0)
			{
				addCameraZoom();
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		if (generatedMusic)
		{
			health = FlxMath.bound(health, 0.0, hudGroup != null && hudGroup.healthBar != null ? hudGroup.healthBar.maxValue : 2.0);

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

			if (hudGroup != null)
				hudGroup.update();

			return;
		}

		if (Main.ENABLE_MULTITHREADING)
		{
			if (threadsCompleted == 0)
			{
				lock = new Mutex();

				// What happens if you load a song with a bpm of under 10? Limit it.
				Main.conductor.bpm = SONG.info.bpm = Math.max(SONG.info.bpm, 10.0);
				Main.conductor.reset();

				strumlineCount == SONG.info.strumlines ? 2 : SONG.info.strumlines;

				songSpeed = SONG.info.speed;

				curStage = SONG.info.stage;

				if (curStage == null || curStage == '') // Fix stage (For vanilla charts)
					curStage = 'stage';

				var stageData:StageData.StageFile = null;

				Thread.create(() ->
				{
					stageData = StageData.getStageFile(curStage);

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

					lock.acquire();

					defaultCamZoom = FlxG.camera.zoom = stageData.defaultZoom;

					BF_X = stageData.boyfriend[0];
					BF_Y = stageData.boyfriend[1];
					GF_X = stageData.girlfriend[0];
					GF_Y = stageData.girlfriend[1];
					DAD_X = stageData.opponent[0];
					DAD_Y = stageData.opponent[1];

					if (null != stageData.camera_speed)
					{
						cameraSpeed = stageData.camera_speed;
					}

					if (null != stageData.camera_boyfriend)
					{
						boyfriendCameraOffset = stageData.camera_boyfriend;
					}

					if (null != stageData.camera_opponent)
					{
						opponentCameraOffset = stageData.camera_opponent;
					}

					if (null != stageData.camera_girlfriend)
					{
						girlfriendCameraOffset = stageData.camera_girlfriend;
					}

					threadsCompleted++;
					lock.release();
				});

				Thread.create(() ->
				{
					if (!noCharacters)
					{
						gf = new Character(0, 0, SONG.info.spectator);

						lock.acquire();

						gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
						gfGroup.add(gf);
					}
					else
						lock.acquire();

					threadsCompleted++;
					lock.release();
				});

				Thread.create(() ->
				{
					if (!noCharacters)
					{
						dad = new Character(0, 0, SONG.info.player2);

						lock.acquire();

						dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
						dadGroup.add(dad);
					}
					else
						lock.acquire();

					threadsCompleted++;
					lock.release();
				});

				Thread.create(() ->
				{
					if (!noCharacters)
					{
						bf = new Character(0, 0, SONG.info.player1, true);

						lock.acquire();

						bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
						bfGroup.add(bf);
					}
					else
						lock.acquire();

					threadsCompleted++;
					lock.release();
				});

				Thread.create(() ->
				{
					inst = new FlxSound();
					inst.loadEmbedded(Paths.inst(SONG.song));

					lock.acquire();

					inst.onComplete = endSong;
					FlxG.sound.list.add(inst);
					inst.looped = false;

					threadsCompleted++;
					lock.release();
				});

				if (SONG.info.needsVoices)
				{
					Thread.create(() ->
					{
						voices = new FlxSound();
						voices.loadEmbedded(Paths.voices(SONG.song));

						lock.acquire();

						FlxG.sound.list.add(voices);
						voices.looped = false;

						threadsCompleted++;
						lock.release();
					});
				}
				else
				{
					lock.acquire();
					threadsCompleted++;
					lock.release();
				}
			}

			if (threadsCompleted == 6)
			{
				// Finish off stage creation and add characters finally

				#if SCRIPTING_ALLOWED
				Main.hscript.callFromAllScripts('createStage', curSong, curDifficulty);
				#end

				threadsCompleted = -2;

				Thread.create(() ->
				{
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

					threadsCompleted = 7;
				});
			}

			if (threadsCompleted == 7)
			{
				generateSongPost();
			}
		}
	}

	var initialStrumWidth:Float = 112.0;
	var initialStrumHeight:Float = 112.0;

	var lock:Mutex;
	var threadsCompleted = -1;

	var loadingTimestamp = 0.0;
	function generateSong(name:String, diff:String):Void
	{
		loadingTimestamp = haxe.Timer.stamp();

		curSong = name;
		curDifficulty = diff;

		if (Main.ENABLE_MULTITHREADING)
		{
			Thread.create(() ->
			{
				loadChart();
				threadsCompleted = 0;
			});
		}
		else
		{
			FlxG.maxElapsed = FlxG.elapsed;

			loadChart();

			// What happens if you load a song with a bpm of under 10? Limit it.
			Main.conductor.bpm = SONG.info.bpm = Math.max(SONG.info.bpm, 10.0);
			Main.conductor.reset();

			strumlineCount == SONG.info.strumlines ? 2 : SONG.info.strumlines;

			songSpeed = SONG.info.speed;

			curStage = SONG.info.stage;

			if (curStage == null || curStage == '') // Fix stage (For vanilla charts)
				curStage = 'stage';

			var stageData:StageData.StageFile = null;

			// Setup stage and character groups

			stageData = StageData.getStageFile(curStage);

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

			defaultCamZoom = FlxG.camera.zoom = stageData.defaultZoom;

			BF_X = stageData.boyfriend[0];
			BF_Y = stageData.boyfriend[1];
			GF_X = stageData.girlfriend[0];
			GF_Y = stageData.girlfriend[1];
			DAD_X = stageData.opponent[0];
			DAD_Y = stageData.opponent[1];

			if (null != stageData.camera_speed)
			{
				cameraSpeed = stageData.camera_speed;
			}

			if (null != stageData.camera_boyfriend)
			{
				boyfriendCameraOffset = stageData.camera_boyfriend;
			}

			if (null != stageData.camera_opponent)
			{
				opponentCameraOffset = stageData.camera_opponent;
			}

			if (null != stageData.camera_girlfriend)
			{
				girlfriendCameraOffset = stageData.camera_girlfriend;
			}

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

			threadsCompleted++;

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

			threadsCompleted = -2;

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
		}

		noteSpawner.camera = strumlines.camera = sustainNoteSpawner.camera = hudCamera;

		var timeTakenToLoad:Float = haxe.Timer.stamp() - loadingTimestamp;

		trace('Loading finished! Took ${Utils.formatTime(timeTakenToLoad * 1000.0, true, true)} to load.');

		if (!noCharacters)
		{
			camFollowPos.setPosition(
				gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0],
				gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1]
			);

			moveCamera(dad);
		}

		generatedMusic = true;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('generateSong', curSong, curDifficulty);
		#end

		openfl.system.System.gc(); // Free up inactive memory

		startCountdown();

		threadsCompleted = -3;

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

	public function dance(beat:Float):Void
	{
		if (!noCharacters)
		{
			if (null != gf
				&& !gf.stunned
				&& 0 == beat % Math.round(gfSpeed * gf.danceEveryNumBeats)
				&& null != gf.animation.curAnim
				&& !gf.animation.curAnim.name.startsWith("sing"))
				gf.dance();

			if (null != dad
				&& !dad.stunned
				&& 0 == beat % dad.danceEveryNumBeats
				&& null != dad.animation.curAnim
				&& !dad.animation.curAnim.name.startsWith('sing')
				&& dad.animation.curAnim.finished)
				dad.dance();

			if (null != bf
				&& !bf.stunned
				&& 0 == beat % bf.danceEveryNumBeats
				&& null != bf.animation.curAnim
				&& !bf.animation.curAnim.name.startsWith('sing')
				&& bf.animation.curAnim.finished)
				bf.dance();
		}
	}

	// For hscript
	public function addCameraZoom(value1:Float = 0.015, value2:Float = 0.03):Void
	{
		if (!songEnded)
		{
			if (null != gameCameraZoomTween)
				gameCameraZoomTween.cancel();
			if (null != hudCameraZoomTween)
				hudCameraZoomTween.cancel();

			FlxG.camera.zoom += value1;
			gameCameraZoomTween = zoomTweenFunction(FlxG.camera, defaultCamZoom);
			hudCamera.zoom += value2;
			hudCameraZoomTween = zoomTweenFunction(hudCamera, 1);
		}
	}

	private function startCountdown():Void
	{
		if (!songEnded)
		{
			addCameraZoom();

			var playerStrum = strumlines.members[1]; // Prevent redundant array access

			for (i in 0...SaveData.contents.controls.GAMEPLAY_BINDS.length)
				for (j in 0...SaveData.contents.controls.GAMEPLAY_BINDS[i].length)
					inputKeybinds.set(SaveData.contents.controls.GAMEPLAY_BINDS[i][j], playerStrum.members[i]);

			var swagCounter = 0;
			_songPos = (-Main.conductor.crochet * 5.0);
			Main.conductor.songPosition = _songPos;

			new flixel.util.FlxTimer().start(Main.conductor.crochet * 0.001, (?timer) ->
			{
				if (swagCounter != 4)
				{
					if (swagCounter != 3)
						FlxG.sound.play(Paths.sound('intro' + (3 - swagCounter)), 0.6);
					else
						FlxG.sound.play(Paths.sound('introGo'), 0.6);
				}

				dance(swagCounter++);
			}, 4);

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('startCountdown');
			#end
		}
	}

	private function startSong():Void
	{
		if (!songEnded)
		{
			if (null != inst)
			{
				inst.play();
				songLength = inst.length;
			}

			if (null != voices)
			{
				voices.play();
			}

			if (null != hudGroup && null != hudGroup.timeTxt)
			{
				hudGroup.timeTxt.visible = true;
			}

			startedCountdown = true;

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('startSong');
			#end

			addCameraZoom();
			dance(0.0);
		}
	}

	public function endSong():Void
	{
		if (songEnded)
		{
			return;
		}

		if (null != voices)
		{
			voices.stop();
		}

		if (null != hudGroup && null != hudGroup.timeTxt)
		{
			hudGroup.timeTxt.visible = false;
		}

		switchState(new WelcomeState());

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('endSong');
		#end

		songEnded = true;
	}

	// Camera functions

	var _mp(default, null):FlxPoint;
	var _cpx(default, null):Float;
	var _cpy(default, null):Float;

	private function moveCamera(whatCharacter:(Character)):Void
	{
		if (null != camFollowPosTween)
			camFollowPosTween.cancel();

		if (!noCharacters)
		{
			if (_mp != null)
			{
				_mp.put();
			}

			_mp = whatCharacter.getMidpoint();
			_cpx = whatCharacter.cameraPosition[0];
			_cpy = whatCharacter.cameraPosition[1];

			if (null != whatCharacter)
			{
				camFollowPosTween = FlxTween.tween(camFollowPos, {
					x: whatCharacter == gf ? _mp.x + _cpx + girlfriendCameraOffset[0] :
						whatCharacter == bf ? (_mp.x - 100.0) - _cpx - boyfriendCameraOffset[0] :
						(_mp.x + 150.0) + _cpx + opponentCameraOffset[0],
					y: whatCharacter == gf ? _mp.y + _cpy + girlfriendCameraOffset[1] :
						whatCharacter == bf ? (_mp.y - 100.0) + _cpy + boyfriendCameraOffset[1] :
						(_mp.y - 100.0) + _cpy + opponentCameraOffset[1]
				}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut});
			}
		}

		#if SCRIPTING_ALLOWEDA
		Main.hscript.callFromAllScripts('moveCamera', whatCharacter);
		#end
	}

	private function zoomTweenFunction(cam:(FlxCamera), amount:Float = 1):FlxTween
	{
		return FlxTween.tween(cam, {zoom: amount}, 1.3, {ease: FlxEase.expoOut});
	}

	function set_defaultCamZoom(value:Float):Float
	{
		if (null != gameCameraZoomTween)
			gameCameraZoomTween.cancel();

		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, value);
		return defaultCamZoom = value;
	}

	function startCharacterPos(char:(Character), gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			char.x = GF_X;
			char.y = GF_Y;

			if (null != gf)
			{
				gf.active = gf.visible = false;
			}
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var inputKeybinds:haxe.ds.IntMap<StrumNote> = new haxe.ds.IntMap<StrumNote>();

	var nd(default, null):Array<Float>;
	var st(default, null):StrumNote;

	var _songPos(default, null):Float = -5000.0;

	function loadChart():Void
	{
		if (FileSystem.exists('assets/data/$curSong/chart/$curDifficulty.json') &&
			!FileSystem.exists('assets/data/$curSong/chart/$curDifficulty.bin'))
			ChartBytesData.saveChartFromJson(curSong, curDifficulty);

		chartBytesData = new ChartBytesData(curSong, curDifficulty);
	}

	public function changeScrollSpeed(newSpeed:Float, tweenDuration:Float = 1.0):Void
	{
		if (null != songSpeedTween)
			songSpeedTween.cancel();

		var newValue = SONG.info.speed * newSpeed;

		if (tweenDuration <= 0.0)
			songSpeed = newValue;
		else
			songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, tweenDuration, {ease: FlxEase.quintOut});
	}

	public function changeSongLength(newLength:Float, tween:Bool = false):Void
	{
		if (null != songLengthTween)
			songLengthTween.cancel();

		if (tween)
			songLengthTween = FlxTween.tween(this, {songLength: newLength * 1000.0}, 1.0, {ease: FlxEase.quintOut});
		else
			songLength = newLength * 1000.0;
	}

	public var paused:Bool = false;
}
