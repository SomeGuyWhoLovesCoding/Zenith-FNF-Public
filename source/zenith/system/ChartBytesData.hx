package zenith.system;

import sys.io.FileInput;
import sys.io.File;

// The chart note data in the most optimized format possible
// Only 8 bytes total for each one (without extra for pointers depending on the target)
typedef ChartNoteData =
{
	var position:Float32;
	var noteData:UInt;
	var sustainLength:UInt;
	var lane:UInt;
}

class ChartBytesData
{
	public var input:FileInput;

	var bytesTotal(default, null):Float = 1;

	public function new(songName:String, songDifficulty:String = 'normal'):Void
	{
		input = File.read('assets/data/$songName/chart/$songDifficulty.bin');

		var song_len = input.readByte();
		var song:String = input.readString(song_len);

		var speed = input.readFloat();
		var bpm = input.readFloat();

		var player1_len = input.readByte();
		var player1:String = input.readString(player1_len);

		var player2_len = input.readByte();
		var player2:String = input.readString(player2_len);

		var spectator_len = input.readByte();
		var spectator:String = input.readString(spectator_len);

		var stage_len = input.readByte();
		var stage:String = input.readString(stage_len);

		var steps = input.readByte();
		var beats = input.readByte();

		var needsVoices:Bool = input.readByte() == 1;
		var strumlines = input.readByte();

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

		bytesTotal = input.readFloat();

		trace(Gameplay.SONG.toString());

		_moveToNext();
	}

	var nextNote:ChartNoteData = {position: 0, noteData: 0, sustainLength: 0, lane: 0};

	public function update():Void
	{
		if (bytesTotal == 0)
			return;

		while (Main.conductor.songPosition > nextNote.position - (1880 / Gameplay.instance.songSpeed))
		{
			Gameplay.instance.noteSpawner.spawn(nextNote);

			if (bytesTotal - input.tell() == 0)
			{
				input.close();
				bytesTotal = 0;
				break;
			}

			_moveToNext();
		}
	}

	inline function _moveToNext():Void
	{
		nextNote.position = _readFloat();
		nextNote.noteData = inline input.readByte();
		nextNote.sustainLength = _readUInt16();
		nextNote.lane = inline input.readByte();
	}

	static public function saveChartFromJson(songName:String, songDifficulty:String):Void
	{
		trace("Parsing json...");

		var json:Song.SwagSong = haxe.Json.parse(File.getContent('assets/data/$songName/chart/$songDifficulty.json'));

		trace('Done! Now let\'s start writing to "assets/data/$songName/chart/$songDifficulty.bin".');

		var output = File.write('assets/data/$songName/chart/$songDifficulty.bin');

		// Song
		inline output.writeByte(json.song.length);
		output.writeString(json.song);

		// Speed
		inline output.writeFloat(json.info.speed);

		// BPM
		inline output.writeFloat(json.info.bpm);

		// Player 1
		inline output.writeByte(json.info.player1.length);
		output.writeString(json.info.player1);

		// Player 2
		inline output.writeByte(json.info.player2.length);
		output.writeString(json.info.player2);

		// Spectator
		inline output.writeByte(json.info.spectator != null ? json.info.spectator.length : 2);
		output.writeString(json.info.spectator != null ? json.info.spectator : "gf");

		// Stage
		inline output.writeByte(json.info.stage != null ? json.info.stage.length : 5);
		output.writeString(json.info.stage != null ? json.info.stage : "stage");

		// Time signature (steps)
		inline output.writeByte(json.info.time_signature[0]);

		// Time signature (beats)
		inline output.writeByte(json.info.time_signature[1]);

		// Needs voices
		inline output.writeByte(json.info.needsVoices ? 1 : 0);

		// Strumline count
		inline output.writeByte(json.info.strumlines);

		// Pretty
		inline output.writeFloat((json.song.length + 9 + (json.info.player1.length + 1) + (json.info.player2.length + 1) +
			(json.info.spectator != null ? json.info.spectator.length + 1 : 3) + (json.info.stage != null ? json.info.stage.length + 1 : 6) + 8) + (json.noteData.length * 8));

		for (note in json.noteData)
		{
			inline output.writeFloat(note[0]);
			inline output.writeByte(Std.int(note[1]));
			inline output.writeUInt16(Std.int(note[2]));
			inline output.writeByte(Std.int(note[3]));
		}

		output.close(); // LMAO
	}

	static public function saveJsonFromChart(songName:String, songDifficulty:String):Void
	{
		trace("Parsing chart...");

		var _input:FileInput = File.read('assets/data/$songName/chart/$songDifficulty.bin');

		trace('Done! Now let\'s start writing to "assets/data/$songName/chart/$songDifficulty.json".');

		var song_len = _input.readByte();
		var song:String = _input.readString(song_len);

		var speed = _input.readFloat();
		var bpm = _input.readFloat();

		var player1_len = _input.readByte();
		var player1:String = _input.readString(player1_len);

		var player2_len = _input.readByte();
		var player2:String = _input.readString(player2_len);

		var spectator_len = _input.readByte();
		var spectator:String = _input.readString(spectator_len);

		var stage_len = _input.readByte();
		var stage:String = _input.readString(stage_len);

		var steps = _input.readByte();
		var beats = _input.readByte();

		var needsVoices:Bool = _input.readByte() == 1;
		var strumlines = _input.readByte();

		var noteData:Array<Array<Float>> = [];

		while (true)
		{
			try
			{
				noteData.push([_input.readFloat(), inline _input.readByte(), _input.readUInt16(), inline _input.readByte()]);
			}
			catch (e)
			{
				break;
			}
		}

		File.saveContent('assets/data/$songName/chart/$songDifficulty.json', '{"song":"$song","info":{"stage":"$stage","player1":"$player1","player2":"$player2","spectator":"$spectator","speed":$speed,"bpm":$bpm,"time_signature":[$beats, $steps],"needsVoices":$needsVoices,"strumlines":$strumlines},"noteData":$noteData}');
	}

	// Inlined functions to improve performance when streaming bytes
	// This is just the rest of ChartBytesData lol

	inline function _readUInt16():Int
	{
		var ch1 = inline input.readByte();
		var ch2 = inline input.readByte();
		return input.bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
	}

	inline function _readInt32():Int {
		var ch1 = inline input.readByte();
		var ch2 = inline input.readByte();
		var ch3 = inline input.readByte();
		var ch4 = inline input.readByte();
		#if (php || python)
		// php will overflow integers.  Convert them back to signed 32-bit ints.
		var n = input.bigEndian ? ch4 | (ch3 << 8) | (ch2 << 16) | (ch1 << 24) : ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
		if (n & 0x80000000 != 0)
			return (n | 0x80000000);
		else
			return n;
		#elseif lua
		var n = input.bigEndian ? ch4 | (ch3 << 8) | (ch2 << 16) | (ch1 << 24) : ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
		return lua.Boot.clampInt32(n);
		#else
		return input.bigEndian ? ch4 | (ch3 << 8) | (ch2 << 16) | (ch1 << 24) : ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
		#end
	}

	inline function _readFloat():Float32
	{
		return inline haxe.io.FPHelper.i32ToFloat(_readInt32());
	}
}
