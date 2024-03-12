package zenithFunkin.gameplay;

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

import zenithFunkin.objects.ui.Note; // Don't remove this.

using StringTools;

class Gameplay extends MusicBeatState
{
	private var unspawnNotes(default, null):Array<ChartNoteData> = [];
	private var eventNotes(default, null):Array<EventNote> = [];

	public var sustains:FlxTypedGroup<Note>;
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
	private static var strumDownScroll(default, null):Bool = true;
	public static var hideHUD:Bool = false;
	public static var renderMode:Bool = false;

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

	private var keybinds(default, null):Array<flixel.input.keyboard.FlxKey> = [A, S, UP, RIGHT];

	private var singAnimations(default, null):Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static var instance:Gameplay;

	override public function create():Void
	{
		cpp.vm.Gc.enable(false);

		if (!cpuControlled)
		{
			Application.current.window.onKeyDown.add(onKeyDown);
			Application.current.window.onKeyUp.add(onKeyUp);
		}

		Paths.initNoteShit(); // Do NOT remove this or the game will crash

		instance = this;

		// Preferences stuff
		// Soon...

		// Reset gameplay stuff
		startedCountdown = songEnded = false;
		songSpeed = noteMult = 1;

		super.create();

		//FlxG.cameras.bgColor = 0xFF333333;

		persistentUpdate = persistentDraw = true;

		FlxG.fixedTimestep = renderMode;

		gameCamera = new FlxCamera();
		hudCamera = new FlxCamera();

		hudCamera.bgColor.alpha = hudCamera.bgColor.alpha = 0;

		FlxG.cameras.reset(gameCamera);
		FlxG.cameras.add(hudCamera, false);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.pixelPerfectPosition = false;

		FlxG.cameras.setDefaultDrawTarget(gameCamera, true);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var songName:String = Sys.args()[0];

		var songDifficulty:String = '-' + Sys.args()[1];
		trace(songDifficulty); // This is intentional, teehee

		if (songDifficulty == '-null') // What?
			songDifficulty = '';

		try
		{
			generateSong(songName, songDifficulty);

			sustains = new FlxTypedGroup<Note>();
			add(sustains);

			strums = new FlxTypedGroup<StrumNote>();
			add(strums);

			generateStrums(0);
			generateStrums(1);

			notes = new FlxTypedGroup<Note>();
			add(notes);

			if (!hideHUD)
			{
				hudGroup = new HUDGroup();
				add(hudGroup);

				@:privateAccess hudGroup.reloadHealthBar();
				hudGroup.cameras = [hudCamera];
			}

			sustains.cameras = strums.cameras = notes.cameras = [hudCamera];
		}
		catch (e:Dynamic)
		{
			if (songName != '-livereload') // Debug
				trace('Error: ' + e);

			FlxG.switchState(new WelcomeState());
		}

		//trace(Sys.args());
	}

