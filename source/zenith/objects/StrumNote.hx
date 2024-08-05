package zenith.objects;

import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;

@:access(zenith.objects.NoteObject)
@:access(zenith.Gameplay)
@:access(flixel.FlxCamera)
class StrumNote extends FlxSprite
{
	public var noteData:NoteState.UInt8;
	public var player:NoteState.UInt8;
	public var scrollMult:Float;
	public var playable(default, set):Bool;

	inline private function set_playable(value:Bool):Bool
	{
		animation.finishCallback = value ? null : finishCallbackFunc;
		return playable = value;
	}

	private var initial_width:NoteState.UInt8;
	private var initial_height:NoteState.UInt8;
	private var _holding:Bool;

	public var parent:Strumline;
	public var index:NoteState.UInt8;

	public function new(data:NoteState.UInt8 = 0, plr:NoteState.UInt8 = 0)
	{
		super();

		noteData = data;
		player = plr;

		scrollMult = 1.0;

		_hittableNote = NoteskinHandler.idleNote;

		@:bypassAccessor moves = false;

		var cam = Gameplay.instance.hudCamera;

		if (cam == null)
		{
			return;
		}

		camera = cam;
	}

	inline public function _reset()
	{
		angle = parent.noteAngles[noteData];
		frames = NoteskinHandler.strumNoteAnimationHolder.frames;
		animation.copyFrom(NoteskinHandler.strumNoteAnimationHolder.animation);
		playAnim(STATIC);

		// Note: frameWidth and frameHeight only works for this lmao
		initial_width = frameWidth;
		initial_height = frameHeight;
	}

	override function update(elapsed:Float)
	{
		animation.update(elapsed);
	}

	public function playAnim(anim:String)
	{
		@:bypassAccessor active = anim != STATIC;
		color = !active ? 0xffffffff : parent.noteColors[noteData];

		animation.play(anim, true);

		@:bypassAccessor
		{
			offset.x = (frameWidth >> 1) - 54;
			offset.y = (frameHeight >> 1) - 56;
			origin.x = offset.x + 54;
			origin.y = offset.y + 56;
		}
	}

	override function set_clipRect(rect:FlxRect):FlxRect
	{
		return clipRect = rect;
	}

	// Please don't mess with this function.
	inline private function finishCallbackFunc(anim:String)
	{
		if (!playable && active)
		{
			@:bypassAccessor active = false;
			color = 0xffffffff;

			animation.play(STATIC, true);

			@:bypassAccessor
			{
				offset.x = (frameWidth >> 1) - 54;
				offset.y = (frameHeight >> 1) - 56;
				origin.x = offset.x + 54;
				origin.y = offset.y + 56;
			}
		}
	}

	/*
	 * //! The note system.
	 * //? Explanation: This is organized so that the note members are based on
	 * strumnotes instead of a single array in the note system class.
	 * Doing said method allows for the note system to be much faster
	 * since the group is split to [number of members in the parent strumline] parts,
	 * and you can basically skip array access when you get the hittable note which
	 * allows for much faster inputs under the hood.
	 * Also, the note object class is meant to be small as possible, so there are
	 * only 6 variables in there (excluding the inherited classes).
	 * //? Behavior
	 * It's very simple but it was almost complicated to make.
	 * Basically, it has a target note variable named _hittableNote, which tracks the closest note to the strumnote.
	 * It's now finished.
	 */
	public var notes:Array<NoteObject> = [];
	public var sustains:Array<NoteObject> = [];

	private var _notePool(default, null):Array<NoteObject> = [];
	private var _susPool(default, null):Array<NoteObject> = [];
	private var _hittableNote(default, null):NoteObject; // The target note for the hitreg

	override function draw()
	{
		final oldDefaultCameras = FlxCamera._defaultCameras;

		if (_cameras != null)
		{
			FlxCamera._defaultCameras = _cameras;
		}

		renderSustains();

		if (visible)
		{
			super.draw();
		}

		renderNotes();

		FlxCamera._defaultCameras = oldDefaultCameras;
	}

	override function destroy()
	{
		super.destroy();

		for (i in 0...notes.length)
		{
			notes[i].destroy();
		}

		for (i in 0...sustains.length)
		{
			sustains[i].destroy();
		}
	}

