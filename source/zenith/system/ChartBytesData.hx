package zenith.system;

import haxe.io.Bytes;
import sys.io.File;

// The chart note data in the most optimized format possible (depending on the target)
// Only 8 bytes total for each one (without extra for pointers)
class ChartNoteData
{
	public var strumTime:Int;
	public var noteData:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end ;
	public var sustainLength:#if cpp cpp.UInt16 #elseif hl hl.UI16 #else UInt #end ;
	public var lane:#if cpp cpp.UInt8 #elseif hl hl.UI8 #else UInt #end ;

	public function new():Void {}
}

class ChartBytesData
{
	var position:UInt = 0;

	public var bytes:Bytes;

	public function new(songName:String, songDifficulty:String = 'normal'):Void
	{
		bytes = File.getBytes('assets/data/$songName/chart/$songDifficulty.bin');

		var song_len = bytes.get(position);
		position++;
		var song:String = bytes.getString(position, song_len);
		position += song.length;

		var speed = bytes.getFloat(position);
		position += 4;

		var bpm = bytes.getFloat(position);
		position += 4;

		var player1_len = bytes.get(position);
		position++;
		var player1:String = bytes.getString(position, player1_len);
		position += player1.length;

		var player2_len = bytes.get(position);
		position++;
		var player2:String = bytes.getString(position, player2_len);
		position += player2.length;

		var spectator_len = bytes.get(position);
		position++;
		var spectator:String = bytes.getString(position, spectator_len);
		position += spectator.length;

		var stage_len = bytes.get(position);
		position++;
		var stage:String = bytes.getString(position, stage_len);
		position += stage.length;

		var steps = bytes.get(position);
		position++;

		var beats = bytes.get(position);
		position++;

		var needsVoices:Bool = bytes.get(position) == 1;
		position++;

		var strumlines = bytes.get(position);
		position++;

		Gameplay.SONG = new Song(song, {
			speed: speed,
			bpm: bpm,
			player1: player1,
			player2: player2,
			spectator: spectator,
			stage: stage,
			time_signature: [beats, steps],
			needsVoices: needsVoices,
			strumlines: strumlines
		});

		trace(Gameplay.SONG.toString());

		_moveToNext();
	}

	var nextNote:ChartNoteData = new ChartNoteData();

	public function update():Void
	{
		while (Main.conductor.songPosition > nextNote.strumTime - (1870 / Gameplay.instance.songSpeed))
		{
			trace('Spawn at ${nextNote.strumTime}');
			Gameplay.instance.noteSpawner.spawn(nextNote);

			_moveToNext();
		}
	}

	inline function _moveToNext():Void
	{
		nextNote.strumTime = bytes.getInt32(position);
		position += 4;
		nextNote.noteData = bytes.get(position);
		position++;
		nextNote.sustainLength = bytes.getUInt16(position);
		position += 2;
		nextNote.lane = bytes.get(position);
		position++;
	}

	static public function saveChartFromJson(songName:String, songDifficulty:String):Void
	{
		trace("Parsing json...");
		var json:Song.SwagSong = haxe.Json.parse(File.getContent('assets/data/$songName/chart/$songDifficulty.json'));
		trace(json);
		trace("Done! Now let's precalculate the size for the bytes and preallocate the bytes");

		// (Bytes for song string) + info.speed (4) + info.bpm (4) + (Bytes for info.player1 string) + (Bytes for info.player2 string) + (Bytes for info.spectator string) + (Bytes for info.stage string) + (SONG.noteData.length) bytes total.
		// For preallocation btw

		trace(json.song.length);
		trace(json.info.player1.length);
		trace(json.info.player2.length);
		trace(json.noteData.length);

		var size:Int = json.song.length + 8 + json.info.player1.length + json.info.player2.length + (json.noteData.length * 8);

		if (json.info.spectator != null)
			size += json.info.spectator.length;

		if (json.info.stage != null)
			size += json.info.stage.length;

		var input:Bytes = Bytes.alloc(size);
		var position:Int = 0;

		// Song
		input.set(position, json.song.length);
		position++;
		_setString(input, position, json.song);
		position += json.song.length;

		// Speed
		input.setFloat(position, json.info.speed);
		position += 4;

		// BPM
		input.setFloat(position, json.info.bpm);
		position += 4;

		// Player 1
		input.set(position, json.info.player1.length);
		position++;
		_setString(input, position, json.info.player1);
		position += json.info.player1.length;

		// Player 2
		input.set(position, json.info.player2.length);
		position++;
		_setString(input, position, json.info.player2);
		position += json.info.player2.length;

		// Spectator
		input.set(position, json.info.spectator.length);
		position++;
		_setString(input, position, json.info.spectator);
		position += json.info.spectator.length;

		// Stage
		input.set(position, json.info.stage.length);
		position++;
		_setString(input, position, json.info.stage);
		position += json.info.stage.length;

		// Time signature (beats)
		input.set(position, json.info.time_signature[0]);
		position++;

		// Time signature (beats)
		input.set(position, json.info.time_signature[1]);
		position++;

		// Needs voices
		input.set(position, json.info.needsVoices ? 1 : 0);
		position++;

		// Strumline count
		input.set(position, json.info.strumlines);
		position++;

		for (note in json.noteData)
		{
			trace(note[0]);
			input.setInt32(position, Std.int(note[0]));
			position += 4;
			input.set(position, Std.int(note[1]));
			position++;
			input.setUInt16(position, Std.int(note[2]));
			position += 2;
			input.set(position, Std.int(note[3]));
			position++;
		}

		File.saveBytes('assets/data/$songName/chart/$songDifficulty.bin', input);
	}

	// This was made as a workaround for setting a string in haxe.io.Bytes without even using haxe.io.BytesBuffer and with preallocation.
	static function _setString(input:Bytes, position:Int, str:String):Void
	{
		input.blit(position, Bytes.ofString(str), 0, str.length);
	}
}
