package zenith;

import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;

import sys.thread.Thread;
import sys.thread.Mutex;

using StringTools;

@:access(zenith.objects.HUDGroup)

class Gameplay extends MusicBeatState
{
	public var strumlines:FlxTypedGroup<Strumline>;
	public var notes:FlxTypedGroup<Note>;
	public var sustains:FlxTypedGroup<SustainNote>;

	// Health stuff
	private var hudGroup(default, null):HUDGroup;
	public var health:Float = 1.0;

	// Score text stuff
	public var score:Float = 0.0;
	public var misses:Float = 0.0;

	public var accuracy_left:Float = 0.0;
	public var accuracy_right:Float = 0.0;

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

	private var keybinds(default, null):Array<flixel.input.keyboard.FlxKey> = [A, S, UP, RIGHT];

	private var singAnimations(default, null):Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	static public var instance:Gameplay = null;

	public var events:Emitter = new Emitter();

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

		newNote = (note:(Note)) ->
		{
			note.scale.x = note.scale.y = 0.7;
			note.setFrame(Paths.regularNoteFrame);

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNote('newNote', note);
			#end
		}

		setupNoteData = (chartNoteData:(Array<(Float)>)) ->
		{
			if (chartNoteData[0] < 0.0 || chartNoteData[3] < 0) // Don't spawn a note with negative time or lane
				return;

			var note:(Note) = notes.recycle((Note));

			#if SCRIPTING_ALLOWED
			for (script in scriptList.keys())
			{
				try
				{
					if (scriptList.get(script).interp.variables.exists('setupNoteData'))
						(scriptList.get(script).interp.variables.get('setupNoteData'))(note, chartNoteData);
				}
				catch (e)
				{
					HScriptSystem.error(e);
				}
			}
			#end

			note.alpha = 1.0;
			note.y = -2000.0;
			note.wasHit = note.tooLate = false;

			note.strumTime = chartNoteData[0];
			note.noteData = Std.int(chartNoteData[1]);
			note.sustainLength = Std.int(chartNoteData[2]) - 32;
			note.lane = Std.int(chartNoteData[3]) % strumlineCount;
			note.multiplier = Std.int(chartNoteData[4]);

			note.strum = strumlines.members[note.lane].members[note.noteData];

			note.color = NoteBase.colorArray[note.noteData];
			note.angle = NoteBase.angleArray[note.noteData];

			if (note.sustainLength > 32.0) // Don't spawn too short sustain notes
			{
				events.emit(SignalEvent.SUSTAIN_SETUP, chartNoteData);
			}

			#if SCRIPTING_ALLOWED
			for (script in scriptList.keys())
			{
				try
				{
					if (scriptList.get(script).interp.variables.exists('setupNoteDataPost'))
						(scriptList.get(script).interp.variables.get('setupNoteDataPost'))(note, chartNoteData);
				}
				catch (e)
				{
					HScriptSystem.error(e);
				}
			}
			#end
		}

		newSustain = (sustain:(SustainNote)) ->
		{
			sustain.scale.x = sustain.scale.y = 0.7;
			sustain.downScroll = downScroll;
			sustain.setFrame(Paths.sustainNoteFrame);
			sustain.offset.x = -0.5 * ((sustain.frameWidth * 0.7) - sustain.frameWidth);
			sustain.origin.x = sustain.frameWidth * 0.5;
			sustain.origin.y = sustain.offset.y = 0.0;

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallSustain('newSustain', sustain);
			#end
		}

