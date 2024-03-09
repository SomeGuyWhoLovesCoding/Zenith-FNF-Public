package;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxSort;

import Note; // Don't remove this.

using StringTools;

class PlayState extends MusicBeatState
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

	// Preference stuff
	public static var downScroll:Bool = false;
	public static var optimizeNotes:Bool = true;
	public static var hideHUD:Bool = false;
	public static var renderMode:Bool = false;

	private var notesAdded(default, null):Int = 0;
	private var eventsAdded(default, null):Int = 0;

	private var framesCaptured(default, null):Int = 0;

	// Song stuff
	public static var SONG:Song.SwagSong;

	// Gameplay stuff

	// For events
	public var curSong:String = 'test';
	public var curStage:String = 'stage';

	// For optimization stuff
	private var strumAnimsPlayedDuringCurrentFrame(default, null):Int = 0;

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

	public var songSpeedTween:FlxTween;
	public var songLengthTween:FlxTween;

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

	public var gameCameraZoomTween:FlxTween;
	public var hudCameraZoomTween:FlxTween;

	public var defaultCamZoom(default, set):Float;

	public var camFollowPos:FlxObject;
	public var camFollowPosTween:FlxTween;

	private var keybinds(default, null):Array<flixel.input.keyboard.FlxKey> = [A, S, UP, RIGHT];

	private var singAnimations(default, null):Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static var instance:PlayState;

	override public function create():Void
	{
		cpp.vm.Gc.enable(true);

		Paths.initNoteShit(); // Do NOT remove this or the game will crash

		instance = this;

		// Preferences stuff
		// Soon...

		// Reset gameplay stuff
		startedCountdown = false;
		songEnded = false;
		songSpeed = 1;
		noteMult = 1;

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

		/*if (songName == null)
			songName = 'test';*/

		var songDifficulty:String = '-' + Sys.args()[1];
		trace(songDifficulty);

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
			FlxG.switchState(new WelcomeState());

		//trace(Sys.args());
	}

	override public function update(elapsed:Float):Void
	{
		if (optimizeNotes && strumAnimsPlayedDuringCurrentFrame != 0)
			strumAnimsPlayedDuringCurrentFrame = 0;

		super.update(elapsed);

		Conductor.songPosition += FlxG.elapsed * 1000;

		while (unspawnNotes.length != 0 && unspawnNotes[unspawnNotes.length-(optimizeNotes ? 1 : notesAdded + 1)] != null)
		{
			if(Conductor.songPosition < unspawnNotes[unspawnNotes.length-(optimizeNotes ? 1 : notesAdded + 1)].strumTime - 1850 / (songSpeed / hudCamera.zoom))
				break;

			var dunceNote:Note = @:privateAccess (unspawnNotes[unspawnNotes.length-(optimizeNotes ? 1 : notesAdded + 1)].isSustainNote ? sustains : notes)
				.recycle(Note).setupNoteData(unspawnNotes[unspawnNotes.length-(optimizeNotes ? 1 : notesAdded + 1)]);

			var n:FlxTypedGroup<Note> = (dunceNote.isSustainNote ? sustains : notes);

			dunceNote.prevNote = n.members[n.members.length-1];

			n.add(dunceNote);
			n.members.sort((b, a) -> Std.int((a != null ? a.strumTime : 0) - (b != null ? b.strumTime : 0)));

			//n.sortNotes();

			if (optimizeNotes)
				unspawnNotes.pop();
			else
				notesAdded++;
		}

		// This used to be a function
		while(eventNotes.length != 0 && eventNotes[eventNotes.length-(optimizeNotes ? 1 : eventsAdded + 1)] != null)
		{
			if(Conductor.songPosition < eventNotes[eventNotes.length-(optimizeNotes ? 1 : eventsAdded + 1)].strumTime)
				break;

			//trace(eventNotes[eventNotes.length-1].event);

			var value1:String = '';
			if(eventNotes[eventNotes.length-(optimizeNotes ? 1 : eventsAdded + 1)].value1 != null)
				value1 = eventNotes[eventNotes.length-(optimizeNotes ? 1 : eventsAdded + 1)].value1;

			var value2:String = '';
			if(eventNotes[eventNotes.length-(optimizeNotes ? 1 : eventsAdded + 1)].value2 != null)
				value2 = eventNotes[eventNotes.length-(optimizeNotes ? 1 : eventsAdded + 1)].value2;

			triggerEventNote(eventNotes[eventNotes.length-(optimizeNotes ? 1 : eventsAdded + 1)].event, value1, value2);

			if (optimizeNotes)
				eventNotes.pop();
			else
				eventsAdded++;
		}

		for (grp in [notes, sustains])
			grp.forEach(function(daNote:Note) {
				daNote.followStrum(strums.members[daNote.noteData + (daNote.mustPress ? 4 : 0)]);
				daNote.onNoteHit = onNoteHit;
				/*daNote.onNoteHit = function(noteData:Int, mustPress:Bool) {
					// Testing...
					//trace(noteData, mustPress);
				}*/

				if (Conductor.songPosition >= daNote.strumTime)
					daNote.hit();

				if (Conductor.songPosition >= daNote.strumTime + (750 / songSpeed)) // Remove them if they're offscreen
					grp.remove(daNote);
			});

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
					if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
					if (dad != null && dad.curCharacter == gf.curCharacter)
					{
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
				}
				else
				{
					if (bf != null) {
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

					if (gameCameraZoomTween != null)
						gameCameraZoomTween.cancel();
					if (hudCameraZoomTween != null)
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

				if (char != null)
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
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							hudGroup.oppIcon.changeIcon(dad.healthIcon);
						}

					case 2:
						if(gf != null)
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
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear});

			case 'Fake Song Length':
				if (songLengthTween != null)
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

		if (SONG.stage == null || SONG.stage == '') // Fix stage
			SONG.stage = 'stage';

		curSong = SONG.song;
		songSpeed = SONG.speed;

		curStage = SONG.stage;

		SONG.stage = curStage;

		var stageData:StageData.StageFile = StageData.getStageFile(curStage);
		if (stageData == null) // Stage couldn't be found, create a dummy stage to prevent crashing
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

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null)
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

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

		if (SONG.gfVersion == null || SONG.gfVersion == '') // Fix gf version (for vanilla charts)
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
			if (gf != null)
				gf.active = gf.visible = false;
		}

		moveCameraSection();

		FlxG.camera.zoom = defaultCamZoom;

		trace('Done!');

		trace('Loading song file...');

		inst = new FlxSound().loadEmbedded(Paths.inst(SONG.song));
		if (!renderMode)
			inst.onComplete = endSong.bind();
		FlxG.sound.list.add(inst);

		voices = new FlxSound();
		if (SONG.needsVoices)
			voices.loadEmbedded(Paths.voices(SONG.song));
		if (!renderMode)
			voices.onComplete = endSong.bind();
		FlxG.sound.list.add(voices);

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
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0],
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
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
					prevNote: unspawnNotes[unspawnNotes.length - 1],
					noAnimation: songNotes[3] == 'No Animation'
				});
				notesLength++;

				var floorSus:Int = Std.int(Math.max(unspawnNotes[unspawnNotes.length-1].sustainLength, 0) / Conductor.stepCrochet);
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
							prevNote: unspawnNotes[unspawnNotes.length - 1],
							noAnimation: songNotes[3] == 'No Animation'
						});
						//Sys.sleep(0.0001);
					}
				}
				//Sys.sleep(0.0001);
			}
		}

		trace('Loaded $notesLength notes... Now time to finish up events...');

		for (event in SONG.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0],
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort((b, a) -> Std.int(a.strumTime - b.strumTime));
		eventNotes.sort((b, a) -> Std.int(a.strumTime - b.strumTime));
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
			strum.downScroll = downScroll;
			strums.add(strum);
			strum.x = 60 + (112 * strum.noteData) + ((FlxG.width * 0.5587511111112) * strum.player);
			strum.y = strum.downScroll ? FlxG.height - 160 : 60;
		}
	}

	override function stepHit():Void
	{
		// Don't resync vocals at the first 2 steps, otherwise it may cause issues with the sound timing
		if (curStep < 2)
			return;

		if (!renderMode)
		{
			if ((inst.time < Conductor.songPosition - 20 || inst.time > Conductor.songPosition + 20)
				|| (voices.time < Conductor.songPosition - 20 || voices.time > Conductor.songPosition + 20))
			{
				Conductor.songPosition = inst.time;
				voices.time = Conductor.songPosition;
			}
		}

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
		if (gameCameraZoomTween != null)
			gameCameraZoomTween.cancel();
		if (hudCameraZoomTween != null)
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
		Conductor.songPosition = -Conductor.crochet * 5;

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
		FlxG.switchState(new WelcomeState());
	}

	// Note hit functions

	public function onNoteHit(note:Note):Void
	{
		var char = (note.mustPress ? bf : (note.gfNote ? gf : dad));

		if (optimizeNotes)
		{
			if (strumAnimsPlayedDuringCurrentFrame < strums.length)
			{
				strums.members[note.noteData + (note.mustPress ? 4 : 0)].playAnim('confirm');
				strumAnimsPlayedDuringCurrentFrame++;
			}
		}
		else
			strums.members[note.noteData + (note.mustPress ? 4 : 0)].playAnim('confirm');

		char.playAnim(singAnimations[note.noteData], true);
		char.holdTimer = 0;

		health += (0.045 * (note.isSustainNote ? 0.5 : 1)) * (note.mustPress ? 1 : -1);
		health = FlxMath.bound(health, 0, 2);

		if (!hideHUD && !note.isSustainNote && note.mustPress)
			score += 350;
	}

	// Camera functions

	private function moveCameraSection():Void
	{
		if (SONG.notes[curSection] == null)
			return;

		if (camFollowPosTween != null)
			camFollowPosTween.cancel();

		if (gf != null && SONG.notes[curSection].gfSection)
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
		if (gameCameraZoomTween != null)
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
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.001;
				}
		}
	}
}
