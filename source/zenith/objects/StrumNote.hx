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
		playAnim("static");

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
		@:bypassAccessor active = anim != "static";
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
	inline private function finishCallbackFunc(anim:String = "")
	{
		if (!playable && active)
		{
			@:bypassAccessor active = false;
			color = 0xffffffff;

			animation.play("static", true);

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

		var len = notes.length;
		for (i in 0...len)
		{
			notes[i].destroy();
		}

		var len = sustains.length;
		for (i in 0...len)
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

		var _songPosition = Main.conductor.songPosition, _songSpeed = Gameplay.instance.songSpeed, _notePosition, _scrollMult = scrollMult,
			_note = NoteskinHandler.idleNote, _idleNote = NoteskinHandler.idleNote,
		    len = sustains.length;

		for (i in 0...len)
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

				if (_holding = @:bypassAccessor animation.curAnim.name == "confirm"
					&& _songPosition > _notePosition
					&& _songPosition < _notePosition + (_note.length - 50))
				{
					//_note.clipRect = ; Will do it tomorrow.
					_onSustainHold();
				}
			}

			_note.distance = 0.45 * (_songPosition - _notePosition) * _songSpeed;
			_note._updateNoteFrame(this);

			@:bypassAccessor
			{
				_note.x = x
					+ (initial_width - Std.int(@:bypassAccessor _note.width) >> 1)
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
		var _songPosition = Main.conductor.songPosition, _songSpeed = Gameplay.instance.songSpeed,
			_notePosition, _hittablePosition = _hittableNote.position, _noteHitbox = Std.int(250 / _songSpeed), _scrollMult = scrollMult,
			_note = NoteskinHandler.idleNote, _idleNote = NoteskinHandler.idleNote,
		    len = notes.length, _hittableAlreadyHit = _hittableNote.state == NoteState.HIT, _hittableValid = _hittableNote != _idleNote;

		for (i in 0...len)
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
						_onNoteHit(_hittableNote);
					}
				}
				else
				{
					if (_hittableValid)
					{
						if (_songPosition - _hittablePosition > _noteHitbox)
						{
							_hittableNote.state = NoteState.MISS;
							_onNoteMiss(false);
							_hittableNote = _idleNote;
						}
					}
					else
					{
						if (_notePosition - _songPosition < _noteHitbox
							|| (_hittableAlreadyHit || _hittablePosition > _notePosition))
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
				_note.x = x
					+ ((_scrollMult < 0 ? -_scrollMult : _scrollMult) * _note.distance) * FlxMath.fastCos(FlxAngle.asRadians(_note.direction - 90));
				_note.y = y
					+ (_scrollMult * _note.distance) * FlxMath.fastSin(FlxAngle.asRadians(_note.direction - 90));
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
			Main.hscript.callFromAllScripts('setupNoteData', note);
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
				Main.hscript.callFromAllScripts('setupSustainData', sustain);
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
		playAnim("pressed");

		var _idleNote = NoteskinHandler.idleNote;

		if (_hittableNote != _idleNote)
		{
			_hittableNote.hit();
			_hittableNote.isInPool = true;
			_notePool.push(_hittableNote);
			_onNoteHit(_hittableNote);
			_hittableNote = _idleNote;
		}
	}

	public function handleRelease()
	{
		playAnim("static");

		if (_holding)
		{
			_onNoteMiss(true);
			_holding = false;
		}
	}

	function _onNoteHit(note:NoteObject):Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteHit", noteData);
		#end

		playAnim("confirm");

		var game = Gameplay.instance;

		game.health += 0.045 * (playable ? 1.0 : -1.0);

		if (playable)
		{
			game.score += 350;
			++game.combo;
			var hitDiff = note.position - Main.conductor.songPosition;
			game.accuracy_left += (hitDiff < 0.0 ? -hitDiff : hitDiff) > 83.35 ? 0.75 : 1.0;
			++game.accuracy_right;
			game.hudGroup?.updateRatings();
		}

		if (!Gameplay.noCharacters && parent.targetCharacter != null)
		{
			parent.targetCharacter.playAnim(parent.singPrefix + parent.singAnimations[noteData] + parent.singSuffix);
			parent.targetCharacter.holdTimer = 0.0;
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onNoteHitPost", note);
		#end

		if (game.hudGroup != null)
		{
			game.hudGroup.updateScoreText();
			game.hudGroup.updateIcons();
		}
	}

	function _onSustainHold():Void
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onHold", noteData);
		#end

		playAnim("confirm");

		Gameplay.instance.health += FlxG.elapsed * (playable ? 0.125 : -0.125);

		var char = parent.targetCharacter;

		if (!Gameplay.noCharacters && char != null)
		{
			if (Gameplay.stillCharacters)
				char.playAnim(parent.singPrefix + parent.singAnimations[noteData]);
			else
			{
				// This shit is similar to amazing engine's character hold fix, but better

				var charAnim = char.animation.curAnim;

				if (charAnim.name == parent.singPrefix + parent.singAnimations[noteData] + parent.missSuffix)
					char.playAnim(parent.singPrefix + parent.singAnimations[noteData]);

				// Prefixing shit actually made this smaller lmao
				if (charAnim.curFrame > (char.stillCharacterFrame == -1 ? charAnim.frames.length : char.stillCharacterFrame))
					@:privateAccess charAnim.curFrame = (char.stillCharacterFrame == -1 ? charAnim.frames.length
						- 2 : char.stillCharacterFrame
						- 1);
			}

			char.holdTimer = 0;
		}

		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts("onHoldPost", noteData);
		#end
	}

	function _onNoteMiss(sustain:Bool)
	{
		#if SCRIPTING_ALLOWED
		Main.hscript.callFromAllScripts(!sustain ? 'onNoteMiss' : 'onSustainMiss', noteData);
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
		Main.hscript.callFromAllScripts(!sustain ? 'onNoteMissPost' : 'onSustainMissPost', noteData);
		#end
	}
}
