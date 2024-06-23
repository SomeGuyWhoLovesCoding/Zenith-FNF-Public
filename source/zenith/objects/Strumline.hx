package zenith.objects;

@:access(zenith.Gameplay)
@:access(zenith.system.NoteSpawner)
@:access(zenith.system.SustainNoteSpawner)
@:access(zenith.objects.StrumNote)
@:access(Stack)
class Strumline extends FlxBasic
{
	public var keys(default, set):UInt8;

	function set_keys(value:UInt8):UInt8
	{
		for (i in 0...value)
		{
			m = members[i];

			if (m == null)
			{
				var strumNote = new StrumNote(i, lane);
				strumNote.scale.x = strumNote.scale.y = scale;
				strumNote.parent = this;
				strumNote.index = i * lane;
				strumNote._reset();
				members[i] = m = strumNote;
			}
			else
			{
				m.angle = NoteBase.angleArray[m.noteData];
			}

			m.index = i * lane;
		}

		if (value <= keys)
		{
			members.resize(value);
		}

		moveX(x);
		moveY(y);
		return keys = value;
	}

	public var lane:UInt8 = 0;
	public var player:Bool = false;
	public var downScroll:Bool = false;

	public var x(default, set):Single;

	function set_x(value:Single):Single
	{
		moveX(value);
		return x = value;
	}

	public var y(default, set):Single;

	function set_y(value:Single):Single
	{
		moveY(value);
		return y = value;
	}

	public var alpha(default, set):Single;

	function set_alpha(value:Single):Single
	{
		if (members.length == 0)
			return alpha;

		for (i in 0...members.length)
		{
			members[i].alpha = value;
		}

		return alpha = value;
	}

	public var members:Array<StrumNote> = [];

	public var gap(default, set):Single;

	function set_gap(value:Single):Single
	{
		if (members.length == 0)
			return gap;

		gap = value;
		moveX(x);

		return gap = value;
	}

	public var scale(default, set):Single;

	function set_scale(value:Single):Single
	{
		if (members.length == 0)
			return scale;

		scale = value;

		for (i in 0...members.length)
		{
			members[i].scale.set(scale, scale);
		}

		moveX(x);

		return value;
	}

	public var playable(default, set):Bool;

	function set_playable(value:Bool):Bool
	{
		if (members.length == 0)
			return playable;

		for (i in 0...members.length)
		{
			members[i].playable = value;
		}

		return playable = value;
	}

	public function new(keys:UInt8 = 4, lane:UInt8 = 0, playable:Bool = false):Void
	{
		super();

		this.lane = lane;
		this.keys = keys;
		gap = 112.0;
		scale = 1.0;
		this.playable = playable;

		// Default strumline positions
		x = (y = 60.0) + ((FlxG.width * 0.5587511111112) * lane);
	}

	public function reset():Strumline
	{
		keys = 4;
		gap = 112.0;
		scale = 1.0;

		// Default strumline positions
		x = (y = 60.0) + ((FlxG.width * 0.5587511111112) * lane);

		return this;
	}

	override function update(elapsed:Float) {}

	var m:StrumNote;

	override function draw():Void
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			m = members[i];
			if (m.exists && m.visible && m.alpha != 0.0)
			{
				if (m.active)
					m.update(FlxG.elapsed);
				m.draw();
			}
		}
	}

	public function moveX(x:Single):Void
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			members[i].x = x + (gap * i);
		}
	}

	public function moveY(y:Single):Void
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			members[i].y = y;
		}
	}

	public function clear():Void
	{
		while (members.length != 0)
		{
			members.pop().destroy();
		}
	}

	public function updateHitbox():Void
	{
		for (i in 0...members.length)
		{
			m = members[i];
			m.width = (m.scale.x < 0.0 ? -m.scale.x : m.scale.x) * m.frameWidth;
			m.height = (m.scale.y < 0.0 ? -m.scale.y : m.scale.y) * m.frameHeight;
			m.offset.x = (m.frameWidth * 0.5) - 54;
			m.offset.y = (m.frameHeight * 0.5) - 56;
			m.origin.x = m.offset.x + 54;
			m.origin.y = m.offset.y + 56;
		}
	}

	public dynamic function singAnimations(data:UInt8):String
	{
		switch (data)
		{
			case 0:
				return "singLEFT";
			case 1:
				return "singDOWN";
			case 2:
				return "singUP";
		}
		return "singRIGHT";
	}
}
