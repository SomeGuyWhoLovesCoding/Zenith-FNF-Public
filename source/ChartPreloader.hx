package;

class ChartPreloader
{
	static public var container:Map<String, Song.SwagSong> = [
		"test" => {
			bpmChanges: [],
			info: {
				speed: 1.6,
				stage: null,
				player1: "bf",
				player2: "bf-pixel-opponent",
				spectator: null,
				bpm: 150,
				needsVoices: true,
				time_signature: [4,4],
				offset: 140,
				strumlines: 2
			},
			song: "Test",
			noteData: [
				[12800,0,0,0,0],
				[13199,1,0,0,0],
				[13599,2,0,0,0],
				[13999,3,0,0,0],
				[14399,0,0,1,0],
				[14799,1,0,1,0],
				[15199,2,0,1,0],
				[15599,3,0,1,0]
			]
		}
	];
}