package zenith.objects;

@:access(Stack);
class NoteLogic
{
	public var members:Stack<NoteObject>;

	public function new():Void
	{
		super();

		members = new Stack<NoteObject>(100, Paths.idleNote);
		active = false;
	}

	override function update(elapsed:Float):Void {}

	var member(default, null):NoteObject;
	override function draw():Void
	{
		for (i in 0...members.length)
		{
			member = members.__items[i];

			if (member.exists)
			{

			}	
		}
	}
}