	override public function update(elapsed:Float):Void
	{
		// Testing...
		/*if (FlxG.keys.justPressed.LBRACKET)
			changeDownScroll(0, true, 0.5);
		if (FlxG.keys.justPressed.RBRACKET)
			changeDownScroll(1, true, 0.5);*/

		super.update(elapsed);

		health = FlxMath.bound(health, 0, hudGroup.healthBar.maxValue);

		Conductor.songPosition += FlxG.elapsed * 1000;

		var spawnTime:Float = 1850 / songSpeed; // Don't use the value on before spawning a note

		while (unspawnNotes.length != 0 && Conductor.songPosition >= unspawnNotes[unspawnNotes.length-1].strumTime - spawnTime)
		{
			var dunceNote:Note = @:privateAccess (unspawnNotes[unspawnNotes.length-1].isSustainNote ? sustains : notes)
				.recycle(Note).setupNoteData(unspawnNotes[unspawnNotes.length-1]);

			var n:FlxTypedGroup<Note> = (dunceNote.isSustainNote ? sustains : notes);

			n.add(dunceNote);

			unspawnNotes.pop();
		}

		// This used to be a function
		while(eventNotes.length != 0 && Conductor.songPosition >= eventNotes[eventNotes.length-1].strumTime)
		{
			var value1:String = '';
			if(null != eventNotes[eventNotes.length-1].value1)
				value1 = eventNotes[eventNotes.length-1].value1;

			var value2:String = '';
			if(null != eventNotes[eventNotes.length-1].value2)
				value2 = eventNotes[eventNotes.length-1].value2;

			triggerEventNote(eventNotes[eventNotes.length-1].event, value1, value2);

			eventNotes.pop();
		}

		for (grp in [notes, sustains])
		{
			for (daNote in grp.members)
			{
				daNote.followStrum(strums.members[daNote.noteData + (daNote.mustPress ? 4 : 0)]);
				daNote.onNoteHit = onNoteHit;
				daNote.onNoteMiss = onNoteMiss;

				/*daNote.onNoteHit = function(noteData:Int, mustPress:Bool) {
					// Testing...
					//trace(noteData, mustPress);
				}*/

				if (Conductor.songPosition >= daNote.strumTime)
				{
					// Opponent note hits
					if (!daNote.mustPress || cpuControlled)
						daNote.hit();

					// Sustain note input
					if (daNote.mustPress && daNote.isSustainNote && (!daNote.wasHit && !daNote.tooLate /* Fix for hold notes not hitting correctly */) &&
						holdArray[daNote.noteData] && !cpuControlled)
						daNote.hit();
				}

				if (Conductor.songPosition >= daNote.strumTime + (Conductor.stepCrochet * 2) && (daNote.mustPress && !daNote.wasHit) && !cpuControlled)
					daNote.miss();

				if (Conductor.songPosition >= daNote.strumTime + (750 / songSpeed)) // Remove them if they're offscreen
					daNote.exists = false;
			}
		}

		//trace(inst.time,voices.time);

		// This is just to test the strum anims!
		/*for (i in 0...keybinds.length) {
			if (FlxG.keys.anyJustPressed([keybinds[i]])) {
				if (FlxG.keys.pressed.SPACE)
					strums.members[i+4].playAnim('confirm');
				else
					strums.members[i+4].playAnim('pressed');
			}
			if (FlxG.keys.anyJustReleased([keybinds[i]])) {
				strums.members[i+4].playAnim('static');
			}
		}*/

		if (renderMode)
		{
			if (!sys.FileSystem.exists(Paths.ASSET_PATH + '/gameRenders/' + Paths.formatToSongPath(SONG.song)))
				sys.FileSystem.createDirectory(Paths.ASSET_PATH + '/gameRenders/' + Paths.formatToSongPath(SONG.song));
			Screenshot.capture(FlxG.game, null, Paths.ASSET_PATH + '/gameRenders/' + Paths.formatToSongPath(SONG.song) + '/' + zeroFill(7, Std.string(framesCaptured++)));
		}
	}

	function zeroFill(num:Int, a:String):String
	{
		var result = '';
		while (result.length <= num - (a.length + 1)) result += '0';
		return result += a;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		switch (eventName)
		{
			case 'Hey!':
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
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
					if (null != dad && dad.curCharacter == gf.curCharacter)
					{
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
				}
				else
				{
					if (null != bf) {
						bf.playAnim('hey', true);
						bf.specialAnim = true;
						bf.heyTimer = time;
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
					gameCameraZoomTween = zoomTweenFunction(hudCamera, 1);
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
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
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Change Character':
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
				@:privateAccess hudGroup.reloadHealthBar();

			case 'Change Scroll Speed':
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
		trace('Loading song json...');

		SONG = Song.loadFromJson(name + '/' + name + diff);

		trace('Done!');

		if (null == SONG.offset) // Fix offset
			SONG.offset = 0;

		curSong = SONG.song;
		songSpeed = SONG.speed;

		curStage = SONG.stage;

		SONG.stage = curStage;

		// Setup stage

		if (null == SONG.stage || SONG.stage == '') // Fix stage (For vanilla charts)
			SONG.stage = 'stage';

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

		trace('Loading characters from chart...');

		bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': // Week 1
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
				var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
				stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
				stageLight.updateHitbox();
				stageLight.flipX = true;
				add(stageLight);

				var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				add(stageCurtains);

		}

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

		camFollowPos.setPosition(
			gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0],
			gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1]
		);

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (null != gf)
				gf.active = gf.visible = false;
		}

		moveCameraSection();

		FlxG.camera.zoom = defaultCamZoom;

		trace('Done!');

