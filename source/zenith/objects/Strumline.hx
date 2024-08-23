package zenith.objects;

/**
 * The strumline.
 */
@:access(zenith.objects.StrumNote)
@:access(flixel.FlxCamera)
class Strumline extends FlxBasic
{
	public var keys(default, set):Int;

	private function set_keys(value:Int):Int
	{
		var val = value;
		for (i in 0...val)
		{
			m = members[i] = new StrumNote(i, lane);
			@:bypassAccessor m.scale.set(scale, scale);
			m.parent = this;
			m._reset();
			m.playable = playable;
		}

		if (val <= keys)
		{
			members.resize(val);
		}

		moveX(x);
		moveY(y);

		return keys = val;
	}

	public var lane:Int;
	public var player:Bool;
	public var downScroll:Bool;

	public var x(default, set):Float;

	private function set_x(value:Float):Float
	{
		moveX(value);
		return x = value;
	}

	public var y(default, set):Float;

	private function set_y(value:Float):Float
	{
		moveY(value);
		return y = value;
	}

	public var alpha(default, set):Float;

	private function set_alpha(value:Float):Float
	{
		if (members.length == 0)
			return alpha;

		var len = members.length;
		for (i in 0...len)
		{
			members[i].alpha = value;
		}

		return alpha = value;
	}

	public var members:Array<StrumNote> = [];

	public var gap(default, set):Float;

	private function set_gap(value:Float):Float
	{
		if (members.length == 0)
			return gap;

		gap = value;
		moveX(x);

		return gap = value;
	}

	public var scale(default, set):Float;

	private function set_scale(value:Float):Float
	{
		if (members.length == 0)
			return scale;

		scale = value;

		var len = members.length;
		for (i in 0...len)
		{
			@:bypassAccessor members[i].scale.set(scale, scale);
		}

		moveX(x);

		return value;
	}

	public var playable(default, set):Bool;

	private function set_playable(value:Bool):Bool
	{
		if (members.length == 0)
			return playable;

		var len = members.length;
		for (i in 0...len)
		{
			members[i].playable = value;
		}

		return playable = value;
	}

	public function new(keys:Int = 4, lane:Int = 0, playable:Bool = false)
	{
		super();

		this.lane = lane;
		this.keys = keys;
		gap = 112;
		scale = 1;
		this.playable = playable;

		// Default strumline positions
		x = (y = 60) + (Std.int(FlxG.width * (0.5587511111112 * lane)));
	}

	inline public function reset()
	{
		keys = 4;
		gap = 112;
		scale = 1;

		// Default strumline positions
		x = (y = 60) + (Std.int(FlxG.width * 0.5587511111112 * lane));
	}

	private var m(default, null):StrumNote;

	override function draw()
	{
		if (members.length == 0)
			return;

		render();
	}

	function render()
	{
		if (!visible)
		{
			return;
		}

		var delta = FlxG.elapsed;
		var len = members.length;
		for (i in 0...len)
		{
			m = members[i];
			if (m.visible)
			{
				if (m.active)
					m.update(delta);
				m.draw();
			}
		}
	}

	public function moveX(x:Float)
	{
		if (members.length == 0)
			return;

		var len = members.length;
		for (i in 0...len)
		{
			@:bypassAccessor members[i].x = x + (gap * i);
		}
	}

	public function moveY(y:Float)
	{
		if (members.length == 0)
			return;

		var len = members.length;
		for (i in 0...len)
		{
			@:bypassAccessor members[i].y = y;
		}
	}

	public function clear()
	{
		while (members.length != 0)
		{
			members.pop().destroy();
		}
	}

	public function updateHitbox()
	{
		var len = members.length;
		for (i in 0...len)
		{
			m = members[i];
			@:bypassAccessor
			{
				m.offset.x = (m.frameWidth >> 1) - 54;
				m.offset.y = (m.frameHeight >> 1) - 56;
				m.origin.x = m.offset.x + 54;
				m.origin.y = m.offset.y + 56;
			}
		}
	}

	public var singPrefix:String = "sing";
	public var singSuffix:String = "";
	public var missSuffix:String = "miss";
	public var singAnimations:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];
	public var noteColors:Array<Int> = [0xFF9966BB, 0xFF00FFFF, 0xFF00FF00, 0xFFFF0000];
	public var noteAngles:Array<Int> = [0, -90, 90, 180];
	public var targetCharacter:Character;
}