		setupSustainData = (chartNoteData:(Array<(Float)>)) ->
		{
			var sustain:(SustainNote) = sustains.recycle((SustainNote));

			#if SCRIPTING_ALLOWED
			for (script in scriptList.keys())
			{
				try
				{
					if (scriptList.get(script).interp.variables.exists('setupSustainData'))
						(scriptList.get(script).interp.variables.get('setupSustainData'))(sustain, chartNoteData);
				}
				catch (e)
				{
					HScriptSystem.error(e);
				}
			}
			#end

			sustain.alpha = 0.6; // Definitive alpha, default
			sustain.y = -2000;
			sustain.holding = sustain.missed = false;

			sustain.strumTime = chartNoteData[0];
			sustain.noteData = Std.int(chartNoteData[1]);
			sustain.length = chartNoteData[2] - 32.0;
			sustain.lane = Std.int(chartNoteData[3]);

			sustain.strum = strumlines.members[sustain.lane].members[sustain.noteData];

			sustain.color = NoteBase.colorArray[sustain.noteData];

			#if SCRIPTING_ALLOWED
			for (script in scriptList.keys())
			{
				try
				{
					if (scriptList.get(script).interp.variables.exists('setupSustainDataPost'))
						(scriptList.get(script).interp.variables.get('setupSustainDataPost'))(sustain, chartNoteData);
				}
				catch (e)
				{
					HScriptSystem.error(e);
				}
			}
			#end
		}

		onNoteHit = (note:(Note)) ->
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNote('onNoteHit', note);
			#end

			note.strum.playAnim('confirm');

			var multiplier:Int = FlxMath.maxInt(note.multiplier, 1); // Avoid calling FlxMath.maxInt 4 times

			health += (0.045 * multiplier) * (note.strum.playable ? 1.0 : -1.0);

			if (note.strum.playable)
			{
				score += 350.0 * multiplier;
				accuracy_left += (Math.abs(note.strumTime - Conductor.songPosition) > 83.35 ? 0.75 : 1.0) * multiplier;
				accuracy_right += multiplier;
			}

			if (!noCharacters)
			{
				var char:Character = (note.strum.playable ? bf : (note.gfNote ? gf : dad));

				if (null != char)
				{
					char.playAnim(singAnimations[note.noteData]);
					char.holdTimer = 0.0;
				}
			}

			note.wasHit = !(note.exists = false);

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNote('onNoteHitPost', note);
			#end