		trace('Loading song file...');

		inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
		if (!renderMode)
			inst.onComplete = endSong;
		FlxG.sound.list.add(inst);

		voices = new FlxSound();
		if (SONG.needsVoices)
			voices.loadEmbedded(Paths.voices(SONG.song));
		FlxG.sound.list.add(voices);

		// Do this
		inst.looped = voices.looped = false;

		trace('Done!');

		trace('Loading chart...');

		Conductor.changeBPM(SONG.bpm);

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
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

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

				unspawnNotes.push({
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
						unspawnNotes.push({
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
						//Sys.sleep(0.0001);
					}
				}
				//Sys.sleep(0.0001);
			}
		}

		trace('Loaded $notesLength notes... Now time to finish up events and sort all of the notes...');

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
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		//trace(unspawnNotes);

		inline unspawnNotes.sort((b, a) -> Std.int(a.strumTime - b.strumTime));
		inline eventNotes.sort((b, a) -> Std.int(a.strumTime - b.strumTime));

		openfl.system.System.gc();

		trace('Done!');

		startCountdown();
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
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
				// Will be adding change character support soon...
		}
	}

	private function generateStrums(player:Int = 0):Void
	{
		for (i in 0...4)
		{
			var strum = new StrumNote(i, player);
			strum.scrollMult = downScroll ? -1 : 1;
			strum.x = 60 + (112 * strum.noteData) + ((FlxG.width * 0.5587511111112) * strum.player);
			strum.y = downScroll ? FlxG.height - 160 : 60;
			strums.add(strum);
		}
	}

	override function stepHit():Void
	{
		// Don't resync vocals at the first 2 steps, otherwise it may cause issues with the sound timing
		if (curStep < 2)
			return;

		if (!renderMode)
		{
			if ((inst.time < (Conductor.songPosition + SONG.offset) - 20 || inst.time > (Conductor.songPosition + SONG.offset) + 20)
				|| (voices.time < (Conductor.songPosition + SONG.offset) - 20 || voices.time > (Conductor.songPosition + SONG.offset) + 20))
			{
				Conductor.songPosition = inst.time - SONG.offset;
				voices.time = Conductor.songPosition + SONG.offset;
			}
		}

		notes.members.sort((a, b) -> (renderMode ? Std.int(b.y - a.y) : Std.int(a.strumTime - b.strumTime)));
		sustains.members.sort((a, b) -> (renderMode ? Std.int(b.y - a.y) : Std.int(a.strumTime - b.strumTime)));

		super.stepHit();
	}

	override function beatHit():Void
	{
		if (gf != null
			&& curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& gf.animation.curAnim != null
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& gf.animation.curAnim.name.endsWith(curBeat % 2 == 0 ? "Right" : "Left")
			&& !gf.stunned)
			gf.dance();

		if (dad != null
			&& curBeat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			|| dad.animation.curAnim.name.endsWith(curBeat % 2 == 0 ? "Right" : "Left")
			&& !dad.stunned)
			dad.dance();

		if (bf != null
			&& curBeat % bf.danceEveryNumBeats == 0
			&& bf.animation.curAnim != null
			&& !bf.animation.curAnim.name.startsWith('sing')
			&& !bf.stunned)
			bf.dance();

		super.beatHit();
	}

	override function sectionHit():Void
	{
		if (null != gameCameraZoomTween)
			gameCameraZoomTween.cancel();
		if (null != hudCameraZoomTween)
			hudCameraZoomTween.cancel();

		FlxG.camera.zoom += 0.015;
		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, defaultCamZoom);
		hudCamera.zoom += 0.03;
		hudCameraZoomTween = zoomTweenFunction(hudCamera, 1);

		moveCameraSection();

		super.sectionHit();
	}

	private function startCountdown():Void
	{
		if (songEnded)
			return;

		var swagCounter:Int = 0;
		Conductor.songPosition = (-Conductor.crochet * 5) - SONG.offset;

		//trace(swagCounter);

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
			// trace(swagCounter);

			if (gf != null
				&& timer.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
				&& gf.animation.curAnim != null
				&& !gf.animation.curAnim.name.startsWith("sing")
				&& gf.animation.curAnim.name.endsWith(timer.loopsLeft % 2 == 0 ? "Right" : "Left")
				&& !gf.stunned)
				gf.dance();

			if (dad != null
				&& timer.loopsLeft % dad.danceEveryNumBeats == 0
				&& dad.animation.curAnim != null
				&& !dad.animation.curAnim.name.startsWith('sing')
				|| dad.animation.curAnim.name.endsWith(timer.loopsLeft % 2 == 0 ? "Right" : "Left")
				&& !dad.stunned)
				dad.dance();

			if (bf != null
				&& timer.loopsLeft % bf.danceEveryNumBeats == 0
				&& bf.animation.curAnim != null
				&& !bf.animation.curAnim.name.startsWith('sing')
				&& !bf.stunned)
				bf.dance();

			swagCounter++;
		}, 5);
	}

	private function startSong():Void
	{
		if (songEnded)
			return;

		inst.play();
		voices.play();
		inst.volume = voices.volume = renderMode ? 0 : 1;

		songLength = inst.length;
		startedCountdown = true;
	}

	public function endSong():Void
	{
		songEnded = true;
		MusicBeatState.switchState(new WelcomeState());
	}

	// Note hit functions

	public function onNoteHit(note:Note):Void
	{
		note.exists = false;

		var char = (note.mustPress ? bf : (note.gfNote ? gf : dad));

		char.playAnim(singAnimations[note.noteData], true);
		char.holdTimer = 0;

		/*// For some reason the strum confirm anim is still played when you stop holding the sustain note at the very tail, so here's a solution to it.
		if (holdArray[note.noteData] || (!note.isSustainNote || !note.mustPress)) // Dumbass if check*/

		strums.members[note.noteData + (note.mustPress ? 4 : 0)].playAnim('confirm');

		health += (0.045 * (note.isSustainNote ? 0.5 : 1)) * (note.mustPress ? 1 : -1);

		if (!note.isSustainNote && note.mustPress)
			score += 350 * noteMult;
	}

	public function onNoteMiss(note:Note):Void
	{
		if (!note.isSustainNote && note.mustPress)
		{
			bf.playAnim(singAnimations[note.noteData] + 'miss', true);
			bf.holdTimer = 0;

			health -= 0.045 * (note.isSustainNote ? 0.5 : 1);
			score -= 100;
			misses++;
		}
	}

	// Camera functions

	private function moveCameraSection():Void
	{
		if (null == SONG.notes[curSection])
			return;

		if (null != camFollowPosTween)
			camFollowPosTween.cancel();

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

	var inputKeybinds:Array<Int> = [
		KeyCode.A,
		KeyCode.S,
		KeyCode.UP,
		KeyCode.RIGHT
	];

	var holdArray:Array<Bool> = [false, false, false, false];

	function onKeyDown(keyCode:Int, keyMod:Int):Void
	{
		var key:Int = inline inputKeybinds.indexOf(keyCode);

		if (key == -1 || cpuControlled || renderMode || holdArray[key])
			return;

		//trace(key); Testing...

		// For some reason the strum note still plays the press animation even when a note is hit sometimes, so here's a solution to it.
		if (strums.members[key + 4].animation.curAnim.name != 'confirm')
			inline strums.members[key + 4].playAnim('pressed');

		var hittable:Note = (inline notes.members.filter(n -> (n.mustPress && !n.isSustainNote) && Math.abs(Conductor.songPosition - n.strumTime) < 166.7 && n.noteData == key && !n.wasHit && !n.tooLate))[0];

		if (null != hittable)
			hittable.hit();

		holdArray[key] = true;
	}

	function onKeyUp(keyCode:Int, keyMod:Int):Void
	{
		var key:Int = inline inputKeybinds.indexOf(keyCode);

		//trace(key); Testing...

		if (key == -1 || cpuControlled || renderMode || !holdArray[key])
			return;

		inline strums.members[key + 4].playAnim('static');

		holdArray[key] = false;
	}

	override function destroy():Void
	{
		super.destroy();

		Application.current.window.onKeyDown.remove(onKeyDown);
		Application.current.window.onKeyUp.remove(onKeyUp);
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

		//downScroll = strums.members.filter(s -> s.scrollMult > 0).length == 0 || strums.members.filter(s -> s.scrollMult < 0).length != 0; That's a preference LMAO
	}
}
