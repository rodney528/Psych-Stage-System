function onEventPushed(name:String, value1:String, value2:String, eventTime:Float):Void {
	switch (name) {
		case 'Starting Stage Offsets':
			setOnScripts('stageOffsets', {x: Std.parseFloat(value1), y: Std.parseFloat(value2)});
		// case '':
	}
}

typedef StageFile = {
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;
	var ?stageUI:String;

	var boyfriend:Array<Int>;
	var girlfriend:Array<Int>;
	var opponent:Array<Int>;
	var ?hide_girlfriend:Bool;

	var ?camera_boyfriend:Array<Int>;
	var ?camera_opponent:Array<Int>;
	var ?camera_girlfriend:Array<Int>;
	var camera_speed:Int;
}

var stageBase:StageFile = {
	directory: '',
	defaultZoom: 0.9,
	isPixelStage: false,
	stageUI: 'normal',

	boyfriend: [770, 100],
	girlfriend: [400, 130],
	opponent: [100, 100],
	hide_girlfriend: false,

	camera_boyfriend: [0, 0],
	camera_opponent: [0, 0],
	camera_girlfriend: [0, 0],
	camera_speed: 1
}

var lastGf:String = PlayState.SONG.gfVersion;
var lastAlpha:Float = 1;

function onEvent(name:String, value1:String, value2:String, eventTime:Float):Void {
	switch (name) {
		case 'Change Character':
			if (value1 == 'gf' || value1 == 'girlfriend') {
				if (gf == null)
					lastGf = value2;
			} else if (value1 == 'dad' || value1 == 'opponent') {}
			else {} // le bf
		// case '':
	}
}

function textSplit(str:String, delimiter:String) {
	var splitTxt:Array<String> = str.split(delimiter);
	for (i in 0...splitTxt.length) splitTxt[i] = StringTools.trim(splitTxt[i]);
	return splitTxt;
}