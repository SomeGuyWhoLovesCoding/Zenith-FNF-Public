package zenith.objects;

class Strumline extends FlxBasic
{
	public var keys(default, set):Int;

	function set_keys(value:Int):Int
	{
		for (i in 0...value)
		{
			m = members[i];
			if (m == null)
			{
				var strumNote = new StrumNote(i, lane);
				strumNote.scale.x = strumNote.scale.y = scale;
				strumNote.parent = this;
				members[i] = strumNote;
			}
			else
			{
				m.angle = NoteBase.angleArray[m.noteData];
			}
		}

		if (value <= keys)
		{
			members.resize(value);
		}

		moveX(x);
		moveY(y);
		return keys = value;
	}

	public var lane:Int = 0;
	public var player:Bool = false;
	public var downScroll:Bool = false;

	public var x(default, set):Float;

	function set_x(value:Float):Float
	{
		moveX(value);
		return x = value;
	}

	public var y(default, set):Float;

	function set_y(value:Float):Float
	{
		moveY(value);
		return y = value;
	}

	public var alpha(default, set):Float;

	function set_alpha(value:Float):Float
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

	public var gap(default, set):Float;

	function set_gap(value:Float):Float
	{
		if (members.length == 0)
			return gap;

		gap = value;
		moveX(x);

		return gap = value;
	}

	public var scale(default, set):Float;

	function set_scale(value:Float):Float
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

	public function new(keys:Int = 4, lane:Int = 0, playable:Bool = false):Void
	{
		super();

		this.lane = lane;
		this.keys = keys;
		gap = 112.0;
		scale = 0.7;
		this.playable = playable;

		// Default strumline positions
		x = (y = 60.0) + ((FlxG.width * 0.5587511111112) * lane);
	}

	public function reset():Strumline
	{
		keys = 4;
		gap = 112.0;
		scale = 0.7;

		// Default strumline positions
		x = (y = 60.0) + ((FlxG.width * 0.5587511111112) * lane);

		return this;
	}

	var m:StrumNote;
	override function update(elapsed:Float)
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			m = members[i];
			if (m.exists && m.active)
			{
				m.update(elapsed);
			}
		}
	}

	override function draw():Void
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			m = members[i];
			if (m.exists && m.visible && m.alpha != 0.0)
			{
				m.draw();
			}
		}
	}

	public function moveX(x:Float):Void
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			members[i].x = x + (gap * i);
		}
	}

	public function moveY(y:Float):Void
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
}
