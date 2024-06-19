package zenith.data;

typedef SwagSong =
{
	song:String,
	info:SongInfo,
	noteData:Array<Array<Float>>
}

class Song
{
	public var song:String;
	public var info:SongInfo;

	public function new(?song:String, ?info:SongInfo):Void
	{
		this.song = song;
		this.info = info;
	}

	public function toString():String
	{
		return '{song : $song, info : $info}';
	}

	public function stringify(noteData:Array<Array<Float>>):String
	{
		return
			'{ "song": "$song", "info": { "stage": "${info.stage}", "player1": "${info.player1}", "player2", "${info.player2}", "spectator", "${info.spectator}", "speed": ${info.speed}, "bpm": ${info.bpm}, "time_signature": ${info.time_signature}, "strumlines": ${info.strumlines} }, "noteData": $noteData }';
	}
}

typedef SongInfo =
{
	var stage:String;
	var player1:String;
	var player2:String;
	var spectator:String;
	var speed:Float;
	var bpm:Float;
	var time_signature:Array<UInt>;
	var needsVoices:Bool;
	@:optional var strumlines:UInt;
}
