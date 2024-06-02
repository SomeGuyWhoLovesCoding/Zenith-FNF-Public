package zenith.system;

enum abstract NoteState(Int)
{
    var IDLE:Int = 0;
    var HELD:Int = 1;
    var HIT:Int = 2;
    var MISS:Int = -1;
}
