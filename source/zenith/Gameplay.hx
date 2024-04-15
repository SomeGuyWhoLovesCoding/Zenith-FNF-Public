package zenith;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;

using StringTools;

// Don't delete these
@:access(flixel.FlxG.elapsed)
@:access(flixel.FlxSprite)
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
	public var cameraSpeed:Float = 1.0;

	public var generatedMusic:Bool = false;
	public var startedCountdown:Bool = false;
	public var songEnded:Bool = false;

	public var gfSpeed:Int = 1;

	public var inst:Sound;
	public var voices:Sound;

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
		onGameplayCreate = () ->
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
				songDifficulty = '';
			#else
			var songName:String = 'test';
			var songDifficulty:String = '';
			#end

			#if sys var timeStamp:Float = Sys.cpuTime(); #end

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

				trace('Loading finished!' #if sys + ' Took ${Utils.formatTime((haxe.Timer.stamp() - timeStamp) * 1000.0, true, true)} to load.' #end);

				if (!noCharacters)
				{
					camFollowPos.setPosition(
						gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0],
						gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1]
					);

					moveCamera(dad);
				}

				generatedMusic = true;
				startCountdown();
			}
			catch (e:haxe.Exception)
			{
				if (renderMode)
					FlxG.autoPause = true;

				trace(e.stack);

				FlxG.switchState(new WelcomeState(e.message));
			}
		}

		events.on(SignalEvent.GAMEPLAY_CREATE, onGameplayCreate);
		events.emit(SignalEvent.GAMEPLAY_CREATE);
		events.off(SignalEvent.GAMEPLAY_CREATE, onGameplayCreate);

		super.create();

		newNote = (note:Note) ->
		{
			note.pixelPerfectPosition = note.active = false;

			note._frame = @:privateAccess Paths.noteFrame;

			note._flashRect.x = note._flashRect.y = 0;
			if (null != note._frame)
			{
				note._flashRect.width = note.frameWidth = Std.int(note._frame.sourceSize.x);
				note._flashRect.height = note.frameHeight = Std.int(note._frame.sourceSize.y);
			}
			note._halfSize.x = 0.5 * note.frameWidth;
			note._halfSize.y = 0.5 * note.frameHeight;

			note.scale.x = note.scale.y = 0.7;
			note.width = Math.abs(note.scale.x) * note.frameWidth;
			note.height = Math.abs(note.scale.y) * note.frameHeight;
			note.offset.x = -0.5 * (note.width - note.frameWidth);
			note.offset.y = -0.5 * (note.height - note.frameHeight);
			note.origin.x =	note.frameWidth * 0.5;
			note.origin.y = note.frameHeight * 0.5;
		}

		setupNoteData = (chartNoteData:Array<Float>) ->
		{
			var note:Note = notes.recycle(Note);

			note.y = -2000;
			note.wasHit = note.tooLate = false;

			note.strumTime = chartNoteData[0];
			note.noteData = Std.int(chartNoteData[1]);
			note.sustainLength = chartNoteData[2];
			note.lane = Std.int(chartNoteData[3]);
			note.multiplier = chartNoteData[4];

			note.strum = strums.members[note.noteData + (4 * note.lane)];

			note.color = NoteBase.colorArray[note.noteData];
			note.angle = NoteBase.angleArray[note.noteData];
		}

		onNoteHit = (note:Note) ->
		{
			note.strum.playAnim('confirm');

			var multiplier:Float = Math.floor(Math.max(note.multiplier, 1.0)); // Avoid calling math.max 4 times

			health += (0.045 * multiplier) * (note.strum.playerStrum ? 1.0 : -1.0);

			if (note.strum.playerStrum)
			{
				score += 350.0 * multiplier;
				accuracy_left += (Math.abs(note.strumTime - Conductor.songPosition) > 83.35 ? 0.75 : 1.0) * multiplier;
				accuracy_right += multiplier;
			}

			if (!noCharacters)
			{
				var char:Character = (note.strum.playerStrum ? bf : (note.gfNote ? gf : dad));

				if (null != char)
				{
					char.playAnim(@:privateAccess singAnimations[note.noteData]);
					char.holdTimer = 0.0;
				}
			}

			note.wasHit = true;
			note.exists = false;
		}

		onNoteMiss = (note:Note) ->
		{
			note.tooLate = true;

			var multiplier:Float = Math.floor(Math.max(note.multiplier, 1.0)); // Avoid calling math.max 4 times

			health -= 0.045 * multiplier;
			score -= 100.0 * multiplier;
			misses += multiplier;
			accuracy_right += multiplier;

			if (!noCharacters)
			{
				bf.playAnim(@:privateAccess singAnimations[note.noteData] + 'miss');
				bf.holdTimer = 0.0;
			}
		}

		onKeyDown = (keyCode:Int, keyModifier:Int) ->
		{
			var key:Int = inputKeybinds.indexOf(keyCode);

			if (-1 != key && !cpuControlled && generatedMusic && !holdArray[key])
			{
				var strum:StrumNote = strums.members[key + (4 * Std.int(Math.max(strumlines - 1, 1)))];

				// For some reason the strum note still plays the press animation even when a note is hit sometimes, so here's a solution to it.
				if (strum.animation.curAnim.name != 'confirm')
					strum.playAnim('pressed');

				var hittable:Note = fastNoteFilter(notes.members, n -> (!n.wasHit && !n.tooLate) && (null != n.strum /* Null check */ && n.strum.playerStrum && n.noteData == key) && Math.abs(Conductor.songPosition - n.strumTime) < 166.7)[0];

				if (null != hittable)
					events.emit(SignalEvent.NOTE_HIT, hittable);

				holdArray[key] = true;
			}
		}

		onKeyUp = (keyCode:Int, keyModifier:Int) ->
		{
			var key:Int = inputKeybinds.indexOf(keyCode);

			if (-1 != key && !cpuControlled && generatedMusic && holdArray[key])
			{
				holdArray[key] = false;

				var strum:StrumNote = strums.members[key + (4 * Std.int(Math.max(strumlines - 1, 1)))];

				if (strum.animation.curAnim.name == 'confirm' ||
					strum.animation.curAnim.name == 'pressed')
					strum.playAnim('static');
			}
		}

		onGameplayUpdate = (elapsed:Float) ->
		{
			// Don't remove this.
			hudCameraBelow.x = hudCamera.x;
			hudCameraBelow.y = hudCamera.y;
			hudCameraBelow.angle = hudCamera.angle;
			hudCameraBelow.alpha = hudCamera.alpha;
			hudCameraBelow.zoom = hudCamera.zoom;

			health = FlxMath.bound(health, 0.0, (Gameplay.hideHUD || Gameplay.noCharacters) ? 2.0 : hudGroup.healthBar.maxValue);

			Conductor.songPosition += elapsed * 1000.0;

			while (null != SONG.noteData[Math.floor(currentNoteId)])
			{
				// Avoid redundant array access
				var note:Array<Float> = SONG.noteData[Math.floor(currentNoteId)];
				var time:Float = note[0];

				if (Conductor.songPosition < time - (1950.0 / songSpeed))
					break;

				if (time >= 0 /* Don't spawn notes with negative strum time */)
					events.emit(SignalEvent.NOTE_SETUP, note);

				currentNoteId++;
			}

			for (i in 0...notes.members.length)
			{
				var note:Note = notes.members[i];
				if (note.exists)
				{
					note.distance = 0.45 * (Conductor.songPosition - note.strumTime) * (songSpeed * note.multSpeed);
					note.x = note.strum.x + note.offsetX;
					note.y = (note.strum.y + note.offsetY) + (-note.strum.scrollMult * note.distance);

					if (Conductor.songPosition >= note.strumTime + (750 / songSpeed)) // Remove them if they're offscreen
						note.exists = false;

					// For note hits and hold input

					if (note.strum.playerStrum)
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
				notes.members.sort((b:Note, a:Note) -> Std.int(a.y - b.y)); // Psych engine display note sorting moment
				pipeFrame();

				if (Conductor.songPosition - (20.0 + SONG.info.offset) >= songLength && !songEnded)
					endSong();
			}
		}

		events.on(SignalEvent.NOTE_NEW, newNote);
		events.on(SignalEvent.NOTE_SETUP, setupNoteData);
		events.on(SignalEvent.NOTE_HIT, onNoteHit);
		events.on(SignalEvent.NOTE_MISS, onNoteMiss);
		events.on(SignalEvent.GAMEPLAY_UPDATE, onGameplayUpdate);

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
	var currentNoteId:Float = 0;

	public var onGameplayCreate:()->(Void);
	public var onGameplayUpdate:(Float)->(Void);

	// Song events for hscript
	public function triggerEvent(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Hey!':
				if (!noCharacters)
				{
					var value:Int = 2;
					switch (value1.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend' | '0':
							value = 0;
						case 'gf' | 'girlfriend' | '1':
							value = 1;
					}

					var time:Float = Std.parseFloat(value2);
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
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1)
					value = 1;

				gfSpeed = value;

			case 'Add Camera Zoom':
				if (FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);

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
					switch (value2.toLowerCase().trim())
					{
						case 'bf' | 'boyfriend':
							char = bf;
						case 'gf' | 'girlfriend':
							char = gf;
						default:
							var val2:Int = Std.parseInt(value2);
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
					var charType:Int = 0;
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

				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

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

				var v1 = Std.parseFloat(value1);

				if (!Math.isNaN(v1))
				{
					if (value2 == 'true')
						songLengthTween = FlxTween.tween(this, {songLength: v1 * 1000.0}, 1, {ease: FlxEase.quintOut});
					else
						songLength = v1 * 1000.0;
				}
		}
	}

	private function generateSong(name:String, diff:String):Void
	{
		trace('Parsing chart data from song json...');

		SONG = Song.loadFromJson(name + '/' + name + diff);

		trace('Loaded ${SONG.noteData.length} notes! Now time to load more stuff here...');

		trace('Loading stage...');

		if (null == SONG.info.offset || SONG.info.offset < 0) // Fix offset
			SONG.info.offset = 0;

		strumlines = null == SONG.info.strumlines ? 2 : SONG.info.strumlines;

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

			startCharacterPos(gf, false);
			startCharacterPos(dad, true);
			startCharacterPos(bf, false);

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

		inst = new Sound(Paths.inst(SONG.song), endSong);

		add(inst);
		inst.volume = renderMode ? 0.0 : 1.0;

		trace('Loading voices audio file...');

		if (SONG.info.needsVoices)
		{
			voices = new Sound(Paths.voices(SONG.song), null);
			add(voices);
			voices.volume = inst.volume;
			voices.onComplete = voices.stop;
		}

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

		if (!renderMode && (null != inst || null != voices))
		{
			var off:Float = Conductor.songPosition + SONG.info.offset;
			if ((inst.time < off - 20.0 || inst.time > off + 20.0)
				|| (voices.time < off - 20.0 || voices.time > off + 20.0))
			{
				Conductor.songPosition = inst.time - SONG.info.offset;
				voices.setTime(Std.int(Conductor.songPosition) + SONG.info.offset);
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

	var isDad:Bool = true;
	public function dance(beat:Int):Void
	{
		if (!noCharacters)
		{
			if (null != gf
				&& 0 == beat % Math.round(gfSpeed * gf.danceEveryNumBeats)
				&& null != gf.animation.curAnim
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& !gf.stunned)
				gf.dance();

			if (null != dad
				&& 0 == beat % dad.danceEveryNumBeats
				&& null != dad.animation.curAnim
				&& !dad.animation.curAnim.name.startsWith('sing')
				&& !dad.stunned
				&& dad.animation.curAnim.finished)
				dad.dance();

			if (null != bf
				&& 0 == beat % bf.danceEveryNumBeats
				&& null != bf.animation.curAnim
				&& !bf.animation.curAnim.name.startsWith('sing')
				&& !bf.stunned
				&& bf.animation.curAnim.finished)
				bf.dance();

			moveCamera((isDad = !isDad) ? dad : bf);
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

			dance(swagCounter++);
		}, 5);
	}

	private function startSong():Void
	{
		if (songEnded)
			return;

		if (null != inst)
		{
			inst.play();
			songLength = inst.length;
		}

		if (null != voices)
			voices.play();

		startedCountdown = true;
	}

	public function endSong():Void
	{
		if (null != inst)
			inst.stop();

		if (null != hudGroup.timeTxt)
			hudGroup.timeTxt.visible = false;

		songEnded = true;
		switchState(new WelcomeState());
	}

	// Camera functions

	private function moveCamera(whatCharacter:Character):Void
	{
		if (null != camFollowPosTween)
			camFollowPosTween.cancel();

		if (!noCharacters)
		{
			var midpoint:flixel.math.FlxPoint = whatCharacter.getMidpoint();
			var camPosX:Float = whatCharacter.cameraPosition[0];
			var camPosY:Float = whatCharacter.cameraPosition[1];

			if (null != whatCharacter)
			{
				camFollowPosTween = FlxTween.tween(camFollowPos, {
					x: whatCharacter == gf ? midpoint.x + camPosX + girlfriendCameraOffset[0] :
						whatCharacter == bf ? (midpoint.x - 100.0) - camPosX - boyfriendCameraOffset[0] :
						(midpoint.x + 150.0) + camPosX + opponentCameraOffset[0],
					y: whatCharacter == gf ? midpoint.y + camPosY + girlfriendCameraOffset[1] :
						whatCharacter == bf ? (midpoint.y - 100.0) + camPosY + boyfriendCameraOffset[1] :
						(midpoint.y - 100.0) + camPosY + opponentCameraOffset[1]
				}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut});
			}
		}
	}

	inline private function zoomTweenFunction(cam:FlxCamera, amount:Float = 1):FlxTween
		return FlxTween.tween(cam, {zoom: amount}, 1.3, {ease: FlxEase.expoOut});

	inline function set_defaultCamZoom(value:Float):Float
	{
		if (null != gameCameraZoomTween)
			gameCameraZoomTween.cancel();

		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, value);
		return defaultCamZoom = value;
	}

	inline function startCharacterPos(char:Character, gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			char.x = GF_X;
			char.y = GF_Y;
		}

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

	public var inputKeybinds:Array<Int> = [];

	private var holdArray(default, null):Array<Bool> = [false, false, false, false];

	private var onKeyDown:(Int, Int)->(Void);
	private var onKeyUp:(Int, Int)->(Void);

	inline private function fastNoteFilter(array:Array<Note>, f:(Note)->Bool):Array<Note>
		return [for (i in 0...array.length) { var a:Note = array[i]; if (f(a)) a; }];

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

		events.off(SignalEvent.NOTE_NEW, newNote);
		events.off(SignalEvent.NOTE_SETUP, setupNoteData);
		events.off(SignalEvent.NOTE_HIT, onNoteHit);
		events.off(SignalEvent.NOTE_MISS, onNoteMiss);
		events.off(SignalEvent.GAMEPLAY_UPDATE, onGameplayUpdate);

		Game.onKeyDown.off(SignalEvent.KEY_DOWN, onKeyDown);
		Game.onKeyUp.off(SignalEvent.KEY_UP, onKeyUp);

		super.destroy();
	}

	private var newNote:(Note)->(Void);

	// Used for recycling
	private var setupNoteData:(Array<Float>)->(Void);

	public var onNoteHit:(Note)->(Void);

	public var onNoteMiss:(Note)->(Void);

	// Render mode shit

	private var process:sys.io.Process;

	public var videoFramerate:Int = 60;
	public var videoEncoder:String = "libx265";
	public var outputPath:String = "output.mp4";

	private function initRender():Void
	{
		if (renderMode && sys.FileSystem.exists(#if windows 'ffmpeg.exe' #else 'ffmpeg' #end))
		{
			#if cpp
			cpp.vm.Gc.enable(true);
			#end
			cpuControlled = true;
			process = new sys.io.Process('ffmpeg', ['-v', 'quiet', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '1280x720', '-r', '$videoFramerate', '-i', '-', '-c:v', videoEncoder, Sys.getCwd().replace('\\', '/') + outputPath]);
			FlxG.autoPause = false;
		}
	}

	private function pipeFrame():Void
	{
		var img:lime.graphics.Image = lime.app.Application.current.window.readPixels(new lime.math.Rectangle(FlxG.scaleMode.offset.x, FlxG.scaleMode.offset.y, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));
		var bytes:haxe.io.Bytes = img.getPixels(new lime.math.Rectangle(0, 0, img.width, img.height));
		process.stdin.writeBytes(bytes, 0, bytes.length);
	}

	private function stopRender():Void
	{
		if (renderMode)
		{
			#if cpp
			cpp.vm.Gc.enable(false);
			#end
			process.stdin.close();
			process.close();
			process.kill();
			FlxG.autoPause = true;
		}
	}
}