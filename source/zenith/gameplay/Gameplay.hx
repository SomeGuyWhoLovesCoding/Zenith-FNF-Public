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
import lime.ui.*;

import zenith.objects.ui.Note; // Don't remove this.

using StringTools;

class Gameplay extends MusicBeatState
{
	private var unspawnNotes(default, null):Array<ChartNoteData> = [];
	private var eventNotes(default, null):Array<EventNote> = [];

	public var strums:FlxTypedGroup<StrumNote>;
	public var notes:FlxTypedGroup<Note>;

	// Health stuff
	private var hudGroup(default, null):HUDGroup;
	public var health:Float = 1;

	// Score text stuff
	public var score:Float = 0;
	public var misses:Float = 0;

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

	public var bfMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var boyfriendCameraOffset:Array<Float> = [0, 0];
	public var opponentCameraOffset:Array<Float> = [0, 0];
	public var girlfriendCameraOffset:Array<Float> = [0, 0];

	public var songSpeedTween(default, null):FlxTween;
	public var songLengthTween(default, null):FlxTween;

	public var songSpeed:Float = 1;
	public var songLength:Float = 0;
	public var noteMult:Float = 1;
	public var cameraSpeed:Float = 1;

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

	public var events:Emitter;

	override function create():Void
	{
		events = new Emitter();

		if (renderMode)
		{
			inline cpp.vm.Gc.enable(true);
			cpuControlled = true;
			initRender();
		}

		Paths.initNoteShit(); // Do NOT remove this or the game will crash

		events.on(SignalEvent.NOTE_FOLLOW, __note);
		events.on(SignalEvent.NOTE_HIT, onNoteHit);
		events.on(SignalEvent.NOTE_MISS, onNoteMiss);

		instance = this;

		// Preferences stuff
		
		/*downScroll = SaveData.preferences.get("DownScroll");
		hideHUD = SaveData.preferences.get("HideHUD");
		noCharacters = SaveData.preferences.get("NoCharacters");*/

		// Reset gameplay stuff
		FlxG.fixedTimestep = startedCountdown = songEnded = false;
		songSpeed = noteMult = 1;

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

		var songName:String = Sys.args()[0];

		if (null == Sys.args()[0]) // What?
			songName = 'test';

		var songDifficulty:String = '-' + Sys.args()[1];

		if (null == Sys.args()[1]) // What?
			songDifficulty = '';

		var timeStamp:Float = haxe.Timer.stamp();

		// You don't need to thread when loading into the song anyway
		try
		{
			generateSong(songName, songDifficulty);

			strums = new FlxTypedGroup<StrumNote>();
			add(strums);

			inline generateStrumline(0);
			inline generateStrumline(1);

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

			var finishTime:Float = (haxe.Timer.stamp() - timeStamp) * 1000;

			trace('Loading finished! Took ${flixel.util.FlxStringUtil.formatTime(finishTime, true, true)} to load.');

			if (!noCharacters)
			{
				camFollowPos.setPosition(
					gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0],
					gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1]
				);

				moveCameraSection();
			}

