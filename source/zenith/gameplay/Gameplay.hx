package zenith.gameplay;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxSort;

import lime.app.Application;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import zenith.objects.ui.Note; // Don't remove this.

using StringTools;

@:access(flixel.FlxG.elapsed) // And don't delete this
class Gameplay extends MusicBeatState
{
	public var strums:FlxTypedGroup<StrumNote>;
	public var notes:FlxTypedGroup<Note>;

	// Health stuff
	private var hudGroup(default, null):HUDGroup;
	public var health:Float = 1.0;

	// Score text stuff
	public var score:Float = 0.0;
	public var misses:Float = 0.0;

	public var accuracy_left:Float = 0.0;
	public var accuracy_right:Float = 0.0;

	// Preference stuff
	public static var cpuControlled:Bool = false;
	public static var downScroll:Bool = true;
	public static var hideHUD:Bool = false;
	public static var renderMode:Bool = false;
	public static var noCharacters:Bool = false;

	private var framesCaptured(default, null):Int = 0;

	// Song stuff
	public static var SONG:Song.SwagSong;

	// Gameplay stuff

	// For events
	public var curSong:String = 'test';
	public var curStage:String = 'stage';

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var bfGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	// This is used to precache characters before loading in the song, like the change character event.
	public var bfMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var boyfriendCameraOffset:Array<Float> = [0.0, 0.0];
	public var opponentCameraOffset:Array<Float> = [0.0, 0.0];
	public var girlfriendCameraOffset:Array<Float> = [0.0, 0.0];

	public var songSpeedTween(default, null):FlxTween;
	public var songLengthTween(default, null):FlxTween;

	public var songSpeed:Float = 1.0;
	public var songLength:Float = 0.0;
	public var noteMult:Float = 1.0;
	public var cameraSpeed:Float = 1.0;

	public var generatedMusic:Bool = false;
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

	private var keybinds(default, null):Array<flixel.input.keyboard.FlxKey> = [A, S, UP, RIGHT];

	private var singAnimations(default, null):Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static var instance:Gameplay;

	public var events:Emitter = new Emitter();

	override function create():Void
	{
		initRender();

		Paths.initNoteShit(); // Do NOT remove this or the game will crash

		instance = this;

		// Preferences stuff

		downScroll = SaveData.contents.preferences.downScroll;
		hideHUD = SaveData.contents.preferences.hideHUD;
		noCharacters = SaveData.contents.preferences.noCharacters;

		// Reset gameplay stuff
		FlxG.fixedTimestep = startedCountdown = songEnded = false;
		songSpeed = noteMult = 1.0;

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

		var songName:String = (inline Sys.args())[0];

		if (null == (inline Sys.args())[0]) // What?
			songName = 'test';

		var songDifficulty:String = '-' + (inline Sys.args())[1];

		if (null == (inline Sys.args())[1]) // What?
			songDifficulty = '';

		var timeStamp:Float = inline haxe.Timer.stamp();

		// You don't need to thread when loading into the song anyway
		try
		{
			generateSong(songName, songDifficulty);

			strums = new FlxTypedGroup<StrumNote>();
			add(strums);

			for (i in 0...strumlines)
				generateStrumline(i);

			notes = new FlxTypedGroup<Note>();
			add(notes);

			if (!hideHUD)
			{
				hudGroup = new HUDGroup();
				add(hudGroup);

				@:privateAccess hudGroup.reloadHealthBar();
				hudGroup.cameras = [hudCamera];
			}

			strums.cameras = notes.cameras = [hudCamera];

			trace('Loading finished! Took ${inline flixel.util.FlxStringUtil.formatTime((inline haxe.Timer.stamp() - timeStamp) * 1000.0, true, true)} to load.');

			if (!noCharacters)
			{
				camFollowPos.setPosition(
					gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0],
					gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1]
				);

				moveCameraSection(dad);
			}

