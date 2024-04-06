package zenith.data;

import zenith.data.Section;
import haxe.format.JsonParser;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var offset:Null<Float>; // For the "Sync notes to beat" option
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float = 100;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var stage:String = 'stage';

	public var offset:Null<Float> = 0;

	inline static private function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if(null == songJson.gfVersion)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if(null == songJson.events)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						inline songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						inline notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	static public function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var formattedFolder:String = inline Paths.formatToSongPath(folder);
		var formattedSong:String = inline Paths.formatToSongPath(jsonInput);

		var rawJson:String = inline sys.io.File.getContent(Paths.ASSET_PATH + '/data/' + formattedFolder + '/' + formattedSong + '.json').trim();

		while (!rawJson.endsWith("}"))
			rawJson = inline rawJson.substr(0, rawJson.length - 1); // LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE

		var songJson:SwagSong = inline parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	inline static public function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = (inline JsonParser.parse(rawJson)).song;
		return swagShit;
	}
}