			generatedMusic = true;
			startCountdown();
		}
		catch (e)
		{
			if (renderMode)
				FlxG.autoPause = true;

			FlxG.switchState(new WelcomeState());
		}

		super.create();

		keyEmitter.on(SignalEvent.KEY_DOWN, onKeyDown);
		keyEmitter.on(SignalEvent.KEY_UP, onKeyUp);

		//trace(Sys.args());
	}

	var currentNote:Note;
	var noteIndex:UInt = 0;

	override function update(elapsed:Float):Void
	{
		if (!generatedMusic)
			return;

		if (renderMode)
			elapsed = 1 / videoFramerate;

		// Don't remove this.
		hudCameraBelow.x = hudCamera.x;
		hudCameraBelow.y = hudCamera.y;
		hudCameraBelow.angle = hudCamera.angle;
		hudCameraBelow.alpha = hudCamera.alpha;
		hudCameraBelow.zoom = hudCamera.zoom;

		health = FlxMath.bound(health, 0, (Gameplay.hideHUD || Gameplay.noCharacters) ? 2 : hudGroup.healthBar.maxValue);

		Conductor.songPosition += elapsed * 1000;

		noteIndex = 0;

		while (null != (currentNote = notes.members[noteIndex++]))
			inline events.emit(SignalEvent.NOTE_FOLLOW, currentNote, strums.members[currentNote.noteData + (currentNote.mustPress ? 4 : 0)]);

		while (null != unspawnNotes[unspawnNotes.length-1] && Conductor.songPosition > unspawnNotes[unspawnNotes.length-1].strumTime - (1950 / songSpeed))
			inline notes.recycle(Note).setupNoteData(unspawnNotes.pop());

		// This used to be a function
		while(eventNotes[eventNotes.length-1] != null && Conductor.songPosition > eventNotes[eventNotes.length-1].strumTime)
		{
			var value1:String = '';
			if(null != eventNotes[eventNotes.length-1].value1)
				value1 = eventNotes[eventNotes.length-1].value1;

			var value2:String = '';
			if(null != eventNotes[eventNotes.length-1].value2)
				value2 = eventNotes[eventNotes.length-1].value2;

			inline triggerEventNote(eventNotes.pop().event, value1, value2);
		}

		super.update(elapsed);

		if (!renderMode)
			return;

		notes.members.sort((b, a) -> Std.int(a.y - b.y)); // Psych engine display note sorting moment
		pipeFrame();

		if (Conductor.songPosition - (20 + SONG.offset) >= (Std.int(songLength) | Std.int(voices.length)) && !songEnded)
			endSong();
	}

	inline public function triggerEventNote(eventName:String, value1:String, value2:String)
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
					{
						inline char.playAnim(value1, true);
						char.specialAnim = true;
					}
				}

			case 'Change Character':
				if (noCharacters)
				{
					var charType:Int = 0;
					switch(value1.toLowerCase().trim()) {
						case 'gf' | 'girlfriend':
							charType = 2;
						case 'dad' | 'opponent':
							charType = 1;
						default:
							charType = Std.parseInt(value1);
							if(Math.isNaN(charType)) charType = 0;
					}

					switch(charType) {
						case 0:
							if(bf.curCharacter != value2) {
								if(!bfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = bf.alpha;
								bf.alpha = 0.001;
								bf = bfMap.get(value2);
								bf.alpha = lastAlpha;
								hudGroup.plrIcon.changeIcon(bf.healthIcon);
							}

						case 1:
							if(dad.curCharacter != value2) {
								if(!dadMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var wasGf:Bool = dad.curCharacter.startsWith('gf');
								var lastAlpha:Float = dad.alpha;
								dad.alpha = 0.001;
								dad = dadMap.get(value2);
								if(!dad.curCharacter.startsWith('gf')) {
									if(wasGf && null != gf) {
										gf.visible = true;
									}
								} else if(null != gf) {
									gf.visible = false;
								}
								dad.alpha = lastAlpha;
								hudGroup.oppIcon.changeIcon(dad.healthIcon);
							}

						case 2:
							if(null != gf)
							{
								if(gf.curCharacter != value2)
								{
									if(!gfMap.exists(value2))
									{
										addCharacterToList(value2, charType);
									}

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

				var newValue:Float = SONG.speed * val1;

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
						songLengthTween = FlxTween.tween(this, {songLength: v1 * 1000}, 1, {ease: FlxEase.quintOut});
					else
						songLength = v1 * 1000;
				}
		}
	}

	private function generateSong(name:String, diff:String):Void
	{
		trace('Parsing chart data from song json...');

		SONG = Song.loadFromJson(name + '/' + name + diff);

		trace('Loading stage...');

		if (null == SONG.offset || SONG.offset < 0) // Fix offset
			SONG.offset = 0;

		curSong = SONG.song;
		songSpeed = SONG.speed;

		curStage = SONG.stage;

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

		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;

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

			if (null == SONG.gfVersion || SONG.gfVersion == '') // Fix gf version (for vanilla charts)
				SONG.gfVersion = 'gf';

			gf = new Character(0, 0, SONG.gfVersion);
			dad = new Character(0, 0, SONG.player2);
			bf = new Character(0, 0, SONG.player1, true);

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

		inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
		if (!renderMode)
			inst.onComplete = endSong;
		inline FlxG.sound.list.add(inst);

		trace('Loading voices audio file...');

		voices = new FlxSound();
		if (SONG.needsVoices)
			voices.loadEmbedded(Paths.voices(SONG.song));
		inline FlxG.sound.list.add(voices);

		inst.looped = voices.looped = false;
		inst.volume = voices.volume = renderMode ? 0 : 1;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		trace('Loading event data from event json...');

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (sys.FileSystem.exists(Paths.ASSET_PATH + '/data/' + songName + '/events.json'))
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var subEvent:EventNote = {
						strumTime: event[0],
						event: event[1][i][0],
						value1: event[1][i][1],
						value2: event[1][i][2]
					};
					inline eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		trace('Loading chart data...');

		var notesLength:Int = 0;

		for (section in SONG.notes)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;
				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				inline unspawnNotes.push({
					strumTime: daStrumTime,
					noteData: daNoteData,
					mustPress: gottaHitNote,
					noteType: songNotes[3],
					gfNote: (songNotes.gfSection && songNotes[1] < 4),
					isSustainNote: false,
					isSustainEnd: false,
					sustainLength: songNotes[2],
					noAnimation: songNotes[3] == 'No Animation'
				});
				notesLength++;

				var floorSus:Int = Std.int(Math.max(songNotes[2], 0) / Conductor.stepCrochet);
				if (floorSus > 1) // Don't add sustain notes that are one step long or less
				{
					for (susNote in 0...floorSus)
					{
						inline unspawnNotes.push({
							strumTime: daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)),
							noteData: daNoteData,
							mustPress: gottaHitNote,
							noteType: songNotes[3],
							gfNote: (section.gfSection && songNotes[1] < 4),
							isSustainNote: true,
							isSustainEnd: susNote == (floorSus - 1),
							sustainLength: 0,
							noAnimation: songNotes[3] == 'No Animation'
						});
					}
				}
			}
		}

		trace('Loaded $notesLength notes! Now loading event data from chart...');

		for (event in SONG.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var subEvent:EventNote = {
					strumTime: event[0],
					event: event[1][i][0],
					value1: event[1][i][1],
					value2: event[1][i][2]
				};
				inline eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		trace('Let\'s finish up chart and events loading...');

		inline unspawnNotes.sort((b, a) -> Std.int(a.strumTime - b.strumTime));
		inline eventNotes.sort((b, a) -> Std.int(a.strumTime - b.strumTime));

		// Run GC twice so it knows what it's doing
		cpp.vm.Gc.run(false);
		cpp.vm.Gc.run(true);

		trace('Done! Now time to load HUD objects...');
	}

	inline public function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				if (noCharacters)
				{
					var charType:Int = 0;
					switch(event.value1.toLowerCase()) {
						case 'gf' | 'girlfriend' | '1':
							charType = 2;
						case 'dad' | 'opponent' | '0':
							charType = 1;
						default:
							charType = Std.parseInt(event.value1);
							if(Math.isNaN(charType)) charType = 0;
					}

					var newCharacter:String = event.value2;
					addCharacterToList(newCharacter, charType);
				}
		}
	}

	inline public function generateStrumline(player:Int = 0):Void
	{
		for (i in 0...4)
		{
			var strum = new StrumNote(i, player);
			strum.scrollMult = downScroll ? -1 : 1;
			strum.x = 60 + (112 * strum.noteData) + ((FlxG.width * 0.5587511111112) * strum.player);
			strum.y = downScroll ? FlxG.height - 160 : 60;
			inline strums.add(strum);
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
			final off:Float = Conductor.songPosition + SONG.offset;
			if ((inst.time < off - 20 || inst.time > off + 20)
				|| (voices.time < off - 20 || voices.time > off + 20))
			{
				Conductor.songPosition = inst.time - SONG.offset;
				voices.time = Conductor.songPosition + SONG.offset;
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

		if (noCharacters)
			return;

		if (null != gf
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& null != gf.animation.curAnim
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& !gf.stunned)
			gf.dance();

		if (null != dad
			&& curBeat % dad.danceEveryNumBeats == 0
			&& null != dad.animation.curAnim
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
			dad.dance();

		if (null != bf
			&& curBeat % bf.danceEveryNumBeats == 0
			&& null != bf.animation.curAnim
			&& !bf.animation.curAnim.name.startsWith('sing')
			&& !bf.stunned)
			bf.dance();

		lastBeatHit = curBeat;

		if (!renderMode)
			notes.members.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (null == SONG.notes[curSection])
			return;

		if (SONG.notes[curSection].changeBPM)
			Conductor.changeBPM(SONG.notes[curSection].bpm);

		moveCameraSection();

		if (null != gameCameraZoomTween)
			gameCameraZoomTween.cancel();
		if (null != hudCameraZoomTween)
			hudCameraZoomTween.cancel();

		FlxG.camera.zoom += 0.015;
		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, defaultCamZoom);
		hudCamera.zoom += 0.03;
		hudCameraZoomTween = zoomTweenFunction(hudCamera, 1);
	}

	private function startCountdown():Void
	{
		if (songEnded)
			return;

		inputKeybinds = [
			SaveData.controls.get("Note_Left"),
			SaveData.controls.get("Note_Down"),
			SaveData.controls.get("Note_Up"),
			SaveData.controls.get("Note_Right")
		];

		var swagCounter:Int = 0;
		Conductor.songPosition = -Conductor.crochet * 5;

		//trace(swagCounter);

		new flixel.util.FlxTimer().start(Conductor.crochet * 0.001, (?timer) ->
		{
			var loopsLeft:Int = timer.loopsLeft;
			new flixel.util.FlxTimer().start(SONG.offset * 0.001, (?timer) ->
			{
				switch (swagCounter)
				{
					case 3:
						inline FlxG.sound.play(Paths.sound('introGo'), 0.6);

					case 4:
						startSong();

					default:
						inline FlxG.sound.play(Paths.sound('intro' + (3 - swagCounter)), 0.6);
				}
				// trace(swagCounter);

				swagCounter++;

				if (noCharacters)
					return;

				if (null != gf
					&& loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
					&& null != gf.animation.curAnim
					&& !gf.animation.curAnim.name.startsWith("sing")
					&& !gf.stunned)
					gf.dance();

				if (null != dad
					&& loopsLeft % dad.danceEveryNumBeats == 0
					&& null != dad.animation.curAnim
					&& !dad.animation.curAnim.name.startsWith('sing')
					&& !dad.stunned)
					dad.dance();

				if (null != bf
					&& loopsLeft % bf.danceEveryNumBeats == 0
					&& null != bf.animation.curAnim
					&& !bf.animation.curAnim.name.startsWith('sing')
					&& !bf.stunned)
					bf.dance();
			});
		}, 5);
	}

	private function startSong():Void
	{
		if (songEnded)
			return;

		inst.play();
		voices.play();

		Game.musicDeltaTarget = inst;

		songLength = inst.length;
		startedCountdown = true;
	}

	public function endSong():Void
	{
		stopRender();
		songEnded = true;
		switchState(new WelcomeState());
	}

	// Camera functions

	private function moveCameraSection():Void
	{
		if (null == SONG.notes[curSection])
			return;

		if (null != camFollowPosTween)
			camFollowPosTween.cancel();

		if (noCharacters)
			return;

		if (null != gf && SONG.notes[curSection].gfSection)
		{
			camFollowPosTween = FlxTween.tween(camFollowPos, {
				x: gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0],
				y: gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1]
			}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut});
			return;
		}

		moveCamera(!SONG.notes[curSection].mustHitSection);
	}

	public function moveCamera(isDad:Bool)
	{
		if (isDad)
		{
			camFollowPosTween = FlxTween.tween(camFollowPos, {
				x: (dad.getMidpoint().x + 150) + dad.cameraPosition[0] + opponentCameraOffset[0],
				y: (dad.getMidpoint().y - 100) + dad.cameraPosition[1] + opponentCameraOffset[1]
			}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut});
		}
		else
		{
			camFollowPosTween = FlxTween.tween(camFollowPos, {
				x: (bf.getMidpoint().x - 100) - bf.cameraPosition[0] - boyfriendCameraOffset[0],
				y: (bf.getMidpoint().y - 100) + bf.cameraPosition[1] + boyfriendCameraOffset[1]
			}, 1.3 * cameraSpeed, {ease: FlxEase.expoOut});
		}
	}

	private function zoomTweenFunction(cam:FlxCamera, amount:Float = 1):FlxTween
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

	function startCharacterPos(char:Character, gfCheck:Bool = false)
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

	public var inputKeybinds:Array<Int> = [];

	private var holdArray(default, null):Array<Bool> = [false, false, false, false];
	inline public function onKeyDown(keyCode:Int):Void
	{
		var key:Int = inline inputKeybinds.indexOf(keyCode);

		if (key == -1 || cpuControlled || !generatedMusic || holdArray[key])
			return;

		//trace(key); Testing...

		var strum:StrumNote = strums.members[key + 4];

		// For some reason the strum note still plays the press animation even when a note is hit sometimes, so here's a solution to it.
		if (strum.animation.curAnim.name != 'confirm')
			inline strum.playAnim('pressed');

		var hittable:Note = (inline fastNoteFilter(notes.members, n -> (n.mustPress && !n.isSustainNote) && Math.abs(Conductor.songPosition - n.strumTime) < 166.7 && !n.wasHit && !n.tooLate && n.noteData == key))[0];

		if (null != hittable)
		{
			inline strum.playAnim('confirm');
			inline events.emit(SignalEvent.NOTE_HIT, hittable);
		}

		holdArray[key] = true;
	}

	inline function fastNoteFilter(array:Array<Note>, f:Note->Bool):Array<Note>
	{
		return [for (i in 0...array.length) { var a:Note = array[i]; if (f(a)) a; }];
	}

	inline public function onKeyUp(keyCode:Int):Void
	{
		var key:Int = inline inputKeybinds.indexOf(keyCode);

		//trace(key); Testing...

		if (key == -1 || cpuControlled || !generatedMusic || !holdArray[key])
			return;

		holdArray[key] = false;

		var strum:StrumNote = strums.members[key + 4];

		if (strum.animation.curAnim.name == 'confirm' ||
			strum.animation.curAnim.name == 'pressed')
			inline strum.playAnim('static');
	}

	// Preferences stuff (Also for lua)

	var strumYTweens(default, null):Array<FlxTween> = [];
	var strumScrollMultTweens(default, null):Array<FlxTween> = [];
	public function changeDownScroll(whichStrum:Int = -1, tween:Bool = false, tweenLength:Float = 1):Void
	{
		// Strumline
		for (strum in strums.members)
		{
			if (strum.player == whichStrum || whichStrum == -1)
			{
				if (tween && tweenLength != 0)
				{
					var actualScrollMult:Float = strum.scrollMult;
					actualScrollMult = -actualScrollMult;

					if (null != strumScrollMultTweens[strums.members.indexOf(strum)])
						strumScrollMultTweens[strums.members.indexOf(strum)].cancel();

					strumScrollMultTweens[strums.members.indexOf(strum)] = FlxTween.tween(strum, {scrollMult: strum.scrollMult > 0 ? -1 : 1}, Math.abs(tweenLength), {ease: FlxEase.quintOut});

					if (null != strumYTweens[strums.members.indexOf(strum)])
						strumYTweens[strums.members.indexOf(strum)].cancel();

					strumYTweens[strums.members.indexOf(strum)] = FlxTween.tween(strum, {y: actualScrollMult < 0 ? FlxG.height - 160 : 60}, Math.abs(tweenLength), {ease: FlxEase.quintOut});
				}
				else
				{
					strum.scrollMult = -strum.scrollMult;
					strum.y = strum.scrollMult < 0 ? FlxG.height - 160 : 60;
				}
			}
		}
	}

	override function destroy():Void
	{
		stopRender();

		events.off(SignalEvent.NOTE_FOLLOW, __note);
		events.off(SignalEvent.NOTE_HIT, onNoteHit);
		events.off(SignalEvent.NOTE_MISS, onNoteMiss);

		keyEmitter.off(SignalEvent.KEY_DOWN, onKeyDown);
		keyEmitter.off(SignalEvent.KEY_UP, onKeyUp);

		super.destroy();
	}

	inline public function onNoteHit(note:Note):Void
	{
		if (!note.mustPress || note.isSustainNote || cpuControlled)
			inline strums.members[note.noteData + (note.mustPress ? 4 : 0)].playAnim('confirm');

		note.wasHit = true;
		note.exists = false;

		health += (0.045 * (note.isSustainNote ? 0.5 : 1)) * (note.mustPress ? 1 : -1);

		if (note.mustPress && !note.isSustainNote)
			score += 350 * noteMult;

		if (!noCharacters)
		{
			var char = (note.mustPress ? instance.bf : (note.gfNote ? gf : dad));
	
			if (null != char)
			{
				inline char.playAnim(@:privateAccess singAnimations[note.noteData], true);
				char.holdTimer = 0;
			}
		}
	}

	inline public function onNoteMiss(note:Note):Void
	{
		note.tooLate = true;

		health -= 0.045 * (note.isSustainNote ? 0.5 : 1);
		score -= 100 * noteMult;
		misses++;

		if (!noCharacters)
		{
			inline bf.playAnim(@:privateAccess singAnimations[note.noteData] + 'miss', true);
			bf.holdTimer = 0;
		}
	}

	inline function __note(note:Note, strum:StrumNote):Void
	{
		if (note.exists)
		{
			note.flipX = note.flipY = strum.scrollMult <= 0 && note.isSustainNote;
	
			// Sustain scaling for song speed (even if it's changed)
			// Psych engine sustain note calculation moment
			note.scale.set(0.7, note.isSustainNote ? (note.animation.curAnim.name.endsWith('end') ? 1 : (153.75 / SONG.bpm) * (songSpeed * note.multSpeed) * Math.abs(strum.scrollMult)) : 0.7);
			note.updateHitbox();
	
			note.distance = 0.45 * (Conductor.songPosition - note.strumTime) * (songSpeed * note.multSpeed);
			note.x = strum.x + note.offsetX;
			note.y = (strum.y + note.offsetY) + (-strum.scrollMult * note.distance) - (note.flipY ? (note.frameHeight * note.scale.y) - strum.height : 0);
	
			if (Conductor.songPosition >= note.strumTime + (750 / Gameplay.instance.songSpeed)) // Remove them if they're offscreen
				note.exists = false;
	
			// For note hits and input
	
			if (note.mustPress)
			{
				if (cpuControlled)
					if (Conductor.songPosition >= note.strumTime)
						inline events.emit(SignalEvent.NOTE_HIT, note);
	
				if (Conductor.songPosition >= note.strumTime + (Conductor.stepCrochet * 2) && (!note.wasHit && !note.tooLate))
					inline events.emit(SignalEvent.NOTE_MISS, note);
	
				if (note.isSustainNote)
					if (Conductor.songPosition >= note.strumTime && holdArray[note.noteData])
						inline events.emit(SignalEvent.NOTE_HIT, note);
			}
			else
				if (Conductor.songPosition >= note.strumTime)
					inline events.emit(SignalEvent.NOTE_HIT, note);
		}
	}

	// Render mode shit

	private var process:sys.io.Process;

	public var videoFramerate:Int = 60;
	public var videoEncoder:String = "libx265";
	public var outputPath:String = "output.mp4";

	private function initRender():Void
	{
		if (!renderMode)
			return;

		process = new sys.io.Process('ffmpeg', ['-v', 'quiet', '-y', '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '1280x720', '-r', '$videoFramerate', '-i', '-', '-c:v', videoEncoder, Sys.getCwd().replace('\\', '/') + outputPath]);

		FlxG.autoPause = false;
	}

	private function pipeFrame():Void
	{
		var img:lime.graphics.Image = lime.app.Application.current.window.readPixels(new lime.math.Rectangle(FlxG.scaleMode.offset.x, FlxG.scaleMode.offset.y, FlxG.scaleMode.gameSize.x, FlxG.scaleMode.gameSize.y));
		var bytes:haxe.io.Bytes = img.getPixels(new lime.math.Rectangle(0, 0, img.width, img.height));
		process.stdin.writeBytes(bytes, 0, bytes.length);
	}

	private function stopRender():Void
	{
		if (!renderMode)
			return;

		inline cpp.vm.Gc.enable(false);

		process.stdin.close();
		process.close();
		process.kill();

		FlxG.autoPause = true;
	}
}
