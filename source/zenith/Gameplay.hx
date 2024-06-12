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

	inline public function onKeyDown(keyCode:Int, keyModifier:Int):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyDown', keyCode, keyModifier);
		#end

		if (inline inputKeybinds.exists(keyCode) && generatedMusic && !cpuControlled)
		{
			st = inline inputKeybinds.get(keyCode);

			if (!st.active)
			{
				if (st.animation.curAnim.name != "confirm")
					st.playAnim("pressed");

				noteSpawner.handleHittableNote(st);
			}

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('onKeyDownPost', keyCode, keyModifier);
			#end
		}
	}

	inline public function onKeyUp(keyCode:Int, keyModifier:Int):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('onKeyUp', keyCode, keyModifier);
		#end

		if (inline inputKeybinds.exists(keyCode) && generatedMusic && !cpuControlled)
		{
			st = inline inputKeybinds.get(keyCode);

			if (st.active)
			{
				if (st.animation.curAnim.name != "static")
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

		// Cause the hscript system loads all the scripts after loading in the song :sob:

		preventHScript = true;

		#if SCRIPTING_ALLOWED
		Main.hscript.loadScriptsFromDirectory('assets/scripts');

		for (script in Main.hscript.list.keys())
		{
			Main.hscript.list[script].interp.variables.set('curState', Type.getClassName(Type.getClass(FlxG.state)));
		}

		Main.hscript.callFromAllScripts('createPre');
		#end

		// Preferences stuff

		downScroll = SaveData.contents.preferences.downScroll;
		hideHUD = SaveData.contents.preferences.hideHUD;
		stillCharacters = SaveData.contents.preferences.stillCharacters;

		// Reset gameplay stuff
		FlxG.fixedTimestep = startedCountdown = songEnded = false;
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

			// Don't progress further if the song has ended

			if (!songEnded)
			{
				if (startedCountdown)
				{
					_songPos = inst.time;
				}
				else
				{
					_songPos += elapsed * 1000.0;
				}

				chartBytesData.update();
			}
			else
				_songPos = inst.length;

			Main.conductor.songPosition = FlxMath.lerp(Main.conductor.songPosition, _songPos, FlxG.elapsed * 10.215);

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

						voices.onComplete = endSong;
						FlxG.sound.list.add(voices);
						voices.looped = false;

						threadsCompleted++;
	
						lock.release();
					});
				}
				else
				{
					threadsCompleted++;

				}
			}

			if (threadsCompleted == 6)
			{
				// Finish off stage creation and add characters finally

				if (!noCharacters)
				{
					#if SCRIPTING_ALLOWED
					Main.hscript.callFromAllScripts('createStage', curSong, curDifficulty);
					#end
				}

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
				if (!noCharacters)
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
				}

				// Now time to load the UI and shit

				sustainNoteSpawner = new SustainNoteSpawner();
				add(sustainNoteSpawner);

				noteSpawner = new NoteSpawner();

				strumlines = new FlxTypedGroup<Strumline>();
				add(strumlines);

				add(noteSpawner);

				for (i in 0...strumlineCount)
					generateStrumline(i);

				if (downScroll)
					changeDownScroll();

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

				preventHScript = false;
				generatedMusic = true;

				#if SCRIPTING_ALLOWED
				Main.hscript.callFromAllScripts('generateSong', curSong, curDifficulty);
				#end

				openfl.system.System.gc(); // Free up inactive memory

				startCountdown();

				threadsCompleted = -3;

				FlxG.autoPause = true;
			}
		}
	}

	var initialStrumWidth:Float = 112.0;
	var initialStrumHeight:Float = 112.0;

	// Song events for hscript
	public function triggerEvent(eventName:String, value1:String, value2:String, value3:String, value4:String)
	{
		switch (eventName)
		{
			case 'Hey!':
				if (!noCharacters)
				{
					var value = 2;
					switch (value1.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend' | '0':
							value = 0;
						case 'gf' | 'girlfriend' | '1':
							value = 1;
					}

					var time = Std.parseFloat(value2);
					if (Math.isNaN(time) || time <= 0)
						time = 0.6;

					if (value == 1)
					{
						if (null != gf)
						{
							gf.playAnim('cheer');
							gf.heyTimer = time;
						}
						if (null != dad && dad.curCharacter == gf.curCharacter)
						{
							dad.playAnim('cheer');
							dad.heyTimer = time;
						}
					}
					else
					{
						if (null != bf) {
							bf.playAnim('hey');
							bf.heyTimer = time;
						}
					}
				}

			case 'Set GF Speed':
				var value = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1)
					value = 1;

				gfSpeed = value;

			case 'Add Camera Zoom':
				if (FlxG.camera.zoom < 1.35)
				{
					var camZoom = Std.parseFloat(value1);
					var hudZoom = Std.parseFloat(value2);

					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					if (null != gameCameraZoomTween)
						gameCameraZoomTween.cancel();
					if (null != hudCameraZoomTween)
						hudCameraZoomTween.cancel();

					FlxG.camera.zoom += camZoom;
					gameCameraZoomTween = zoomTweenFunction(FlxG.camera, defaultCamZoom);
					hudCamera.zoom += hudZoom;
					hudCameraZoomTween = zoomTweenFunction(hudCamera, 1);
				}

			case 'Play Animation':
				if (!noCharacters)
				{
					var char = dad;
					switch (value2.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend':
							char = bf;
						case 'gf' | 'girlfriend':
							char = gf;
						default:
							var val2 = Std.parseInt(value2);
							if (Math.isNaN(val2))
								val2 = 0;

							switch (val2)
							{
								case 1: char = bf;
								case 2: char = gf;
							}
					}

					if (null != char)
						char.playAnim(value1);
				}

			case 'Change Character':
				if (!noCharacters)
				{
					var charType = 0;
					switch (value1.toLowerCase().trim())
					{
						case 'gf' | 'girlfriend':
							charType = 2;
						case 'dad' | 'opponent':
							charType = 1;
						default:
							charType = Std.parseInt(value1);
							if (Math.isNaN(charType))
								charType = 0;
					}

					switch(charType)
					{
						case 0:
							if(bf.curCharacter != value2)
							{
								if(!bfMap.exists(value2))
									addCharacterToList(value2, charType);

								var lastAlpha = bf.alpha;
								bf.alpha = 0.001;
								bf = bfMap.get(value2);
								bf.alpha = lastAlpha;
								if (hudGroup != null && hudGroup.plrIcon != null)
									hudGroup.plrIcon.changeIcon(bf.healthIcon);
							}

						case 1:
							if(dad.curCharacter != value2)
							{
								if(!dadMap.exists(value2))
									addCharacterToList(value2, charType);

								var wasGf = dad.curCharacter.startsWith('gf');
								var lastAlpha = dad.alpha;
								dad.alpha = 0.001;
								dad = dadMap.get(value2);

								if(null != gf)
									gf.visible = !dad.curCharacter.startsWith('gf') && wasGf;

								dad.alpha = lastAlpha;
								if (hudGroup != null && hudGroup.oppIcon != null)
									hudGroup.oppIcon.changeIcon(dad.healthIcon);
							}

						case 2:
							if(null != gf)
							{
								if(gf.curCharacter != value2)
								{
									if(!gfMap.exists(value2))
										addCharacterToList(value2, charType);

									var lastAlpha = gf.alpha;
									gf.alpha = 0.001;
									gf = gfMap.get(value2);
									gf.alpha = lastAlpha;
								}
							}
					}
				}

				if (hudGroup != null)
					hudGroup.reloadHealthBar();

			case 'Change Scroll Speed':
				if (null != songSpeedTween)
					songSpeedTween.cancel();

				var val1 = Std.parseFloat(value1);
				var val2 = Std.parseFloat(value2);

				if (Math.isNaN(val1))
					val1 = 1.0;
				if (Math.isNaN(val2))
					val2 = 0.0;

				var newValue = SONG.info.speed * val1;

				if (val2 <= 0.0)
					songSpeed = newValue;
				else
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.quintOut});

			case 'Fake Song Length':
				if (null != songLengthTween)
					songLengthTween.cancel();

				var v1 = Std.parseFloat(value1);

				if (!Math.isNaN(v1))
				{
					if (value2 == 'true')
						songLengthTween = FlxTween.tween(this, {songLength: v1 * 1000.0}, 1.0, {ease: FlxEase.quintOut});
					else
						songLength = v1 * 1000.0;
				}
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts('triggerEvent', eventName, value1, value2, value3, value4);
		#end
	}

	var lock:Mutex;
	var threadsCompleted = -1;

	var loadingTimestamp = 0.0;
	inline private function generateSong(name:String, diff:String):Void
	{
		loadingTimestamp = haxe.Timer.stamp();

		curSong = name;
		curDifficulty = diff;

		if (Main.ENABLE_MULTITHREADING)
		{
			loadChart();
			threadsCompleted = 0;
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
				voices.onComplete = endSong;
				FlxG.sound.list.add(voices);
				voices.looped = false;
			}

			// Finish off stage creation and add characters finally

			threadsCompleted = -2;

			if (!noCharacters && curStage == 'stage')
			{
				#if SCRIPTING_ALLOWED
				Main.hscript.callFromAllScripts('createStage', curSong, curDifficulty);
				#end

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

				add(gfGroup);
				add(dadGroup);
				add(bfGroup);
	
				startCharacterPos(gf, false);
				startCharacterPos(dad, true);
				startCharacterPos(bf, false);

				#if SCRIPTING_ALLOWED
				Main.hscript.callFromAllScripts('createStagePost', curSong, curDifficulty);
				#end
			}

			// Now time to load the UI and shit

			sustainNoteSpawner = new SustainNoteSpawner();
			add(sustainNoteSpawner);

			noteSpawner = new NoteSpawner();

			strumlines = new FlxTypedGroup<Strumline>();
			add(strumlines);

			add(noteSpawner);

			for (i in 0...strumlineCount)
				generateStrumline(i);

			if (downScroll)
				changeDownScroll();

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

			preventHScript = false;
			generatedMusic = true;

			#if SCRIPTING_ALLOWED
			Main.hscript.callFromAllScripts('generateSong', curSong, curDifficulty);
			#end

			openfl.system.System.gc(); // Free up inactive memory

			startCountdown();

			FlxG.maxElapsed = 0.1;
		}
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
			Main.conductor.songPosition = _songPos - 100.0;

			new flixel.util.FlxTimer().start(Main.conductor.crochet * 0.001, (?timer) ->
			{
				if (swagCounter != 4)
				{
					if (swagCounter != 3)
					{
						FlxG.sound.play(Paths.sound('intro' + (3 - swagCounter)), 0.6);
					}
					else
					{
						FlxG.sound.play(Paths.sound('introGo'), 0.6);
					}
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
		songEnded = true;

		if (null != inst)
		{
			inst.stop();
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
		return FlxTween.tween(cam, {zoom: amount}, 1.3, {ease: FlxEase.expoOut});

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

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!bfMap.exists(newCharacter)) {
					var newBoyfriend = new Character(0, 0, newCharacter, true);
					bfMap.set(newCharacter, newBoyfriend);
					bfGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.001;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.001;
				}

			case 2:
				if(null != gf && !gfMap.exists(newCharacter)) {
					var newGf = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.001;
				}
		}
	}

	public var inputKeybinds:haxe.ds.IntMap<StrumNote> = new haxe.ds.IntMap<StrumNote>();

	var strumYTweens(default, null):Map<StrumNote, FlxTween> = new Map<StrumNote, FlxTween>();
	var strumScrollMultTweens(default, null):Map<StrumNote, FlxTween> = new Map<StrumNote, FlxTween>();
	public function changeDownScroll(whichStrum:Int = -1, tween:Bool = false, tweenLength:Float = 1.0):Void
	{
		// Strumline
		for (strumline in strumlines.members)
		{
			for (strum in strumline.members)
			{
				if (strum.player == whichStrum || whichStrum == -1)
				{
					if (tween && tweenLength != 0.0)
					{
						var actualScrollMult = strum.scrollMult;
						actualScrollMult = -actualScrollMult;

						var scrollMultTween = strumScrollMultTweens[strum];
						var yTween = strumYTweens[strum];

						if (null != scrollMultTween)
							scrollMultTween.cancel();

						strumScrollMultTweens.set(strum, FlxTween.tween(strum, {scrollMult: strum.scrollMult > 0.0 ? -1.0 : 1.0}, (tweenLength < 0.0 ? -tweenLength : tweenLength), {ease: FlxEase.quintOut}));

						if (null != yTween)
							yTween.cancel();

						strumYTweens.set(strum, FlxTween.tween(strum, {y: actualScrollMult < 0.0 ? FlxG.height - 160.0 : 60.0}, (tweenLength < 0.0 ? -tweenLength : tweenLength), {ease: FlxEase.quintOut}));
					}
					else
					{
						strum.scrollMult = -strum.scrollMult;
					}
				}

				if (strum.noteData == strumline.keys - 1)
				{
					strumline.downScroll = strum.scrollMult < 0.0;
				}
			}
			strumline.y = strumline.downScroll ? FlxG.height - 160.0 : 60.0;
		}
	}

	var nd(default, null):Array<Float>;
	var st(default, null):StrumNote;

	var _songPos(default, null):Float = -5000.0;

	function onNoteHit(note:Note):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteHit", note);
		#end

		note.strum.playAnim("confirm");

		health += 0.045 * (note.strum.playable ? 1.0 : -1.0);

		if (note.strum.playable)
		{
			score += 350.0;
			accuracy_left += ((note.position - Main.conductor.songPosition < 0.0 ? -(note.position - Main.conductor.songPosition) :
				note.position - Main.conductor.songPosition) > 83.35 ? 0.75 : 1.0);
			accuracy_right++;
		}

		if (!noCharacters)
		{
			if (null != note.targetCharacter)
			{
				note.targetCharacter.playAnim(note.strum.parent.singAnimations(note.noteData));
				note.targetCharacter.holdTimer = 0.0;
			}
		}

		note.state = HIT;
		note.exists = false;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteHitPost", note);
		#end

		if (hudGroup != null)
			hudGroup.updateScoreText();
	}

	function onNoteMiss(note:Note):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteMiss", note);
		#end

		note.state = MISS;
		note.alpha = 0.6;

		health -= 0.045;
		score -= 100.0;
		misses++;
		accuracy_right++;

		if (!noCharacters)
		{
			note.targetCharacter.playAnim(note.strum.parent.singAnimations(note.noteData) + "miss");
			note.targetCharacter.holdTimer = 0.0;
		}

		if (hudGroup != null)
			hudGroup.updateScoreText();

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteMissPost", note);
		#end
	}

	function onHold(sustain:SustainNote):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onHold", sustain);
		#end

		sustain.strum.playAnim("confirm");

		health += FlxG.elapsed * (sustain.strum.playable ? 0.125 : -0.125);

		if (!noCharacters)
		{
			if (null != sustain.targetCharacter)
			{
				if (Gameplay.stillCharacters)
					sustain.targetCharacter.playAnim(sustain.strum.parent.singAnimations(sustain.noteData));
				else
				{
					// This shit is similar to amazing engine's character hold fix, but better

					if (sustain.targetCharacter.animation.curAnim.name == sustain.strum.parent.singAnimations(sustain.noteData) + "miss")
						sustain.targetCharacter.playAnim(sustain.strum.parent.singAnimations(sustain.noteData));

					if (sustain.targetCharacter.animation.curAnim.curFrame > (sustain.targetCharacter.stillCharacterFrame == -1 ?
						sustain.targetCharacter.animation.curAnim.frames.length : sustain.targetCharacter.stillCharacterFrame))
						sustain.targetCharacter.animation.curAnim.curFrame = (sustain.targetCharacter.stillCharacterFrame == -1 ?
						sustain.targetCharacter.animation.curAnim.frames.length - 2 : sustain.targetCharacter.stillCharacterFrame - 1);
				}

				sustain.targetCharacter.holdTimer = 0.0;
			}
		}

		sustain.state = HELD;

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onHoldPost", sustain);
		#end
	}

	function loadChart():Void
	{
		if (State.crashHandler)
		{
			try
			{
				if (FileSystem.exists('assets/data/$curSong/chart/$curDifficulty.json') &&
					!FileSystem.exists('assets/data/$curSong/chart/$curDifficulty.bin'))
					ChartBytesData.saveChartFromJson(curSong, curDifficulty);

				chartBytesData = new ChartBytesData(curSong, curDifficulty);

				loadChart();
			}
			catch (e)
			{
				trace('Chart file "assets/data/$curSong/chart/$curDifficulty.bin" is either corrupted or nonexistent.');
				trace(e);
			}
		}
		else
		{
			if (FileSystem.exists('assets/data/$curSong/chart/$curDifficulty.json') &&
				!FileSystem.exists('assets/data/$curSong/chart/$curDifficulty.bin'))
				ChartBytesData.saveChartFromJson(curSong, curDifficulty);

			chartBytesData = new ChartBytesData(curSong, curDifficulty);
		}
	}

	public var paused:Bool = false;
}