			hudGroup.updateScoreText();
		}

		onNoteMiss = (note:(Note)) ->
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNote('onNoteMiss', note);
			#end

			note.tooLate = true;
			note.alpha = 0.6;

			var multiplier:Int = FlxMath.maxInt(note.multiplier, 1); // Avoid calling FlxMath.maxInt 4 times

			health -= 0.045 * multiplier;
			score -= 100.0 * multiplier;
			misses += multiplier;
			accuracy_right += multiplier;

			if (!noCharacters)
			{
				bf.playAnim(singAnimations[note.noteData] + 'miss');
				bf.holdTimer = 0.0;
			}

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallNote('onNoteMissPost', note);
			#end

			hudGroup.updateScoreText();
		}

		onHold = (sustain:(SustainNote)) ->
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallSustain('onHold', sustain);
			#end

			sustain.strum.playAnim('confirm');

			health += 0.00275 * (sustain.strum.playable ? 1.0 : -1.0);

			if (!noCharacters)
			{
				var char:Character = (sustain.strum.playable ? bf : (sustain.gfNote ? gf : dad));

				if (null != char)
				{
					if (Gameplay.stillCharacters)
					{
						char.playAnim(singAnimations[sustain.noteData]);
					}
					else
					{
						// This shit is similar to amazing engine's character hold fix, but better

						if (char.animation.curAnim.name == singAnimations[sustain.noteData] + 'miss')
							char.playAnim(singAnimations[sustain.noteData]);

						if (char.animation.curAnim.curFrame > (char.stillCharacterFrame == -1 ? char.animation.curAnim.frames.length : char.stillCharacterFrame))
							char.animation.curAnim.curFrame = (char.stillCharacterFrame == -1 ? char.animation.curAnim.frames.length - 2 : char.stillCharacterFrame - 1);
					}

					char.holdTimer = 0.0;
				}
			}

			sustain.holding = true;

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCallSustain('onHoldPost', sustain);
			#end
		}

		onRelease = (noteData:(Int)) ->
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

		handleNoteHit = (key:(Int)) ->
		{
			for (n in notes.members)
			{
				if ((n.strum.playable && n.noteData == key) &&
					(!n.wasHit && !n.tooLate) && Math.abs(Conductor.songPosition - n.strumTime) < 166.7)
				{
					events.emit(SignalEvent.NOTE_HIT, n);
					break;
				}
			}
		}

		handleNoteRelease = (key:(Int)) ->
		{
			for (s in sustains.members)
			{
				if ((s.strum.playable && s.noteData == key) && (s.holding && !s.missed) &&
					Conductor.songPosition <= (s.strumTime + s.length) - (Conductor.stepCrochet * 0.875))
				{
					events.emit(SignalEvent.NOTE_RELEASE, s.noteData);
					s.missed = !(s.holding = false);
					s.alpha = 0.3;
				}
			}
		}

		sortShit = () ->
		{
			notes.members.sort((a:(Note), b:(Note)) -> Std.int(a.strumTime - b.strumTime));
			sustains.members.sort((a:(SustainNote), b:(SustainNote)) -> Std.int(a.strumTime - b.strumTime));
		}

		updateNotes = () ->
		{
			for (i in 0...notes.members.length)
			{
				var note:(Note) = notes.members[i];
				if (note.exists)
				{
					var dir:Float = FlxAngle.asRadians(note.direction - 90.0);
					note.distance = 0.45 * (Conductor.songPosition - note.strumTime) * songSpeed;
					note.x = note.strum.x + note.offsetX + (-Math.abs(note.strum.scrollMult) * note.distance) * FlxMath.fastCos(dir);
					note.y = note.strum.y + note.offsetY + (note.strum.scrollMult * note.distance) * FlxMath.fastSin(dir);

					if (Conductor.songPosition >= note.strumTime + (750.0 / songSpeed)) // Remove them if they're offscreen
						note.exists = false;

					// For note hits

					if (note.strum.playable)
					{
						if (cpuControlled)
						{
							if (Conductor.songPosition >= note.strumTime)
							{
								events.emit(SignalEvent.NOTE_HIT, note);
							}
						}

						if (Conductor.songPosition >= note.strumTime + (200.0 / songSpeed) && (!note.wasHit && !note.tooLate))
						{
							events.emit(SignalEvent.NOTE_MISS, note);
						}
					}
					else
					{
						if (Conductor.songPosition >= note.strumTime)
						{
							events.emit(SignalEvent.NOTE_HIT, note);
						}
					}
				}
			}
		}

		updateSustains = () ->
		{
			for (i in 0...sustains.members.length)
			{
				var sustain:(SustainNote) = sustains.members[i];
				if (sustains.exists)
				{
					var dir:Float = FlxAngle.asRadians(sustain.direction - 90.0);
					sustain.distance = 0.45 * (Conductor.songPosition - sustain.strumTime) * songSpeed;

					sustain.x = (sustain.strum.x + sustain.offsetX + (-Math.abs(sustain.strum.scrollMult) * sustain.distance) * FlxMath.fastCos(dir)) +
						((initialStrumWidth - (sustain.frameWidth * sustain.scale.x)) * 0.5);

					sustain.y = (sustain.strum.y + sustain.offsetY + (sustain.strum.scrollMult * sustain.distance) * FlxMath.fastSin(dir)) +
						(initialStrumHeight * 0.5);

					// For hold input

					if (Conductor.songPosition >= (sustain.strumTime + sustain.length) + (750.0 / songSpeed))
						sustain.holding = sustain.missed = sustain.exists = false;

					if (sustain.strum.playable)
					{
						if (!sustain.missed && Conductor.songPosition <= (sustain.strumTime + sustain.length) - (Conductor.stepCrochet * 0.875) &&
							!sustain.missed && Conductor.songPosition >= sustain.strumTime)
						{
							if (holdArray[sustain.noteData])
							{
								events.emit(SignalEvent.NOTE_HOLD, sustain);
							}
						}
					}
					else
					{
						if (Conductor.songPosition <= (sustain.strumTime + sustain.length) - (Conductor.stepCrochet * 0.875) &&
							Conductor.songPosition >= sustain.strumTime)
						{
							events.emit(SignalEvent.NOTE_HOLD, sustain);
						}
					}
				}
			}
		}

		processSpawning = () ->
		{
			while (null != SONG.noteData[currentNoteId])
			{
				// Avoid redundant array access
				var note = SONG.noteData[currentNoteId];

				if (Conductor.songPosition < note[0] - (1950.0 / songSpeed))
					break;

				events.emit(SignalEvent.NOTE_SETUP, note);

				currentNoteId++;
			}
		}

		onKeyDown = (keyCode:(Int), keyModifier:(Int)) ->
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Ints('onKeyDown', keyCode, keyModifier);
			#end

			var key:Int = inputKeybinds.indexOf(keyCode);

			if (cpuControlled || key == -1 || !generatedMusic || holdArray[key])
				return;
			
			var strum:(StrumNote) = strumlines.members[strumlines.members.length-1].members[key];

			if (strum.animation.curAnim.name != 'confirm')
				strum.playAnim('pressed');

			handleNoteHit(key);

			holdArray[key] = true;

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Ints('onKeyDownPost', keyCode, keyModifier);
			#end
		}

		onKeyUp = (keyCode:(Int), keyModifier:(Int)) ->
		{
			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Ints('onKeyUp', keyCode, keyModifier);
			#end

			var key:Int = inputKeybinds.indexOf(keyCode);

			if (cpuControlled || key == -1 || !generatedMusic || !holdArray[key])
				return;

			var strum:(StrumNote) = strumlines.members[strumlines.members.length-1].members[key];

			if (strum.animation.curAnim.name == 'confirm' ||
				strum.animation.curAnim.name == 'pressed')
				strum.playAnim('static');

			handleNoteRelease(key);

			holdArray[key] = false;

			#if SCRIPTING_ALLOWED
			Main.optUtils.scriptCall2Ints('onKeyUpPost', keyCode, keyModifier);
			#end
		}

		onGameplayUpdate = (elapsed:Float) ->
		{
			// Don't remove this.
			hudCameraBelow.x = hudCamera.x;
			hudCameraBelow.y = hudCamera.y;
			hudCameraBelow.angle = hudCamera.angle;
			hudCameraBelow.alpha = hudCamera.alpha;
			hudCameraBelow.zoom = hudCamera.zoom;

			Conductor.songPosition += elapsed * 1000.0;

			processSpawning();
			updateNotes();
			updateSustains();
		}

		events.on(SignalEvent.NOTE_NEW, newNote);
		events.on(SignalEvent.NOTE_SETUP, setupNoteData);
		events.on(SignalEvent.NOTE_HIT, onNoteHit);
		events.on(SignalEvent.NOTE_MISS, onNoteMiss);
		events.on(SignalEvent.NOTE_HOLD, onHold);
		events.on(SignalEvent.NOTE_RELEASE, onRelease);
		events.on(SignalEvent.SUSTAIN_NEW, newSustain);
		events.on(SignalEvent.SUSTAIN_SETUP, setupSustainData);
		events.on(SignalEvent.GAMEPLAY_UPDATE, onGameplayUpdate);

		Main.game.onKeyDown.on(SignalEvent.KEY_DOWN, onKeyDown);
		Main.game.onKeyUp.on(SignalEvent.KEY_UP, onKeyUp);
	}

	override function update(elapsed:Float):Void
	{
		// Song creation

		//trace(threadsCompleted);

		if (Main.ENABLE_MULTITHREADING)
		{
			if (threadsCompleted == 0)
			{
				startOtherThreads();
				threadsCompleted++;
			}

			if (threadsCompleted == 7)
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

					threadsCompleted = 8;
				});
			}

			if (threadsCompleted == 8)
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
			}
		}

		if (!generatedMusic)
			return;

		super.update(elapsed);

		events.emit(SignalEvent.GAMEPLAY_UPDATE, elapsed);
	}

	var initialStrumWidth:Float = 112.0;
	var initialStrumHeight:Float = 112.0;
	var currentNoteId:Int = 0;

	public var onGameplayUpdate:(Float)->(Void) = null;

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

	var lock = new Mutex();
	var threadsCompleted:Int = -1;

	var loadingTimestamp:Float;
	inline private function generateSong(name:String, diff:String):Void
	{
		loadingTimestamp = haxe.Timer.stamp();

		curSong = name;
		curDifficulty = diff;

		if (Main.ENABLE_MULTITHREADING)
		{
			Thread.create(() ->
			{
				trace('Parsing chart data from song json...');

				var preloadName:String = curSong + (curDifficulty != '' ? '-$curDifficulty' : '');
				try
				{
					// Chart preloader
					if (ChartPreloader.container.exists(preloadName))
					{
						trace('Nvm we found the data in ChartPreloader - YIPPEE!!!');
						SONG = ChartPreloader.container.get(preloadName);
					}
					else
						SONG = Song.loadFromJson(curSong + '/' + curSong + curDifficulty);

					threadsCompleted++;
				}
				catch (e)
				{
					trace('Chart file "$preloadName" doesn\'t exist.');
				}
			});
		}
		else
		{
			FlxG.maxElapsed = FlxG.elapsed;

			trace('Parsing chart data from song json...');

			var preloadName:String = curSong + (curDifficulty != '' ? '-$curDifficulty' : '');

			// Chart preloader
			if (ChartPreloader.container.exists(preloadName))
			{
				trace('Nvm we found the data in ChartPreloader - YIPPEE!!!');
				SONG = ChartPreloader.container.get(preloadName);
			}
			else
			{
				SONG = Song.loadFromJson(curSong + '/' + curSong + curDifficulty);
			}

			trace('Loaded ${SONG.noteData.length} notes! Now time to load more stuff here...');

			Conductor.mapBPMChanges(SONG);

			// What happens if you load a song with a bpm of under 10 or over 10000? Limit it.
			SONG.info.bpm = Math.min(Math.max(SONG.info.bpm, 10.0), 10000.0);

			Conductor.changeBPM(SONG.info.bpm);

			if (null == SONG.info.spectator) // Fix gf (for vanilla charts)
				SONG.info.spectator = 'gf';

			if (null == SONG.info.offset || SONG.info.offset < 0) // Fix offset
				SONG.info.offset = 0;

			strumlineCount = null == SONG.info.strumlines ? 2 : SONG.info.strumlines;

			songSpeed = SONG.info.speed;

			curStage = SONG.info.stage;

			if (curStage == null || curStage == '') // Fix stage (For vanilla charts)
				curStage = 'stage';

			var stageData:StageData.StageFile = null;

			trace('Loading stage...');

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

			trace('Done loading stage!');

			lock.acquire();

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

			trace('Loading gf...');

			gf = new Character(0, 0, SONG.info.spectator);
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
			gfGroup.add(gf);

			lock.acquire();

			trace('Done loading gf!');

			trace('Loading dad...');

			dad = new Character(0, 0, SONG.info.player2);
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
			dadGroup.add(dad);

			lock.acquire();

			trace('Done loading dad!');

			trace('Loading bf...');

			bf = new Character(0, 0, SONG.info.player1, true);
			bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
			bfGroup.add(bf);

			lock.acquire();

			trace('Done loading bf!');

			trace('Loading inst audio file...');
			inst = new FlxSound();
			inst.loadEmbedded(Paths.inst(SONG.song));

			trace('Done loading inst!');

			lock.acquire();

			inst.onComplete = endSong;
			FlxG.sound.list.add(inst);
			inst.looped = false;

			threadsCompleted++;
			lock.release();
			
			if (SONG.info.needsVoices)
			{
				trace('Loading voices audio file...');
				voices = new FlxSound();
				voices.loadEmbedded(Paths.voices(SONG.song));

				trace('Done loading voices!');

				lock.acquire();

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

	private function startOtherThreads():Void
	{
		if (!Main.ENABLE_MULTITHREADING)
			return;

		trace('Loaded ${SONG.noteData.length} notes! Now time to load more stuff here...');

		Conductor.mapBPMChanges(SONG);

		// What happens if you load a song with a bpm of under 10 or over 10000? Limit it.
		SONG.info.bpm = Math.min(Math.max(SONG.info.bpm, 10.0), 10000.0);

		Conductor.changeBPM(SONG.info.bpm);

		if (null == SONG.info.spectator) // Fix gf (for vanilla charts)
			SONG.info.spectator = 'gf';

		if (null == SONG.info.offset || SONG.info.offset < 0) // Fix offset
			SONG.info.offset = 0;

		strumlineCount = null == SONG.info.strumlines ? 2 : SONG.info.strumlines;

		songSpeed = SONG.info.speed;

		curStage = SONG.info.stage;

		if (curStage == null || curStage == '') // Fix stage (For vanilla charts)
			curStage = 'stage';

		var stageData:StageData.StageFile = null;

		Thread.create(() ->
		{
			trace('Loading stage...');

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

			trace('Done loading stage!');

			lock.acquire();

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

			threadsCompleted++;
			lock.release();
		});

		Thread.create(() ->
		{
			trace('Loading gf...');

			gf = new Character(0, 0, SONG.info.spectator);
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
			gfGroup.add(gf);

			trace('Done loading gf!');

			lock.acquire();

			threadsCompleted++;
			lock.release();
		});

		Thread.create(() ->
		{
			trace('Loading dad...');

			dad = new Character(0, 0, SONG.info.player2);
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
			dadGroup.add(dad);

			trace('Done loading dad!');

			lock.acquire();

			threadsCompleted++;
			lock.release();
		});

		Thread.create(() ->
		{
			trace('Loading bf...');

			bf = new Character(0, 0, SONG.info.player1, true);
			bfGroup = new FlxSpriteGroup(BF_X, BF_Y);
			bfGroup.add(bf);

			trace('Done loading bf!');

			lock.acquire();

			threadsCompleted++;
			lock.release();
		});

		Thread.create(() ->
		{
			trace('Loading inst audio file...');
			inst = new FlxSound();
			inst.loadEmbedded(Paths.inst(SONG.song));

			trace('Done loading inst!');

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
				trace('Loading voices audio file...');
				voices = new FlxSound();
				voices.loadEmbedded(Paths.voices(SONG.song));

				trace('Done loading voices!');

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

	static public var strumlineCount:Int = 2;
	static public var playablelineConfiguration:Array<Bool> = [false, true];
	public function generateStrumline(player:Int = 0):Void
	{
		// If the array's length is not above or equal to the strumline count, compensate for it
		while (playablelineConfiguration.length <= strumlineCount)
		{
			playablelineConfiguration.push(false);
		}

		var strumline = new Strumline(4, player, playablelineConfiguration[player]);
		strumlines.add(strumline);
	}

	var lastStepHit:Int = -1;
	override function stepHit():Void
	{
		super.stepHit();

		if (!startedCountdown || songEnded)
			return;

		if(curStep == lastStepHit)
			return;

		if ((null != inst || null != voices))
		{
			var off:Float = Conductor.songPosition + SONG.info.offset;
			if ((inst.time < off - 20.0 || inst.time > off + 20.0)
				|| (voices.time < off - 20.0 || voices.time > off + 20.0))
			{
				Conductor.songPosition = inst.time - SONG.info.offset;
				voices.time = Conductor.songPosition + SONG.info.offset;
			}
		}

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit():Void
	{
		super.beatHit();

		if(lastBeatHit >= curBeat)
			return;

		dance(curBeat);

		if (curBeat % 4 == 0)
			addCameraZoom();

		sortShit();

		lastBeatHit = curBeat;
	}

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
		gameCameraZoomTween = zoomTweenFunction(FlxG.camera, defaultCamZoom);
		hudCamera.zoom += value2;
		hudCameraZoomTween = zoomTweenFunction(hudCamera, 1);
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

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCall('startCountdown');
		#end
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

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCall('startSong');
		#end
	}

	public function endSong():Void
	{
		songEnded = true;

		if (null != inst)
			inst.stop();

		if (null != voices)
			voices.stop();

		if (null != hudGroup.timeTxt)
			hudGroup.timeTxt.visible = false;

		switchState(new WelcomeState());

		#if SCRIPTING_ALLOWED
		Main.optUtils.scriptCall('endSong');
		#end
	}

	// Camera functions

	private function moveCamera(whatCharacter:(Character)):Void
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

		#if SCRIPTING_ALLOWED
		for (script in scriptList.keys())
		{
			try
			{
				if (scriptList.get(script).interp.variables.exists('moveCamera'))
					(scriptList.get(script).interp.variables.get('moveCamera'))(whatCharacter);
			}
			catch (e)
			{
				HScriptSystem.error(e);
			}
		}
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
				gf.active = gf.visible = false;
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

	// Real input system!!

	public var inputKeybinds:Array<(lime.ui.KeyCode)> = [];

	// The extra 5 values are used to check if a key is just pressed for extra keys aswell
	public var holdArray(default, null):Array<Bool> = [false, false, false, false, false, false, false, false, false];

	public var onKeyDown:((Int), (Int))->(Void) = null;
	public var onKeyUp:((Int), (Int))->(Void) = null;

	// Preferences stuff (Also for scripting)

	var strumYTweens(default, null):Map<StrumNote, FlxTween> = [];
	var strumScrollMultTweens(default, null):Map<StrumNote, FlxTween> = [];
	public function changeDownScroll(whichStrum:Int = -1, tween:Bool = false, tweenLength:Float = 1.0):Void
	{
		// Strumline
		var strumline = strumlines.members[whichStrum];
		for (strum in strumline.members)
		{
			if (strum.player == whichStrum || whichStrum == -1)
			{
				if (tween && tweenLength != 0.0)
				{
					var actualScrollMult = strum.scrollMult;
					actualScrollMult = -actualScrollMult;

					var scrollTween = strumScrollMultTweens.get(strum);
					var yTween = strumYTweens.get(strum);

					if (null != scrollTween)
						scrollTween.cancel();

					strumScrollMultTweens.set(strum, FlxTween.tween(strum, {scrollMult: strum.scrollMult > 0.0 ? -1.0 : 1.0}, Math.abs(tweenLength), {ease: FlxEase.quintOut}));

					if (null != yTween)
						yTween.cancel();

					strumYTweens.set(strum, FlxTween.tween(strum, {y: actualScrollMult < 0.0 ? FlxG.height - 160.0 : 60.0}, Math.abs(tweenLength), {ease: FlxEase.quintOut}));
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
		events.off(SignalEvent.NOTE_NEW, newNote);
		events.off(SignalEvent.NOTE_SETUP, setupNoteData);
		events.off(SignalEvent.NOTE_HIT, onNoteHit);
		events.off(SignalEvent.NOTE_MISS, onNoteMiss);
		events.off(SignalEvent.NOTE_HOLD, onHold);
		events.off(SignalEvent.NOTE_RELEASE, onRelease);
		events.off(SignalEvent.SUSTAIN_NEW, newSustain);
		events.off(SignalEvent.SUSTAIN_SETUP, setupSustainData);
		events.off(SignalEvent.GAMEPLAY_UPDATE, onGameplayUpdate);

		Main.game.onKeyDown.off(SignalEvent.KEY_DOWN, onKeyDown);
		Main.game.onKeyUp.off(SignalEvent.KEY_UP, onKeyUp);

		super.destroy();
	}

	private var newNote:(Note)->(Void) = null;
	private var newSustain:(SustainNote)->(Void) = null;

	private var setupNoteData:(Array<(Float)>)->(Void) = null;
	private var setupSustainData:(Array<(Float)>)->(Void) = null;

	public var onNoteHit:(Note)->(Void) = null;
	public var onNoteMiss:(Note)->(Void) = null;
	public var onHold:(SustainNote)->(Void) = null;
	public var onRelease:(Int)->(Void) = null;

	var handleNoteHit:(Int)->(Void) = null;
	var handleNoteRelease:(Int)->(Void) = null;
	var sortShit:()->(Void) = null;

	var updateNotes:()->(Void) = null;
	var updateSustains:()->(Void) = null;
	var processSpawning:()->(Void) = null;
}
