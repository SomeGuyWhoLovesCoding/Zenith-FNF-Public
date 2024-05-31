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

using StringTools;

@:access(zenith.objects.HUDGroup)

class Gameplay extends State
{
	public var strumlines:FlxTypedGroup<Strumline>;
	public var notes:FlxTypedGroup<Note>;
	public var sustains:FlxTypedGroup<SustainNote>;

	private var hudGroup(default, null):HUDGroup;
	public var health:Float = 1.0;

	public var score(default, set):Float = 0.0;

	inline function set_score(value:Float):Float
	{
		return score = Math.ffloor(value);
	}

	public var misses(default, set):Float = 0.0;

	inline function set_misses(value:Float):Float
	{
		return misses = Math.ffloor(value);
	}

	var accuracy_left(default, null):Float = 0.0;
	var accuracy_right(default, null):Float = 0.0;

	// Preference stuff
	static public var cpuControlled:Bool = false;
	static public var downScroll:Bool = true;
	static public var hideHUD:Bool = false;
	static public var noCharacters:Bool = false;
	static public var stillCharacters:Bool = false;

	// Song stuff
	static public var SONG:Song.SwagSong;

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

	static var singAnimations(default, null):Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	static public var instance:Gameplay;

	function h(key:(Int)):Void
	{
		for (i in 0...notes.members.length)
		{
			_n = notes.members[i];
			if ((_n.strum.playable && _n.noteData == key) &&
				(!_n.wasHit && !_n.tooLate) && Math.abs(Main.conductor.songPosition - _n.strumTime) < 166.7)
			{
				onNoteHit(_n);
				break;
			}
		}
	}

	function r(key:(Int)):Void
	{
		for (i in 0...sustains.members.length)
		{
			_s = sustains.members[i];
			if ((_s.strum.playable && !_s.missed && _s.noteData == key) && Main.conductor.songPosition >= _s.strumTime &&
				Main.conductor.songPosition <= (_s.strumTime + _s.length) - (Main.conductor.stepCrochet * 0.875))
			{
				onRelease(_s.noteData);
				_s.holding = false;
				_s.missed = true;
				_s.alpha = 0.3;
			}
		}
	}

	function ss():Void
	{
		notes.members.sort((a:(Note), b:(Note)) -> Std.int(a.strumTime - b.strumTime));
		sustains.members.sort((a:(SustainNote), b:(SustainNote)) -> Std.int(a.strumTime - b.strumTime));
	}

	function p():Void
	{
		while (nd != null && nd[0] <= Main.conductor.songPosition + (1915.0 / songSpeed))
		{
			setupNoteData(nd);
			nd = SONG.noteData[currentNoteId++];
		}
	}

	function n():Void
	{
		for (i in 0...notes.members.length)
		{
			currentNote = notes.members[i];

			if (currentNote.exists)
			{
				currentNote.scale.set(currentNote.strum.scale.x, currentNote.strum.scale.y);
				currentNote.offset.x = -0.5 * ((currentNote.frameWidth * 0.7) - currentNote.frameWidth);
				currentNote.offset.y = -0.5 * ((currentNote.frameHeight * 0.7) - currentNote.frameHeight);
				currentNote.origin.x = currentNote.frameWidth * 0.5;
				currentNote.origin.y = currentNote.frameHeight * 0.5;

				currentNote.distance = 0.45 * (Main.conductor.songPosition - currentNote.strumTime) * songSpeed;
				currentNote.x = currentNote.strum.x + currentNote.offsetX + (-Math.abs(currentNote.strum.scrollMult) * currentNote.distance) *
					FlxMath.fastCos(FlxAngle.asRadians(currentNote.direction - 90.0));
				currentNote.y = currentNote.strum.y + currentNote.offsetY + (currentNote.strum.scrollMult * currentNote.distance) *
					FlxMath.fastSin(FlxAngle.asRadians(currentNote.direction - 90.0));

				if (Main.conductor.songPosition >= currentNote.strumTime + (750.0 / songSpeed)) // Remove them if they're offscreen
				{
					currentNote.exists = false;
					continue;
				}

				// For note hits

				if (currentNote.strum.playable)
				{
					if (cpuControlled && Main.conductor.songPosition >= currentNote.strumTime)
					{
						onNoteHit(currentNote);
					}

					if (Main.conductor.songPosition >= currentNote.strumTime + (200.0 / songSpeed) && (!currentNote.wasHit && !currentNote.tooLate))
					{
						onNoteMiss(currentNote);
					}
				}
				else
				{
					if (Main.conductor.songPosition >= currentNote.strumTime)
					{
						onNoteHit(currentNote);
					}
				}
			}
		}
	}

