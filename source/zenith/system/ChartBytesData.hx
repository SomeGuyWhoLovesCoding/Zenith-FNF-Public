package zenith.system;

import sys.io.FileInput;
import sys.io.FileOutput;
import sys.io.File;

@:access(zenith.objects.StrumNote)
class ChartBytesData
{
	public var input:FileInput;
	public var global_noteskin:String;

	var bytesTotal(default, null):Int = 1;

	public function new(songName:String, curDifficulty:String)
	{
		if (sys.FileSystem.exists('assets/data/$songName/chart/$curDifficulty.json'))
			saveChartFromJson(songName, curDifficulty);

		if (!sys.FileSystem.exists('assets/data/$songName/chart/$curDifficulty.bin'))
			curDifficulty = 'normal';

		input = File.read('assets/data/$songName/chart/$curDifficulty.bin');

		var global_noteskin_len = input.readByte();
		global_noteskin = input.readString(global_noteskin_len);

		var song_len = input.readByte();
		var song = input.readString(song_len);

		var speed = input.readDouble(), bpm = input.readDouble();

		var player1_len = input.readByte();
		var player1 = input.readString(player1_len);

		var player2_len = input.readByte();
		var player2 = input.readString(player2_len);

		var spectator_len = input.readByte();
		var spectator = input.readString(spectator_len);

		var stage_len = input.readByte();
		var stage = input.readString(stage_len);

		var steps = input.readByte(), beats = input.readByte(), needsVoices = input.readByte() == 1, strumlines = input.readByte();

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

		// The 10 traces are just for testing... don't worry about it
		trace(global_noteskin);
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

		bytesTotal = sys.FileSystem.stat('assets/data/$songName/chart/$curDifficulty.bin').size;

		_moveToNext();
	}

	// This chart note data is 8 bytes in size for each note
	// Proof: Int32 (4 bytes), UInt8 (1 byte), UInt16 (2 bytes), and UInt8 (1 byte again)
	var position(default, null):Int = 0;

	public function update()
	{
		if (bytesTotal == 0)
			return;

		while (Main.conductor.songPosition > position - (1880.0 / Gameplay.instance.songSpeed))
		{
			var lane = inline input.readByte(), noteData = inline input.readByte(),
				length = inline input.readByte() | (inline input.readByte() << 8);

			Gameplay.instance.strumlines[lane].members[noteData].spawnNote(position, length);

			if (input.tell() == bytesTotal)
			{
				input.close();
				bytesTotal = 0;
				break;
			}

			_moveToNext();
		}
	}

	// Internal helper function
	function _moveToNext()
	{
		position = (inline input.readByte()) | (inline input.readByte() << 8) | (inline input.readByte() << 16) | (inline input.readByte() << 24);
	}

	static public function saveChartFromJson(songName:String, curDifficulty:String)
	{
		trace("Parsing json...");

		var json = haxe.Json.parse(File.getContent('assets/data/$songName/chart/$curDifficulty.json'));

		trace('Done! Now let\'s start writing to "assets/data/$songName/chart/$curDifficulty.bin".');

		var output:FileOutput = File.write('assets/data/$songName/chart/$curDifficulty.bin');

		json.noteskin = json.noteskin ?? "Regular";
		inline output.writeByte(json.noteskin.length);
		output.writeString(json.noteskin);

		// Song
		inline output.writeByte(json.song.length);
		output.writeString(json.song);

		// Speed
		inline output.writeDouble(json.info.speed);

		// BPM
		inline output.writeDouble(json.info.bpm);

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

		var nd:Array<Array<Float>> = json.noteData; // Workaround for the dynamic iteration error

		for (i in 0...nd.length)
		{
			var note = nd[i];

			var position = Std.int(note[0]);

			// Basically writeInt32
			inline output.writeByte(position & 0xFF);
			inline output.writeByte((position >> 8) & 0xFF);
			inline output.writeByte((position >> 16) & 0xFF);
			inline output.writeByte(position >>> 24);

			inline output.writeByte(Std.int(note[3]));
			inline output.writeByte(Std.int(note[1]));

			var length = Std.int(note[2]);

			// Basically writeUInt16
			inline output.writeByte(length & 0xFF);
			inline output.writeByte(length >> 8);
		}

		output.close(); // LMAO
	}

	static public function saveJsonFromChart(songName:String, curDifficulty:String)
	{
		trace("Parsing chart...");

		var _input:FileInput = File.read('assets/data/$songName/chart/$curDifficulty.bin');

		trace('Done! Now let\'s start writing to "assets/data/$songName/chart/$curDifficulty.json".');

		var noteskin_len = _input.readByte();
		var noteskin = _input.readString(noteskin_len);

		var song_len = _input.readByte();
		var song = _input.readString(song_len);

		var speed = _input.readDouble();
		var bpm = _input.readDouble();

		var player1_len = _input.readByte();
		var player1 = _input.readString(player1_len);

		var player2_len = _input.readByte();
		var player2 = _input.readString(player2_len);

		var spectator_len = _input.readByte();
		var spectator = _input.readString(spectator_len);

		var stage_len = _input.readByte();
		var stage = _input.readString(stage_len);

		var steps = _input.readByte();
		var beats = _input.readByte();

		var needsVoices:Bool = _input.readByte() == 1;
		var strumlines = _input.readByte();

		var noteData:Array<Array<Float>> = [];
		var _lane = 0, _noteData = 0, _susLen = 0, _position = 0;

		while (!_input.eof())
		{
			_position = (inline _input.readByte()) | (inline _input.readByte() << 8) | (inline _input.readByte() << 16) | (inline _input.readByte() << 24);
			_lane = inline _input.readByte();
			_noteData = inline _input.readByte();
			_susLen = (inline _input.readByte()) | (inline _input.readByte() << 8);
			noteData.push([_position, _noteData, _susLen, _lane]);
		}

		File.saveContent('assets/data/$songName/chart/$curDifficulty.json',
			'{"noteskin":"$noteskin","song":"$song","info":{"stage":"$stage","player1":"$player1","player2":"$player2","spectator":"$spectator","speed":$speed,"bpm":$bpm,"time_signature":[$beats, $steps],"needsVoices":$needsVoices,"strumlines":$strumlines},"noteData":$noteData}');
	}
}
