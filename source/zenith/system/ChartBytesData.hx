package zenith.system;

import sys.io.FileInput;
import sys.io.FileOutput;
import sys.io.File;

class ChartBytesData
{
	public var input:FileInput;

	var bytesTotal(default, null):Int = 1;

	public function new(songName:String, songDifficulty:String = 'normal'):Void
	{
		if (sys.FileSystem.exists('assets/data/$songName/chart/$songDifficulty.json'))
			saveChartFromJson(songName, songDifficulty);

		input = File.read('assets/data/$songName/chart/$songDifficulty.bin');

		var song_len = input.readByte();
		var song:String = input.readString(song_len);

		var speed = input.readByte() * 0.0392156862745098;
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

		trace(Gameplay.SONG.song);
		trace(Gameplay.SONG.info.speed);
		trace(Gameplay.SONG.info.bpm);
		trace(Gameplay.SONG.info.player1);
		trace(Gameplay.SONG.info.player2);
		trace(Gameplay.SONG.info.spectator);
		trace(Gameplay.SONG.info.stage);
		trace(Gameplay.SONG.info.time_signature);
		trace(Gameplay.SONG.info.needsVoices);
		trace(Gameplay.SONG.info.strumlines);

		bytesTotal = sys.FileSystem.stat('assets/data/$songName/chart/$songDifficulty.bin').size;

		_moveToNext();
	}

	// Chart note data (but with raw variables)
	// This is 7 bytes in size for each note
	// Proof: Int32 (4 bytes), UInt8 (1 byte), UInt8 (another 1 byte), and UInt8 (1 byte yet again)
	var position(default, null):Int = 0;
	var noteData(default, null):Int = 0;
	var length(default, null):Int = 0;
	var lane(default, null):Int = 0;

	public function update():Void
	{
		if (bytesTotal == 0)
			return;

		while (Main.conductor.songPosition > position - (1880.0 / Gameplay.instance.songSpeed))
		{
			Gameplay.instance.noteSpawner.spawn(position, noteData, length, lane);

			if (input.tell() == bytesTotal)
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
		position = inline input.readInt32();
		noteData = (inline input.readByte()) & 0xFF;
		length = (inline input.readByte()) & 0xFF;
		lane = (inline input.readByte()) & 0xFF;
	}

	static public function saveChartFromJson(songName:String, songDifficulty:String):Void
	{
		trace("Parsing json...");

		var json:Song.SwagSong = haxe.Json.parse(File.getContent('assets/data/$songName/chart/$songDifficulty.json'));

		trace('Done! Now let\'s start writing to "assets/data/$songName/chart/$songDifficulty.bin".');

		var output:FileOutput = File.write('assets/data/$songName/chart/$songDifficulty.bin');

		// Song
		inline output.writeByte(json.song.length);
		output.writeString(json.song);

		// Speed
		inline output.writeByte(Std.int(json.info.speed * 25.5));

		// BPM
		inline output.writeFloat(json.info.bpm);

		// Player 1
		inline output.writeByte(json.info.player1.length);
		output.writeString(json.info.player1);

		// Player 2
		inline output.writeByte(json.info.player2.length);
		output.writeString(json.info.player2);

		// Spectator
		json.info.spectator = json.info.spectator ?? "gf";
		inline output.writeByte(json.info.spectator.length);
		output.writeString(json.info.spectator);

		// Stage
		json.info.stage = json.info.stage ?? "stage";
		inline output.writeByte(json.info.stage.length);
		output.writeString(json.info.stage);

		// Time signature (steps)
		inline output.writeByte(json.info.time_signature[0]);

		// Time signature (beats)
		inline output.writeByte(json.info.time_signature[1]);

		// Needs voices
		inline output.writeByte(json.info.needsVoices ? 1 : 0);

		// Strumline count
		inline output.writeByte(json.info.strumlines);

		for (note in json.noteData)
		{
			inline output.writeInt32(Std.int(note[0]));
			inline output.writeByte(Std.int(note[1]) & 0xFF);
			inline output.writeByte((Std.int(note[2]) & 0xFF) >> 5);
			inline output.writeByte(Std.int(note[3]) & 0xFF);
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

		var speed = _input.readByte() * 0.0392156862745098;
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
				noteData.push([_input.readInt32(), inline _input.readByte(), inline _input.readByte() << 5, inline _input.readByte()]);
			}
			catch (e)
			{
				break;
			}
		}

		File.saveContent('assets/data/$songName/chart/$songDifficulty.json',
			'{"song":"$song","info":{"stage":"$stage","player1":"$player1","player2":"$player2","spectator":"$spectator","speed":$speed,"bpm":$bpm,"time_signature":[$beats, $steps],"needsVoices":$needsVoices,"strumlines":$strumlines},"noteData":$noteData}');
	}

	// Inlined functions to improve performance when streaming bytes
	// This is just the rest of ChartBytesData lol

	inline function _readInt32():Int
	{
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
}