	private function renderSustains()
	{
		if (sustains.length == 0)
		{
			return;
		}

		var _songPosition = Main.conductor.songPosition,
			_songSpeed = Gameplay.instance.songSpeed,
			_notePosition,
			_scrollMult = scrollMult;
		var _note, _idleNote = NoteskinHandler.idleNote;
		var playingConfAnim = animation.curAnim != null && animation.curAnim.name == CONFIRM;

		for (i in 0...sustains.length)
		{
			_note = sustains[i];
			_notePosition = _note.position;

			if (@:bypassAccessor !_note.exists)
			{
				if (!_note.isInPool)
				{
					_note.isInPool = true;
					_susPool.push(_note);
				}

				continue;
			}

			if (_songPosition - _notePosition > _note.length + (500 / _songSpeed))
			{
				@:bypassAccessor _note.exists = false;
			}

			if (_note.visible)
			{
				_note.draw();
			}

			if (_note.state == NoteState.IDLE)
			{
				// Literally the sustain logic system

				if (_holding = playingConfAnim && _songPosition > _notePosition && _songPosition < _notePosition + (_note.length - 50))
				{
					// @:bypassAccessor _note.clipRect = ; Will do it tomorrow.
					_onSustainHold();
				}
			}

			_note.distance = 0.45 * (_songPosition - _notePosition) * _songSpeed;
			_note._updateNoteFrame(this);

			@:bypassAccessor
			{
				_note.x = x
					+ (initial_width - Std.int(_note.width) >> 1)
					+ ((_scrollMult < 0 ? -_scrollMult : _scrollMult) * _note.distance) * FlxMath.fastCos(FlxAngle.asRadians(_note.direction - 90));
				_note.y = y
					+ (initial_height >> 1)
					+ (_scrollMult * _note.distance) * FlxMath.fastSin(FlxAngle.asRadians(_note.direction - 90));
			}
		}
	}

	private function renderNotes()
	{
		if (notes.length == 0)
		{
			return;
		}

		// Variables list (For even faster field access)
		var _songPosition = Main.conductor.songPosition,
			_songSpeed = Gameplay.instance.songSpeed,
			_notePosition,
			_hittablePosition = _hittableNote.position,
			_noteHitbox = Std.int(250 / _songSpeed),
			_scrollMult = scrollMult;
		var _note = NoteskinHandler.idleNote,
			_idleNote = NoteskinHandler.idleNote;
		var _hittableAlreadyHit = _hittableNote.state == NoteState.HIT,
			_hittableValid = _hittableNote != _idleNote;

		for (i in 0...notes.length)
		{
			_note = notes[i];
			_notePosition = _note.position;

			if (@:bypassAccessor !_note.exists)
			{
				if (!_note.isInPool)
				{
					_note.isInPool = true;
					_notePool.push(_note);
				}

				continue;
			}

			if (_songPosition - _notePosition > _note.length + (_noteHitbox << 1))
			{
				@:bypassAccessor _note.exists = false;
			}

			if (_note.visible)
			{
				_note.draw();
			}

			if (_note.state == NoteState.IDLE)
			{
				if (!playable)
				{
					if (_songPosition > _notePosition)
					{
						_note.hit();
						_note.isInPool = true;
						_notePool.push(_note);
						_hitNote(_hittableNote);
					}
				}
				else
				{
					if (_hittableValid)
					{
						if (_songPosition - _hittablePosition > _noteHitbox)
						{
							_hittableNote.state = NoteState.MISS;
							_missNote(false);
							_hittableNote = _idleNote;
						}
					}
					else
					{
						if (_notePosition - _songPosition < _noteHitbox || (_hittableAlreadyHit || _hittablePosition > _notePosition))
						{
							_hittablePosition = _notePosition;
							_hittableNote = _note;
						}
					}
				}
			}

			_note.distance = 0.45 * (_songPosition - _notePosition) * _songSpeed;
			_note._updateNoteFrame(this);

			@:bypassAccessor
			{
				_note.x = x + ((_scrollMult < 0 ? -_scrollMult : _scrollMult) * _note.distance) * FlxMath.fastCos(FlxAngle.asRadians(_note.direction - 90));
				_note.y = y + (_scrollMult * _note.distance) * FlxMath.fastSin(FlxAngle.asRadians(_note.direction - 90));
			}
		}
	}

	private function spawnNote(position:Int, length:NoteState.UInt16)
	{
		var note:NoteObject = _notePool.pop();

		if (note == null)
		{
			note = new NoteObject(false);
			note.color = parent.noteColors[noteData];
			notes.push(note);

			#if SCRIPTING_ALLOWED
			callHScript(SETUP_NOTE_DATA, note);
			#end
		}

		note.isInPool = false;
		note.renew(position, 0);
		note.angle = angle;
		@:bypassAccessor note.exists = true;

		if (length > 20)
		{
			var sustain:NoteObject = _susPool.pop();

			if (sustain == null)
			{
				sustain = new NoteObject(true);
				sustain.color = parent.noteColors[noteData];
				sustains.push(sustain);

				#if SCRIPTING_ALLOWED
				callHScript(SETUP_SUSTAIN_DATA, sustain);
				#end
			}

			sustain.isSustain = true;
			sustain.isInPool = false;
			sustain.renew(position, length);
			sustain.angle = 0;
			@:bypassAccessor sustain.exists = true;
		}
	}

