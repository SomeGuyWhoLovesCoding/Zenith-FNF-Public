package zenith.objects;

class Note extends NoteBase
{
	public var sustainLength:Float = 0.0;
	public var wasHit:Bool = false;
	public var tooLate:Bool = false;

	public var multiplier:Int = 0;

	public function new():Void
	{
		super();

		// The absolute fastest way to display notes
		if (null != Gameplay.instance.events)
			Gameplay.instance.events.emit(SignalEvent.NOTE_NEW, this);
	}
}