			generatedMusic = true;
			startCountdown();
		}
		catch (e)
		{
			if (renderMode)
				FlxG.autoPause = true;

			#if debug
			trace(e);
			#end

			FlxG.switchState(new WelcomeState());
		}

		super.create();

		events.on(SignalEvent.NOTE_HIT, onNoteHit);
		events.on(SignalEvent.NOTE_MISS, onNoteMiss);
		events.on(SignalEvent.GAMEPLAY_UPDATE, updateGameplay);

		Game.onKeyDown.on(SignalEvent.KEY_DOWN, onKeyDown);
		Game.onKeyUp.on(SignalEvent.KEY_UP, onKeyUp);
	}

	override function update(elapsed:Float):Void
	{
		if (!generatedMusic)
			return;

		if (renderMode)
			FlxG.elapsed = 1.0 / videoFramerate;

		super.update(elapsed);

		events.emit(SignalEvent.GAMEPLAY_UPDATE, elapsed);
	}

	var initialStrumHeight:Float; // Because for some reason, on downscroll, the sustain note changes y offset when its strum plays the confirm anim LOL
	var currentNoteId:UInt = 0;
	inline public function updateGameplay(elapsed:Float):Void
	{
		// Don't remove this.
		hudCameraBelow.x = hudCamera.x;
		hudCameraBelow.y = hudCamera.y;
		hudCameraBelow.angle = hudCamera.angle;
		hudCameraBelow.alpha = hudCamera.alpha;
		hudCameraBelow.zoom = hudCamera.zoom;

		health = inline FlxMath.bound(health, 0.0, (Gameplay.hideHUD || Gameplay.noCharacters) ? 2.0 : hudGroup.healthBar.maxValue);

		Conductor.songPosition += elapsed * 1000.0;

		while (null != SONG.noteData[currentNoteId])
		{
			// Avoid redundant array access
			var note:Array<UInt> = SONG.noteData[currentNoteId];
			var time:Float = note[0];

			if (Conductor.songPosition < time - (1950.0 / songSpeed))
				break;

			if (time >= 0 /* Don't spawn notes with negative strum time */)
				notes.recycle(Note).setupNoteData(note);

			currentNoteId++;
		}

		for (i in 0...notes.members.length)
		{
			var note:Note = notes.members[i];
			if (note.exists)
			{
				var strum:StrumNote = strums.members[note.noteData + (4 * note.lane)];

				// Sustain scaling for song speed (even if it's changed)
				// Psych engine sustain note calculation moment
				note.distance = 0.45 * (Conductor.songPosition - note.strumTime) * (songSpeed * note.multSpeed);
				note.x = strum.x + note.offsetX;
				note.y = (strum.y + note.offsetY) + (-strum.scrollMult * note.distance);

				if (Conductor.songPosition >= note.strumTime + (750 / songSpeed)) // Remove them if they're offscreen
					note.exists = false;

				// For note hits and hold input

				if (strum.playerStrum)
				{
					if (cpuControlled)
						if (Conductor.songPosition >= note.strumTime)
							events.emit(SignalEvent.NOTE_HIT, note);

					if (Conductor.songPosition >= note.strumTime + (Conductor.stepCrochet * 2.0) && (!note.wasHit && !note.tooLate))
						events.emit(SignalEvent.NOTE_MISS, note);
				}
				else
					if (Conductor.songPosition >= note.strumTime)
						events.emit(SignalEvent.NOTE_HIT, note);
			}
		}

		if (renderMode)
		{
			inline notes.members.sort((b:Note, a:Note) -> inline Std.int(a.y - b.y)); // Psych engine display note sorting moment
			pipeFrame();

			if (Conductor.songPosition - (20.0 + SONG.info.offset) >= inline Std.int(songLength) && !songEnded)
				endSong();
		}
	}

	// Song events for hscript
	public function triggerEvent(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Hey!':
				if (!noCharacters)
				{
					var value:Int = 2;
					switch (inline (inline value1.toLowerCase()).trim())
					{
						case 'bf' | 'boyfriend' | '0':
							value = 0;
						case 'gf' | 'girlfriend' | '1':
							value = 1;
					}

					var time:Float = inline Std.parseFloat(value2);
					if (Math.isNaN(time) || time <= 0)
						time = 0.6;

					if (value == 1)
					{
						if (null != gf)
						{
							inline gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
						if (null != dad && dad.curCharacter == gf.curCharacter)
						{
							inline dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
					}
					else
					{
						if (null != bf) {
							inline bf.playAnim('hey', true);
							bf.specialAnim = true;
							bf.heyTimer = time;
						}
					}
				}

			case 'Set GF Speed':
				var value:Int = inline Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1)
					value = 1;

				gfSpeed = value;

			case 'Add Camera Zoom':
				if (FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = inline Std.parseFloat(value1);
					var hudZoom:Float = inline Std.parseFloat(value2);

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
					var char:Character = dad;
					switch ((inline value2.toLowerCase()).trim())
					{
						case 'bf' | 'boyfriend':
							char = bf;
						case 'gf' | 'girlfriend':
							char = gf;
						default:
							var val2:Int = inline Std.parseInt(value2);
							if (Math.isNaN(val2))
								val2 = 0;

							switch (val2)
							{
								case 1: char = bf;
								case 2: char = gf;
							}
					}

					if (null != char)
					{
						inline char.playAnim(value1, true);
						char.specialAnim = true;
					}
				}

			case 'Change Character':
				if (noCharacters)
				{
					var charType:Int = 0;
					switch ((inline value1.toLowerCase()).trim())
					{
						case 'gf' | 'girlfriend':
							charType = 2;
						case 'dad' | 'opponent':
							charType = 1;
						default:
							charType = inline Std.parseInt(value1);
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

								var lastAlpha:Float = bf.alpha;
								bf.alpha = 0.001;
								bf = bfMap.get(value2);
								bf.alpha = lastAlpha;
								hudGroup.plrIcon.changeIcon(bf.healthIcon);
							}

						case 1:
							if(dad.curCharacter != value2)
							{
								if(!dadMap.exists(value2))
									addCharacterToList(value2, charType);

								var wasGf:Bool = dad.curCharacter.startsWith('gf');
								var lastAlpha:Float = dad.alpha;
								dad.alpha = 0.001;
								dad = dadMap.get(value2);

								if(null != gf)
									gf.visible = !dad.curCharacter.startsWith('gf') && wasGf;

								dad.alpha = lastAlpha;
								hudGroup.oppIcon.changeIcon(dad.healthIcon);
							}

						case 2:
							if(null != gf)
							{
								if(gf.curCharacter != value2)
								{
									if(!gfMap.exists(value2))
										addCharacterToList(value2, charType);

									var lastAlpha:Float = gf.alpha;
									gf.alpha = 0.001;
									gf = gfMap.get(value2);
									gf.alpha = lastAlpha;
								}
							}
					}
				}
				@:privateAccess hudGroup.reloadHealthBar();

			case 'Change Scroll Speed':
				if (null != songSpeedTween)
					songSpeedTween.cancel();

				var val1:Float = inline Std.parseFloat(value1);
				var val2:Float = inline Std.parseFloat(value2);

				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var newValue:Float = SONG.info.speed * val1;

				if (val2 <= 0)
					songSpeed = newValue;
				else
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.quintOut});

			case 'Fake Song Length':
				if (null != songLengthTween)
					songLengthTween.cancel();

				var v1 = inline Std.parseFloat(value1);

				if (!Math.isNaN(v1))
				{
					if (value2 == 'true')
						songLengthTween = FlxTween.tween(this, {songLength: v1 * 1000}, 1, {ease: FlxEase.quintOut});
					else
						songLength = v1 * 1000;
				}
		}
	}

	private function generateSong(name:String, diff:String):Void
	{
		trace('Parsing chart data from song json...');

		SONG = inline Song.loadFromJson(name + '/' + name + diff);

		trace('Loaded ${SONG.noteData.length} notes! Now time to load more stuff here...');

		trace('Loading stage...');

		if (null == SONG.info.offset || SONG.info.offset < 0) // Fix offset
			SONG.info.offset = 0;

		if (null == SONG.info.strumlines) // Fix strumlines
			SONG.info.strumlines = 2;

		curSong = SONG.song;
		songSpeed = SONG.info.speed;

		curStage = SONG.info.stage;

		// Setup stage

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

		defaultCamZoom = FlxG.camera.zoom = stageData.defaultZoom;

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (null != stageData.camera_speed)
			cameraSpeed = stageData.camera_speed;

		if (null != stageData.camera_boyfriend)
			boyfriendCameraOffset = stageData.camera_boyfriend;

		if (null != stageData.camera_opponent)
			opponentCameraOffset = stageData.camera_opponent;

		if (null != stageData.camera_girlfriend)
			girlfriendCameraOffset = stageData.camera_girlfriend;

		if (!noCharacters)
		{
			DisplayStage.loadStage(curStage);

			trace('Loading characters...');

			bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

			add(gfGroup);
			add(dadGroup);
			add(bfGroup);

			// Setup characters and camera stuff

			if (null == SONG.info.spectator || SONG.info.spectator == '') // Fix spectator
				SONG.info.spectator = 'gf';

			gf = new Character(0, 0, SONG.info.spectator);
			dad = new Character(0, 0, SONG.info.player2);
			bf = new Character(0, 0, SONG.info.player1, true);

			inline startCharacterPos(gf, false);
			inline startCharacterPos(dad, true);
			inline startCharacterPos(bf, false);

			gfGroup.add(gf);
			dadGroup.add(dad);
			bfGroup.add(bf);

			if (dad.curCharacter.startsWith('gf'))
			{
				dad.setPosition(GF_X, GF_Y);
				if (null != gf)
					gf.active = gf.visible = false;
			}
		}

		FlxG.camera.zoom = defaultCamZoom;

		trace('Loading instrumental audio file...');

		inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
		if (!renderMode)
			inst.onComplete = endSong;
		FlxG.sound.list.add(inst);

		trace('Loading voices audio file...');

		voices = new FlxSound();
		if (SONG.info.needsVoices)
			voices.loadEmbedded(Paths.voices(SONG.song));
		FlxG.sound.list.add(voices);

		inst.looped = voices.looped = false;
		inst.volume = voices.volume = renderMode ? 0.0 : 1.0;

		Conductor.mapBPMChanges(SONG); ////Since the chart format is being reworked, comment this out for now.

		// What happens if you load a song with a bpm of under 10? Change to 10 instead.
		SONG.info.bpm = Math.max(SONG.info.bpm, 10.0);

		Conductor.changeBPM(SONG.info.bpm);
	}

	public static var strumlines:Int = 2;
	inline public function generateStrumline(player:Int = 0):Void
	{
		for (i in 0...4)
		{
			var strum:StrumNote = new StrumNote(i, player);
			strum.scrollMult = downScroll ? -1.0 : 1.0;
			strum.x = 60.0 + (112.0 * strum.noteData) + ((FlxG.width * 0.5587511111112) * strum.player);
			strum.y = downScroll ? FlxG.height - 160.0 : 60.0;
			strum.playerStrum = player == strumlines - 1;
			initialStrumHeight = strum.height;
			strums.add(strum);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit():Void
	{
		super.stepHit();

		if (!startedCountdown)
			return;

		if (!renderMode)
		{
			var off:Float = Conductor.songPosition + SONG.info.offset;
			if ((inst.time < off - 20.0 || inst.time > off + 20.0)
				|| (voices.time < off - 20.0 || voices.time > off + 20.0))
			{
				Conductor.songPosition = inst.time - SONG.info.offset;
				voices.time = Conductor.songPosition + SONG.info.offset;
			}
		}

		if(curStep == lastStepHit)
			return;

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit():Void
	{
		super.beatHit();

		if(lastBeatHit >= curBeat)
			return;

		dance(curBeat);

		lastBeatHit = curBeat;

		if (!renderMode)
			notes.members.sort((a:Note, b:Note) -> Std.int(a.strumTime - b.strumTime));
	}

	public function dance(beat:Int):Void
	{
		if (!noCharacters)
		{
			if (null != gf
				&& beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
				&& null != gf.animation.curAnim
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& !gf.stunned)
				gf.dance();

			if (null != dad
				&& beat % dad.danceEveryNumBeats == 0
				&& null != dad.animation.curAnim
				&& !dad.animation.curAnim.name.startsWith('sing')
				&& !dad.stunned)
				dad.dance();

			if (null != bf
				&& beat % bf.danceEveryNumBeats == 0
				&& null != bf.animation.curAnim
				&& !bf.animation.curAnim.name.startsWith('sing')
				&& !bf.stunned)
				bf.dance();
		}
	}

	// For hscript
	public function addCameraZoom(value1:Float = 0.015, value2:Float = 0.03):Void
	{
		if (null != gameCameraZoomTween)
			gameCameraZoomTween.cancel();
		if (null != hudCameraZoomTween)
			hudCameraZoomTween.cancel();

		FlxG.camera.zoom += value1;
		gameCameraZoomTween = inline zoomTweenFunction(FlxG.camera, defaultCamZoom);
		hudCamera.zoom += value2;
		hudCameraZoomTween = inline zoomTweenFunction(hudCamera, 1);
	}

	private function startCountdown():Void
	{
		if (songEnded)
			return;

		inputKeybinds = SaveData.contents.controls.GAMEPLAY_BINDS;

		var swagCounter:Int = 0;
		Conductor.songPosition = (-Conductor.crochet * 5.0) - SONG.info.offset;

		new flixel.util.FlxTimer().start(Conductor.crochet * 0.001, (?timer) ->
		{
			switch (swagCounter)
			{
				case 3:
					FlxG.sound.play(Paths.sound('introGo'), 0.6);

				case 4:
					startSong();

				default:
					FlxG.sound.play(Paths.sound('intro' + (3 - swagCounter)), 0.6);
			}

			if (swagCounter != 4)
				dance(swagCounter - 1);

			swagCounter++;
		}, 5);
	}

	private function startSong():Void
	{
		if (songEnded)
			return;

		inst.play();
		voices.play();

		songLength = inst.length;
		startedCountdown = true;

		dance(curBeat);
	}

	public function endSong():Void
	{
		if (null != hudGroup.timeTxt)
			hudGroup.timeTxt.visible = false;

		songEnded = true;
		switchState(new WelcomeState());
	}

	// Camera functions

	private function moveCameraSection(whatCharacter:Character):Void
	{
		if (null != camFollowPosTween)
			camFollowPosTween.cancel();

		if (noCharacters)
			return;

		if (null != whatCharacter && whatCharacter == gf)
		{
			camFollowPosTween = FlxTween.tween(camFollowPos, {
				x: whatCharacter.getMidpoint().x + whatCharacter.cameraPosition[0] + girlfriendCameraOffset[0],
				y: whatCharacter.getMidpoint().y + whatCharacter.cameraPosition[1] + girlfriendCameraOffset[1]
			}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut});
		}

		camFollowPosTween = whatCharacter == bf ? FlxTween.tween(camFollowPos, {
			x: (whatCharacter.getMidpoint().x - 100.0) - whatCharacter.cameraPosition[0] - boyfriendCameraOffset[0],
			y: (whatCharacter.getMidpoint().y - 100.0) + whatCharacter.cameraPosition[1] + boyfriendCameraOffset[1]
		}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut}) : FlxTween.tween(camFollowPos, {
			x: (whatCharacter.getMidpoint().x + 150.0) + whatCharacter.cameraPosition[0] + opponentCameraOffset[0],
			y: (whatCharacter.getMidpoint().y - 100.0) + whatCharacter.cameraPosition[1] + opponentCameraOffset[1]
		}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut});
	}

	inline private function zoomTweenFunction(cam:FlxCamera, amount:Float = 1):FlxTween
	{
		return FlxTween.tween(cam, {zoom: amount}, 1.3, {ease: FlxEase.expoOut});
	}

	inline function set_defaultCamZoom(value:Float):Float
	{
		if (null != gameCameraZoomTween)
			gameCameraZoomTween.cancel();

		gameCameraZoomTween = inline zoomTweenFunction(FlxG.camera, value);
		return defaultCamZoom = value;
	}

	inline function startCharacterPos(char:Character, gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!bfMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					bfMap.set(newCharacter, newBoyfriend);
					bfGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.001;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.001;
				}

			case 2:
				if(null != gf && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.001;
				}
		}
	}

	// Real input system!!

	public var inputKeybinds:Array<KeyCode> = [];

	private var holdArray(default, null):Array<Bool> = [false, false, false, false];
	inline public function onKeyDown(keyCode:KeyCode, keyMod:KeyModifier):Void
	{
		var key:Int = inline inputKeybinds.indexOf(keyCode);

		if (key != -1 && !cpuControlled && generatedMusic && !holdArray[key])
		{
			var strum:StrumNote = strums.members[key + (4 * Std.int(Math.max(SONG.info.strumlines - 1, 1)))];

			// For some reason the strum note still plays the press animation even when a note is hit sometimes, so here's a solution to it.
			if (strum.animation.curAnim.name != 'confirm')
				strum.playAnim('pressed');

			var hittable:Note = fastNoteFilter(notes.members, n -> strum.playerStrum && (Math.abs(Conductor.songPosition - n.strumTime)) < 166.7 && !n.wasHit && !n.tooLate && n.noteData == key)[0];

			if (null != hittable)
				events.emit(SignalEvent.NOTE_HIT, hittable);

			holdArray[key] = true;
		}
	}

	inline private function fastNoteFilter(array:Array<Note>, f:(Note)->Bool):Array<Note>
		return [for (i in 0...array.length) { var a:Note = array[i]; if (f(a)) a; }];

	inline public function onKeyUp(keyCode:KeyCode, keyMod:KeyModifier):Void
	{
		var key:Int = inline inputKeybinds.indexOf(keyCode);

		if (key != -1 && !cpuControlled && generatedMusic && holdArray[key])
		{
			holdArray[key] = false;

			var strum:StrumNote = strums.members[key + (4 * Std.int(Math.max(SONG.info.strumlines - 1, 1)))];

			if (strum.animation.curAnim.name == 'confirm' ||
				strum.animation.curAnim.name == 'pressed')
				strum.playAnim('static');
		}
	}

	// Preferences stuff (Also for scripting)

	var strumYTweens(default, null):Array<FlxTween> = [];
	var strumScrollMultTweens(default, null):Array<FlxTween> = [];
	public function changeDownScroll(whichStrum:Int = -1, tween:Bool = false, tweenLength:Float = 1.0):Void
	{
		// Strumline
		for (i in 0...strums.members.length)
		{
			var strum:StrumNote = strums.members[i];

			if (strum.player == whichStrum || whichStrum == -1)
			{
				if (tween && tweenLength != 0.0)
				{
					var actualScrollMult:Float = strum.scrollMult;
					actualScrollMult = -actualScrollMult;

					if (null != strumScrollMultTweens[strums.members.indexOf(strum)])
						strumScrollMultTweens[strums.members.indexOf(strum)].cancel();

					strumScrollMultTweens[strums.members.indexOf(strum)] = FlxTween.tween(strum, {scrollMult: strum.scrollMult > 0.0 ? -1.0 : 1.0}, Math.abs(tweenLength), {ease: FlxEase.quintOut});

					if (null != strumYTweens[strums.members.indexOf(strum)])
						strumYTweens[strums.members.indexOf(strum)].cancel();

					strumYTweens[strums.members.indexOf(strum)] = FlxTween.tween(strum, {y: actualScrollMult < 0.0 ? FlxG.height - 160.0 : 60.0}, Math.abs(tweenLength), {ease: FlxEase.quintOut});
				}
				else
				{
					strum.scrollMult = -strum.scrollMult;
					strum.y = strum.scrollMult < 0.0 ? FlxG.height - 160.0 : 60.0;
				}
			}
		}
	}

	override function destroy():Void
	{
		stopRender();

		events.off(SignalEvent.NOTE_HIT, onNoteHit);
		events.off(SignalEvent.NOTE_MISS, onNoteMiss);
		events.off(SignalEvent.GAMEPLAY_UPDATE, updateGameplay);

		Game.onKeyDown.off(SignalEvent.KEY_DOWN, onKeyDown);
		Game.onKeyUp.off(SignalEvent.KEY_UP, onKeyUp);

		super.destroy();
	}

	inline public function onNoteHit(note:Note):Void
	{
		var strum:StrumNote = strums.members[note.noteData + (4 * note.lane)]; // Avoid doing array access twice
		strum.playAnim('confirm');

		var multiplier:Float = Math.max(note.multiplier, 1.0); // Avoid calling math.max 4 times

		health += (0.045 * multiplier) * (strum.playerStrum ? 1.0 : -1.0);

		if (strum.playerStrum)
		{
			score += 350.0 * multiplier;
			accuracy_left += (Math.abs(note.strumTime - Conductor.songPosition) > 83.35 ? 0.75 : 1.0) * multiplier;
			accuracy_right += multiplier;
		}

		if (!noCharacters)
		{
			var char:Character = (strum.playerStrum ? bf : (note.gfNote ? gf : dad));

			if (null != char)
			{
				inline char.playAnim(@:privateAccess singAnimations[note.noteData], true);
				char.holdTimer = 0.0;
			}
		}

		note.wasHit = true;
		note.exists = false;
	}

	inline public function onNoteMiss(note:Note):Void
	{
		note.tooLate = true;

		var multiplier:Float = Math.max(note.multiplier, 1.0); // Avoid calling math.max 4 times

		health -= 0.045 * multiplier;
		score -= 100.0 * multiplier;
		misses += multiplier;
		accuracy_right += multiplier;

		if (!noCharacters)
		{
			inline bf.playAnim(@:privateAccess singAnimations[note.noteData] + 'miss', true);
			bf.holdTimer = 0.0;
		}
	}

	// Render mode shit

	private var process:sys.io.Process;

	public var videoFramerate:Int = 60;
	public var videoEncoder:String = "libx265";
	public var outputPath:String = "output.mp4";

	inline private function initRender():Void
	{
		if (renderMode)
		{
			cpuControlled = true;
			process = new sys.io.Process('ffmpeg', ['-v', 'quiet', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '1280x720', '-r', '$videoFramerate', '-i', '-', '-c:v', videoEncoder, (inline (inline Sys.getCwd()).replace('\\', '/')) + outputPath]);
			FlxG.autoPause = false;
		}
	}

	inline private function pipeFrame():Void
	{
		var img:lime.graphics.Image = lime.app.Application.current.window.readPixels(new lime.math.Rectangle(FlxG.scaleMode.offset.x, FlxG.scaleMode.offset.y, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));
		var bytes:haxe.io.Bytes = img.getPixels(new lime.math.Rectangle(0, 0, img.width, img.height));
		process.stdin.writeBytes(bytes, 0, bytes.length);
	}

	inline private function stopRender():Void
	{
		if (renderMode)
		{
			process.stdin.close();
			process.close();
			process.kill();

			FlxG.autoPause = true;
		}
	}
}