	function s():Void
	{
		for (i in 0...sustains.members.length)
		{
			currentSustain = sustains.members[i];

			if (currentSustain.exists)
			{
				currentSustain.scale.set(currentSustain.strum.scale.x, currentSustain.strum.scale.y);
				currentSustain.offset.x = -0.5 * ((currentSustain.frameWidth * currentSustain.scale.x) - currentSustain.frameWidth);
				currentSustain.origin.x = currentSustain.frameWidth * 0.5;
				currentSustain.origin.y = currentSustain.offset.y = 0.0;

				currentSustain.distance = 0.45 * (Main.conductor.songPosition - currentSustain.strumTime) * songSpeed;

				currentSustain.x = (currentSustain.strum.x + currentSustain.offsetX + (-Math.abs(currentSustain.strum.scrollMult) * currentSustain.distance) *
					FlxMath.fastCos(FlxAngle.asRadians(currentSustain.direction - 90.0))) + ((initialStrumWidth - (currentSustain.frameWidth * currentSustain.scale.x)) * 0.5);

				currentSustain.y = (currentSustain.strum.y + currentSustain.offsetY + (currentSustain.strum.scrollMult * currentSustain.distance) *
					FlxMath.fastSin(FlxAngle.asRadians(currentSustain.direction - 90.0))) + (initialStrumHeight * 0.5);

				// For hold input

				if (Main.conductor.songPosition >= (currentSustain.strumTime + currentSustain.length) + (750.0 / songSpeed))
				{
					currentSustain.holding = currentSustain.missed = currentSustain.exists = false;
					continue;
				}

				if (currentSustain.strum.playable)
				{
					if (holdArray[currentSustain.noteData] && Main.conductor.songPosition >= currentSustain.strumTime && !currentSustain.missed &&
						Main.conductor.songPosition <= (currentSustain.strumTime + currentSustain.length) - (Main.conductor.stepCrochet * 0.875))
					{
						onHold(currentSustain);
					}
				}
				else
				{
					if (Main.conductor.songPosition <= (currentSustain.strumTime + currentSustain.length) - (Main.conductor.stepCrochet * 0.875) &&
						Main.conductor.songPosition >= currentSustain.strumTime)
					{
						onHold(currentSustain);
					}
				}
			}
		}
	}

	inline public function onKeyDown(keyCode:(Int), keyModifier:(Int)):Void
	{
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCall2Ints('onKeyDown', keyCode, keyModifier);
		#end

		st = inputKeybinds[keyCode];

		if (st != null && !cpuControlled && generatedMusic && !holdArray[st.noteData])
		{
			if (st.animation.curAnim.name != 'confirm')
				st.playAnim('pressed');

			h(st.noteData);

			holdArray[st.noteData] = true;

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Ints('onKeyDownPost', keyCode, keyModifier);
			#end
		}
	}

