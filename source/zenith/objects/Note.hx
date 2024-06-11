package zenith.objects;

@:final
class Note extends NoteBase { public var sustainLength:#if cpp cpp.UInt16 #elseif hl hl.UI16 #else UInt #end = 0; public var state:NoteState = IDLE; }
