package zenith.objects;

class Strumline extends FlxBasic
{
	public var keys(default, set):Int;

	function set_keys(value:Int):Int
	{
		for (i in 0...value)
		{
			var member = members[i];
			if (member == null)
			{
				var strumNote = new StrumNote(i, lane = startingLane);
				strumNote.scale.x = strumNote.scale.y = scale;
				members[i] = strumNote;
			}
			else
			{
				member.angle = member.angleArray[member.noteData];
				member.color = member.colorArray[member.noteData];
			}
		}
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

	public var gap(default, null):Float = 112.0;

	public var scale(default, null):Float = 0.7;

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

		this.keys = keys;
		this.lane = lane;
		this.playable = playable;

		// Default strumline positions
		x = 50.0 + ((FlxG.width * 0.55875138) * lane);
		y = 50.0;
	}

	override function update(elapsed:Float)
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			var member = members[i];
			if (member.exists && member.active)
			{
				member.update(elapsed);
			}
		}
	}

	override function draw():Void
	{
		if (members.length == 0)
			return;

		for (i in 0...members.length)
		{
			var member = members[i];
			if (member.exists && member.visible && member.alpha != 0.0)
			{
				member.draw();
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

	public function setGap(newGap:Float = 160.0):Void
	{
		gap = newGap;
		move(x, y);
	}

	public function setScale(newScale:Float = 0.7):Void
	{
		if (members.length == 0)
			return;

		scale = newScale;

		for (i in 0...members.length)
		{
			members[i].scale.set(scale, scale);
		}
	}

	public function clear():Void
	{
		while (members.length != 0)
		{
			members.pop().destroy();
		}
	}
}