	// The rest of the input stuff, including the hit and miss calls

	public function handlePress()
	{
		playAnim(PRESSED);

		var _idleNote = NoteskinHandler.idleNote;

		if (_hittableNote != _idleNote)
		{
			_hittableNote.hit();
			_hittableNote.isInPool = true;
			_notePool.push(_hittableNote);
			_hitNote(_hittableNote);
			_hittableNote = _idleNote;
		}
	}

	public function handleRelease()
	{
		playAnim(STATIC);

		if (_holding)
		{
			_missNote(true);
			_holding = false;
		}
	}

	function _hitNote(note:NoteObject)
	{
		#if SCRIPTING_ALLOWED
		callHScript(HIT_NOTE, noteData);
		#end

		playAnim(CONFIRM);

		var game = Gameplay.instance;

		game.health += 0.045 * (playable ? 1.0 : -1.0);

		if (playable)
		{
			game.score += 350;
			++game.combo;
			var hitDiff = note.position - Main.conductor.songPosition;
			game.accuracy_left += (hitDiff < 0 ? -hitDiff : hitDiff) > 83.35 ? 0.75 : 1;
			++game.accuracy_right;
			game.hudGroup?.updateRatings();
		}

		var char = parent.targetCharacter;

		if (!Gameplay.noCharacters && char != null)
		{
			char.playAnim(parent.singPrefix + parent.singAnimations[noteData] + parent.singSuffix);
			char.holdTimer = 0;
		}

		#if SCRIPTING_ALLOWED
		callHScript(HIT_NOTE_POST, note);
		#end

		if (game.hudGroup != null)
		{
			game.hudGroup.updateScoreText();
			game.hudGroup.updateIcons();
		}
	}

	function _onSustainHold()
	{
		#if SCRIPTING_ALLOWED
		callHScript(HOLD, noteData);
		#end

		playAnim(CONFIRM);

		Gameplay.instance.health += FlxG.elapsed * (playable ? 0.125 : -0.125);

		var char = parent.targetCharacter;
		var singAnim = parent.singAnimations[noteData];

		if (!Gameplay.noCharacters && char != null)
		{
			// This shit is similar to amazing engine's character hold fix, but better

			var charAnim = char.animation.curAnim;
			var charSingAnimName = parent.singPrefix + singAnim;

			if (charAnim.name == charSingAnimName + parent.missSuffix || charAnim.name == CHAR_IDLE)
				char.playAnim(charSingAnimName);

			// Prefixing shit actually made this smaller lmao
			if (!Gameplay.stillCharacters)
			{
				var charStutterFrame = char.stillCharacterFrame;
				var charStutterFrameEmpty = charStutterFrame == -1;
				var charFramesLen = charAnim.frames.length;

				if (charAnim.curFrame > (charStutterFrameEmpty ? charFramesLen : charStutterFrame))
					charAnim.curFrame = (charStutterFrameEmpty ? charFramesLen - 2 : charStutterFrame - 1);
			}
			else
				charAnim.curFrame = 0;

			char.holdTimer = 0;
		}

		#if SCRIPTING_ALLOWED
		callHScript(HOLD_POST, noteData);
		#end
	}

	function _missNote(sustain:Bool)
	{
		#if SCRIPTING_ALLOWED
		callHScript(!sustain ? MISS_NOTE : RELEASE, noteData);
		#end

		var char = parent.targetCharacter;

		if (!Gameplay.noCharacters && char != null)
		{
			char.playAnim(parent.singPrefix + parent.singAnimations[noteData] + parent.missSuffix);
			char.set_holdTimer(0.0);
		}

		if (playable)
		{
			var game = Gameplay.instance;
			game.combo = 0;
			++game.misses;
			game.hudGroup?.updateRatings();
		}

		#if SCRIPTING_ALLOWED
		callHScript(!sustain ? MISS_NOTE_POST : RELEASE_POST, noteData);
		#end
	}

	// This is at the bottom cause these variables are to help reduce frequent string allocations
	var PRESSED = "pressed";
	var CONFIRM = "confirm";
	var STATIC = "static";

	var CHAR_IDLE = "idle";

	var SETUP_NOTE_DATA = "setupNoteData";
	var SETUP_SUSTAIN_DATA = "setupSustainData";
	var HIT_NOTE = "hitNote";
	var HIT_NOTE_POST = "hitNotePost";
	var MISS_NOTE = "missNote";
	var MISS_NOTE_POST = "missNotePost";
	var HOLD = "hold";
	var HOLD_POST = "hold";
	var RELEASE = "release";
	var RELEASE_POST = "releasePost";
}