	inline public function onKeyUp(keyCode:(Int), keyModifier:(Int)):Void
	{
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCall2Ints('onKeyUp', keyCode, keyModifier);
		#end

		st = inputKeybinds[keyCode];

		if (st != null && !cpuControlled && generatedMusic && holdArray[st.noteData])
		{
			if (st.animation.curAnim.name == 'confirm' ||
				st.animation.curAnim.name == 'pressed')
				st.playAnim('static');

			r(st.noteData);

			holdArray[st.noteData] = false;

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Ints('onKeyUpPost', keyCode, keyModifier);
			#end
		}
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

		var songDifficulty:String = '-' + Sys.args()[1];

		if (null == Sys.args()[1]) // What?
		{
			songDifficulty = '';
		}
		#else
		var songName:String = 'test';
		var songDifficulty:String = '';
		#end

		generateSong(songName, songDifficulty);

		super.create();

		Main.conductor.onBeatHit = (curBeat:(Float)) ->
		{
			ss();

			if (!songEnded && (startedCountdown || curBeat != 0) && Main.conductor.songPosition > 0)
			{
				if (curBeat % 32 == 31)
				{
					Main.conductor.executeBpmChange(200.0, 25600.0);
				}

				dance(curBeat - 1); // This is rather very fuckin weird but ok
			}
		}

		Main.conductor.onMeasureHit = (curMeasure:(Float)) ->
		{
			if (!songEnded && (startedCountdown || curMeasure != 0) && Main.conductor.songPosition > 0)
			{
				addCameraZoom();
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		if (generatedMusic)
		{
			health = FlxMath.bound(health, 0.0, hudGroup != null ? hudGroup.healthBar.maxValue : 2.0);

			hudCameraBelow.x = hudCamera.x;
			hudCameraBelow.y = hudCamera.y;
			hudCameraBelow.angle = hudCamera.angle;
			hudCameraBelow.alpha = hudCamera.alpha;
			hudCameraBelow.zoom = hudCamera.zoom;

			if (startedCountdown && !songEnded)
			{
				_songPos = inst.time - SONG.info.offset;
			}
			else
			{
				_songPos += elapsed * 1000.0;
			}

			Main.conductor.songPosition = FlxMath.lerp(Main.conductor.songPosition, _songPos, 0.126565 * (lime.app.Application.current.window.displayMode.refreshRate / FlxG.updateFramerate));

			p();
			n();
			s();

			if (_songPos >= 0 && !startedCountdown)
			{
				startSong();
			}

			super.update(elapsed);

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

				if (null == SONG.info.spectator) // Fix gf (for vanilla charts)
					SONG.info.spectator = 'gf';

				if (null == SONG.info.offset || SONG.info.offset < 0) // Fix offset
					SONG.info.offset = 0;

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
							camera_speed: 1
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
					gf = new Character(0, 0, SONG.info.spectator);
					gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
					gfGroup.add(gf);

					lock.acquire();

					threadsCompleted++;
					lock.release();
				});

				Thread.create(() ->
				{
					dad = new Character(0, 0, SONG.info.player2);
					dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
					dadGroup.add(dad);

					lock.acquire();

					threadsCompleted++;
					lock.release();
				});

				Thread.create(() ->
				{
					bf = new Character(0, 0, SONG.info.player1, true);
					bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
					bfGroup.add(bf);

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

				#if SCRIPTING_ALLOWED
				Main.optUtils.scriptCall2Strings('createStage', curSong, curDifficulty);
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
				add(gfGroup);
				add(dadGroup);
				add(bfGroup);

				startCharacterPos(gf, false);
				startCharacterPos(dad, true);
				startCharacterPos(bf, false);

				#if SCRIPTING_ALLOWED
				Main.optUtils.scriptCall2Strings('createStagePost', curSong, curDifficulty);
				#end

				// Now time to load the UI and shit

				sustains = new FlxTypedGroup<SustainNote>();
				add(sustains);

				strumlines = new FlxTypedGroup<Strumline>();
				add(strumlines);

				for (i in 0...strumlineCount)
					generateStrumline(i);

				if (downScroll)
					changeDownScroll();

				notes = new FlxTypedGroup<Note>();
				add(notes);

				if (!hideHUD)
				{
					hudGroup = new HUDGroup();
					add(hudGroup);

					hudGroup.reloadHealthBar();
					hudGroup.cameras = [hudCamera];
				}

				sustains.cameras = strumlines.cameras = notes.cameras = [hudCamera];

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
				Main.optUtils.scriptCall2Strings('generateSong', curSong, curDifficulty);
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
	var currentNoteId:Int = 0;

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
								if (hudGroup != null)
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
								if (hudGroup != null)
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
		Main.optUtils.scriptCallEvent('triggerEvent', eventName, value1, value2, value3, value4);
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
			FlxG.autoPause = false;
			Thread.create(() ->
			{
				var preloadName:String = curSong + (curDifficulty != '' ? '-$curDifficulty' : '');
				try
				{
					// Chart preloader
					if (ChartPreloader.container.exists(preloadName))
					{
						SONG = ChartPreloader.container.get(preloadName);
					}
					else
						SONG = Song.loadFromJson(curSong + '/' + curSong + curDifficulty);

					nd = SONG.noteData[currentNoteId];
					threadsCompleted++;
				}
				catch (e)
				{
					trace('Chart file "$preloadName" is either corrupted or nonexistent.');
				}
			});
		}
		else
		{
			FlxG.maxElapsed = FlxG.elapsed;

			var preloadName:String = curSong + (curDifficulty != '' ? '-$curDifficulty' : '');

			try
			{
				// Chart preloader
				if (ChartPreloader.container.exists(preloadName))
				{
					SONG = ChartPreloader.container.get(preloadName);
				}
				else
					SONG = Song.loadFromJson(curSong + '/' + curSong + curDifficulty);

				nd = SONG.noteData[currentNoteId];
			}
			catch (e)
			{
				trace('Chart file "$preloadName" is either corrupted or nonexistent.');
			}

			// What happens if you load a song with a bpm of under 10? Limit it.
			Main.conductor.bpm = SONG.info.bpm = Math.max(SONG.info.bpm, 10.0);
			Main.conductor.reset();

			if (null == SONG.info.spectator) // Fix gf (for vanilla charts)
				SONG.info.spectator = 'gf';

			if (null == SONG.info.offset || SONG.info.offset < 0) // Fix offset
				SONG.info.offset = 0;

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
					camera_speed: 1
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

			gf = new Character(0, 0, SONG.info.spectator);
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
			gfGroup.add(gf);

			dad = new Character(0, 0, SONG.info.player2);
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
			dadGroup.add(dad);

			bf = new Character(0, 0, SONG.info.player1, true);
			bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
			bfGroup.add(bf);

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

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Strings('createStage', curSong, curDifficulty);
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

			add(gfGroup);
			add(dadGroup);
			add(bfGroup);

			startCharacterPos(gf, false);
			startCharacterPos(dad, true);
			startCharacterPos(bf, false);

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Strings('createStagePost', curSong, curDifficulty);
			#end

			// Now time to load the UI and shit

			sustains = new FlxTypedGroup<SustainNote>();
			add(sustains);

			strumlines = new FlxTypedGroup<Strumline>();
			add(strumlines);

			for (i in 0...strumlineCount)
				generateStrumline(i);

			if (downScroll)
				changeDownScroll();

			notes = new FlxTypedGroup<Note>();
			add(notes);

			if (!hideHUD)
			{
				hudGroup = new HUDGroup();
				add(hudGroup);

				hudGroup.reloadHealthBar();
				hudGroup.cameras = [hudCamera];
			}

			sustains.cameras = strumlines.cameras = notes.cameras = [hudCamera];

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
			Main.optUtils.scriptCall2Strings('generateSong', curSong, curDifficulty);
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

			for (i in 0...SaveData.contents.controls.GAMEPLAY_BINDS.length)
			{
				inputKeybinds.set(SaveData.contents.controls.GAMEPLAY_BINDS[i], strumlines.members[1].members[i]);
			}

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
			}, 5);

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall('startCountdown');
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

			startedCountdown = true;

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall('startSong');
			#end

			addCameraZoom();
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
		Main.optUtils.scriptCall('endSong');
		#end
	}

	// Camera functions

	var _mp(default, null):FlxPoint;
	var _cpx(default, null):Float = 0.0;
	var _cpy(default, null):Float = 0.0;

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

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallCharacter('moveCamera', whatCharacter);
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

	public var inputKeybinds:Map<(Int), (StrumNote)> = new Map<(Int), (StrumNote)>();

	// The extra 5 values are used to check if a key is just pressed for extra keys aswell
	public var holdArray(default, null):Array<Bool> = [false, false, false, false, false, false, false, false, false];

	// Preferences stuff (Also for scripting)

	var strumYTweens(default, null):Map<StrumNote, FlxTween> = [];
	var strumScrollMultTweens(default, null):Map<StrumNote, FlxTween> = [];
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

						var scrollMultTween = strumScrollMultTweens.get(strum);
						var yTween = strumYTweens.get(strum);

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

	var currentNote(default, null):Note;
 	var spawnedNote(default, null):Note;
	var _n(default, null):Note;
	var currentSustain(default, null):SustainNote;
	var spawnedSustain(default, null):SustainNote;
	var _s(default, null):SustainNote;

	var nd(default, null):Array<Float>;

	var _d(default, null):Float;
	var _nk(default, null):Int = 0;

	var c(default, null):Character;

	var st(default, null):StrumNote;

	var _songPos(default, null):Float = -5000.0;

	function setupNoteData(chartNoteData:(Array<(Float)>)):Void
	{
		if (chartNoteData[0] >= 0.0 && chartNoteData[3] >= 0) // Don't spawn a note with negative time or lane
		{
			spawnedNote = notes.recycle((Note));
			spawnedNote.setFrame(Paths.regularNoteFrame);

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNoteSetup('setupNoteData', spawnedNote, chartNoteData);
			#end

			spawnedNote.alpha = 1.0;
			spawnedNote.y = -2000.0;
			spawnedNote.wasHit = spawnedNote.tooLate = false;

			spawnedNote.strumTime = chartNoteData[0];
			spawnedNote.noteData = Std.int(chartNoteData[1]);
			spawnedNote.sustainLength = Std.int(chartNoteData[2]) - 32;
			spawnedNote.lane = Std.int(chartNoteData[3]) % strumlineCount;
			spawnedNote.multiplier = Std.int(chartNoteData[4]);

			_nk = strumlines.members[spawnedNote.lane].keys;

			spawnedNote.strum = strumlines.members[spawnedNote.lane].members[spawnedNote.noteData % _nk];
			spawnedNote.scale.set(spawnedNote.strum.scale.x, spawnedNote.strum.scale.y);

			spawnedNote.offset.x = -0.5 * ((spawnedNote.frameWidth * spawnedNote.scale.x) - spawnedNote.frameWidth);
			spawnedNote.offset.y = -0.5 * ((spawnedNote.frameHeight * spawnedNote.scale.y) - spawnedNote.frameHeight);
			spawnedNote.origin.x = spawnedNote.frameWidth * 0.5;
			spawnedNote.origin.y = spawnedNote.frameHeight * 0.5;

			spawnedNote.color = NoteBase.colorArray[spawnedNote.noteData % _nk];
			spawnedNote.angle = NoteBase.angleArray[spawnedNote.noteData % _nk];

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNote('newNote', spawnedNote);
			#end

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNoteSetup('setupNoteDataPost', spawnedNote, chartNoteData);
			#end

			if (spawnedNote.sustainLength > 2.0) // Don't spawn too short sustain notes
			{
				setupSustainData(chartNoteData);
			}
		}
	}

	function setupSustainData(chartNoteData:(Array<(Float)>)):Void
	{
		spawnedSustain = sustains.recycle((SustainNote));

		spawnedSustain.setFrame(Paths.sustainNoteFrame);

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallSustainSetup('setupSustainData', spawnedSustain, chartNoteData);
		#end

		spawnedSustain.alpha = 0.6; // Definitive alpha, default
		spawnedSustain.y = -2000.0;
		spawnedSustain.holding = spawnedSustain.missed = false;

		spawnedSustain.strumTime = chartNoteData[0];
		spawnedSustain.noteData = Std.int(chartNoteData[1]);
		spawnedSustain.length = chartNoteData[2] - 32.0;
		spawnedSustain.lane = Std.int(chartNoteData[3]);

		_nk = strumlines.members[spawnedSustain.lane].keys;

		spawnedSustain.strum = strumlines.members[spawnedSustain.lane].members[spawnedSustain.noteData % _nk];
		spawnedSustain.scale.set(spawnedSustain.strum.scale.x, spawnedSustain.strum.scale.y);

		spawnedSustain.offset.x = -0.5 * ((spawnedSustain.frameWidth * spawnedSustain.scale.x) - spawnedSustain.frameWidth);
		spawnedSustain.origin.x = spawnedSustain.frameWidth * 0.5;
		spawnedSustain.origin.y = spawnedSustain.offset.y = 0.0;

		spawnedSustain.color = NoteBase.colorArray[spawnedSustain.noteData % _nk];

		spawnedSustain.downScroll = spawnedSustain.strum.scrollMult < 0.0;

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallSustain('newSustain', spawnedSustain);
		#end

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallSustainSetup('setupSustainDataPost', spawnedSustain, chartNoteData);
		#end
	}

	function onNoteHit(note:(Note)):Void
	{
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallNote('onNoteHit', note);
		#end

		note.strum.playAnim('confirm');

		health += (0.045 * FlxMath.maxInt(note.multiplier, 1)) * (note.strum.playable ? 1.0 : -1.0);

		if (note.strum.playable)
		{
			_d = note.strumTime - Main.conductor.songPosition;
			score += 350.0 * FlxMath.maxInt(note.multiplier, 1);
			accuracy_left += ((_d < 0.0 ? -_d : _d) > 83.35 ? 0.75 : 1.0) * FlxMath.maxInt(note.multiplier, 1);
			accuracy_right += FlxMath.maxInt(note.multiplier, 1);
		}

		if (!noCharacters)
		{
			c = note.strum.playable ? bf : note.gfNote ? gf : dad;

			if (null != c)
			{
				c.playAnim(singAnimations[note.noteData]);
				c.holdTimer = 0.0;
			}
		}

		note.wasHit = true;
		note.exists = false;

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallNote('onNoteHitPost', note);
		#end

		if (hudGroup != null)
			hudGroup.updateScoreText();
	}

	function onNoteMiss(note:(Note)):Void
	{
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallNote('onNoteMiss', note);
		#end

		note.tooLate = true;
		note.alpha = 0.6;

		health -= 0.045 * FlxMath.maxInt(note.multiplier, 1);
		score -= 100.0 * FlxMath.maxInt(note.multiplier, 1);
		misses += FlxMath.maxInt(note.multiplier, 1);
		accuracy_right += FlxMath.maxInt(note.multiplier, 1);

		if (!noCharacters)
		{
			bf.playAnim(singAnimations[note.noteData] + 'miss');
			bf.holdTimer = 0.0;
		}

		r(note.noteData);

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallNote('onNoteMissPost', note);
		#end

		if (hudGroup != null)
			hudGroup.updateScoreText();
	}

	function onHold(sustain:(SustainNote)):Void
	{
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallSustain('onHold', sustain);
		#end

		sustain.strum.playAnim('confirm');

		health += FlxG.elapsed * (sustain.strum.playable ? 0.125 : -0.125);

		if (!noCharacters)
		{
			c = (sustain.strum.playable ? bf : (sustain.gfNote ? gf : dad));

			if (null != c)
			{
				if (Gameplay.stillCharacters)
				{
					c.playAnim(singAnimations[sustain.noteData]);
				}
				else
				{
					// This shit is similar to amazing engine's character hold fix, but better

					if (c.animation.curAnim.name == singAnimations[sustain.noteData] + 'miss')
						c.playAnim(singAnimations[sustain.noteData]);

					if (c.animation.curAnim.curFrame > (c.stillCharacterFrame == -1 ? c.animation.curAnim.frames.length : c.stillCharacterFrame))
						c.animation.curAnim.curFrame = (c.stillCharacterFrame == -1 ? c.animation.curAnim.frames.length - 2 : c.stillCharacterFrame - 1);
				}

				c.holdTimer = 0.0;
			}
		}

		sustain.holding = true;

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallSustain('onHoldPost', sustain);
		#end
	}

	function onRelease(noteData:(Int)):Void
	{
		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallInt('onRelease', noteData);
		#end

		health -= 0.045;

		if (!noCharacters)
		{
			bf.playAnim(singAnimations[noteData] + 'miss');
			bf.holdTimer = 0.0;
		}

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCallInt('onReleasePost', noteData);
		#end
	}

	var finder:NoteFinder = new NoteFinder();

	public var paused:Bool = false;
}

private class NoteFinder
{
	public function new():Void {}

	var noteTracker:Int;
	var sustainTracker:Int;

	var note:Note;
	var sustain:Note;

	// I'm getting confused here
	public function findNote(position:Float):Note
	{
		note = Gameplay.instance.notes.members[noteTracker = Std.int(position / Main.conductor.stepCrochet)];

		if (!note.strum.playable)
		{
			while (!note.strum.playable)
			{
				note = Gameplay.instance.notes.members[noteTracker++];
			}
		}

		return note;
	}
}
