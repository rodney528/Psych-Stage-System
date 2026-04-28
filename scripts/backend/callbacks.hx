// mainly for v0.7 and above
function createCallbackForOthers(name:String, func:Dynamic):Void {
	for (script in game.luaArray)
		if (script != null && script.lua != null && !script.closed)
			if (parentLua.scriptName != script.scriptName)
				script.addLocalCallback(name, func);
	game.setOnHScript(name, func);
}

createCallbackForOthers('makeStageSprite', function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
	parentLua.call('makeStageSprite', [tag, image, x, y]);
});
createCallbackForOthers('makeAnimatedStageSprite', function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0, ?spriteType:String = 'sparrow') {
	parentLua.call('makeAnimatedStageSprite', [tag, image, x, y, spriteType]);
});
createCallbackForOthers('applyStageOffsets', function(tag:String) {
	parentLua.call('applyStageOffsets', [tag]);
});