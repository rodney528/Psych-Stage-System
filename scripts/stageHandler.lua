-- Script by @rodney528

--[[
Plans -
	Figure out pixel stage shenanigans / 90%
]]--

-- Utility functions.

---Check's if the input is nil.
---@generic input
---@param variable any
---@param ifNil input
---@return input
local function nilCheck(variable, ifNil)
	return (type(variable) == 'nil' or variable == nil) and ifNil or variable
end

---Check's if your running on v1 instances of Psych Engine.
---@param exact? boolean If true, it will look for v1.0.4 specifically.
---@return boolean
local function isNew(exact)
	return nilCheck(exact, false) and version == '1.0.4' or version >= '1.0'
end
---Check's if your running on v0.7 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.7.3 specifically.
---@return boolean
local function isLegacy(exact)
	return nilCheck(exact, false) and version == '0.7.3' or (version <= '0.7.3' and version >= '0.7')
end
---Check's if your running on v0.6 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.6.3 specifically.
---@return boolean
local function isBeta(exact)
	return nilCheck(exact, false) and version == '0.6.3' or (version <= '0.6.3' and version >= '0.6')
end

---String interpolation in lua!
---@param ... any
---@return string
local function f(...)
	---@param value table
	---@return string
	local function stringifyTable(value)
		-- can't use "_setVar" because it uses "f" and I don't wanna put "f" anymore downwards than it has to be
		if isBeta() then
			runHaxeCode([[ setVar('f_varHolder', null); ]])
			setProperty('f_varHolder', value)
		else
			setVar('f_varHolder', value)
		end

		-- can't use "prepImports" here for the same reason as "_setVar"
		if not isNew() then addHaxeLibrary('Std') end
		runHaxeCode((isNew() and 'import Std;' or '') .. [[ setVar('f_varHolder', Std.string(getVar('f_varHolder'))); ]])
		return getProperty('f_varHolder')
	end

	local final = ''
	for index, value in pairs({...}) do
		local part = value
		part = type(part) == 'table' and stringifyTable(part) or tostring(part)
		part = nilCheck(part, 'nil')
		final = final .. part
	end
	return final
end

---Split's a piece of string into an array.
---@param text string
---@param delimiter string
---@return string[]
local function textSplit(text, delimiter)
	local splitTxt = stringSplit(text, delimiter) ---@type string[]
	for index, value in pairs(splitTxt) do
		splitTxt[index] = stringTrim(value)
	end
	return splitTxt
end

---Useful for prepping imports for runHaxeCode usage.
---
---## example:
---```lua
---runHaxeCode(f(
---	prepImports({'flixel.addons.display.FlxBackdrop'}),
---	[[ var ahh:FlxBackdrop = new FlxBackdrop(Paths.image('characters/BOYFRIEND')); ]]
---))
---```
---@param imports string[] The imports to prep.
---@return string
local function prepImports(imports)
	local final = ''
	for index, path in pairs(imports) do
		if isBeta() then
			runHaxeCode(f([[
				var preppedImports:Array<String> = ']], path, [['.split('.');
				setVar('prepImports_varHolder', [preppedImports.pop(), preppedImports.join('.')]);
			]]))
			local finalzedImport = getProperty('prepImports_varHolder') ---@type string[][]
			addHaxeLibrary(finalzedImport[1], finalzedImport[2])
		else
			final = f(final, 'import ', path, ';\n')
		end
	end
	return final
end

---Checks if the charting mode is active.
---@return boolean
local function isChartingMode()
	return getPropertyFromClass(f(isBeta() and '' or 'states.', 'PlayState'), 'chartingMode')
end

---A shortcut function for debugPrint with some extra stuff to it.
---@param value any What you wish to debugPrint.
---@param isDebug? boolean If true, this will only print when in charting mode.
local function trace(value, isDebug)
	if nilCheck(isDebug, false) then
		if isChartingMode() or luaDebugMode then
			debugPrint(f(value))
		end
	else -- wrapped in "f" jic you pop a single table in here
		debugPrint(f(value))
	end
end

---Returns the contents of a json file.
---@param path string The file path.
---@param printWarning? boolean If true, it will print a warning if the file doesn't exist.
---@return table | nil
local function parseJson(path, printWarning)
	local filePath = f(path, '.json')
	local fileContents = ''
	if checkFileExists(filePath) then
		fileContents = getTextFromFile(filePath) ---@type string
	else
		if printWarning then
			trace(f('File not found: ', filePath))
		end
		return nil
	end

	runHaxeCode(f(
		prepImports({'haxe.format.JsonParser'}),
		[[ var fileContents:String = ']], fileContents, [[';
		var jsonData = new JsonParser(fileContents).doParse();
		setVar('jsonData_varHolder', jsonData); ]]
	))

	return getProperty('jsonData_varHolder')
end

---Used to make setVar usage compatible with older versions.
---@param variable string The variable name.
---@param value any What the variable stores.
local function _setVar(variable, value)
	if isBeta() then
		runHaxeCode(f('setVar("',  variable,  '", null);'))
		setProperty(variable, value)
	else
		setVar(variable, value)
	end
end

---Used to make setOnScripts usage compatible with older versions.
---@param variable string The variable name.
---@param value any What the variable stores.
---@param ignoreSelf? boolean Wether to not set the variable on itself.
---@param exclusions? string[] Specific scripts to not set the variable for.
---@param luaOnly? boolean If true, it only calls setOnLuas when on newer versions.
local function _setOnScripts(variable, value, ignoreSelf, exclusions, luaOnly)
	if isBeta() then
		_setVar('setOnLuas_varHolder', {variable, value})
		runHaxeCode([[
			var varHolder:Array<Dynamic> = getVar('setOnLuas_varHolder');
			game.setOnLuas(varHolder[0], varHolder[1]);
			varHolder.resize(0);
		]])
	else
		ignoreSelf = nilCheck(ignoreSelf, false)
		exclusions = nilCheck(exclusions, {})
		if nilCheck(luaOnly, false) then
			setOnLuas(variable, value, ignoreSelf, exclusions)
		else
			setOnScripts(variable, value, ignoreSelf, exclusions)
		end
	end
end

---Used to make callOnScripts usage compatible with older versions.
---@param func string The function name.
---@param arguments? any[] The function arguments.
---@param ignoreStops? boolean Wether to ignore "Function_Stop" calls.
---@param ignoreSelf? boolean Wether the script should ignore itself. Useful for preventing recursion!
---@param excludedScripts? string[] Specific scripts to not call upon.
---@param excludedValues? any[] Values to prevent from being returned.
---@param luaOnly? boolean If true, it only calls callOnLuas when on newer versions.
---@return any returnValue Note: Always returns true on 0.7.3 for some reason? Might add a workaround, but I'm unsure atm.
local function _callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues, luaOnly)
	arguments = nilCheck(arguments, {})
	ignoreStops = nilCheck(ignoreStops, false)
	ignoreSelf = nilCheck(ignoreSelf, true)
	excludedScripts = nilCheck(excludedScripts, {})
	if isBeta() then
		return callOnLuas(func, arguments, ignoreSelf, excludedScripts)
	else
		excludedValues = nilCheck(excludedValues, {})
		if nilCheck(luaOnly, false) then
			return callOnLuas(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues)
		else
			return callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues)
		end
	end
end

-- This Scripts Utility Functions.

---Helper class for X and Y positions.
---@class LuaPoint
LuaPoint = {
	x = 0, ---@type number The X position.
	y = 0 ---@type number The Y position.
}

---@type LuaPoint
stageOffsets = nil

---Helper function for setting the stage offsets.
---@param x number The X offset.
---@param y number The Y offset.
local function setStageOffsets(x, y)
	_setOnScripts('stageOffsets', {
		x = nilCheck(x, 0),
		y = nilCheck(y, 0)
	})

end

---@todo Maybe have it return an array to allow both lua and haxe at the same time?
---@param stage string The stage file name.
---@param isJson? boolean If true, it will add the json file extension instead detecting the scripts extension.
---@return string
local function stageScript(stage, isJson)
	local hehePath = f('stages/', stage)
	if nilCheck(isJson, false) then
		if checkFileExists(f(hehePath, '.json')) then
			return f(hehePath, '.json')
		end
	else
		if checkFileExists(f(hehePath, '.lua')) then
			return f(hehePath, '.lua')
		end
		if checkFileExists(f(hehePath, '.hx')) then
			return f(hehePath, '.hx')
		end
	end
	return 'aww shit'
end

---@param func string The function name.
---@param arguments? any[] The function arguments.
local function callFunc(func, arguments)
	if isChartingMode() and func ~= 'precacheStage' then
		local fileToString = getTextFromFile(stageScript(curStage))
		if not string.find(fileToString, 'onStageCreation') or not string.find(fileToString, 'onStageDestruction') then
			trace(f('Where tf is "', func, '"?? You need that!!!'))
		end
	end
	_callOnScripts(func, arguments, true)
end

---@param character string The character tag.
---@param x number The X position.
---@param y number The Y position.
local function changeCharXY(character, x, y)
	if character == 'dad' or character == 'boyfriend' or character == 'gf' then
		setProperty(f(character, 'Group.x'), x)
		setProperty(f(character, 'Group.y'), y)
	else
		trace(f('Invalid character: ', character, ', your choices are "dad", "boyfriend", or "gf".'), true)
	end
end

---@param path string The script path.
---@param ignoreAlreadyRunning? boolean If true, it will add the script again if it's already added.
local function addScript(path, ignoreAlreadyRunning)
	ignoreAlreadyRunning = nilCheck(ignoreAlreadyRunning, false)
	if checkFileExists(f(path, '.lua')) then
		addLuaScript(path, ignoreAlreadyRunning)
	end
	if checkFileExists(f(path, '.hx')) then
		addHScript(path, ignoreAlreadyRunning)
	end
end
---@param path string Script path.
local function removeScript(path)
	if checkFileExists(f(path, '.lua')) then
		removeLuaScript(path)
	end
	if checkFileExists(f(path, '.hx')) then
		removeHScript(path)
	end
end

---Is just makeLuaSprite.
---@param tag string The sprite tag name.
---@param image string The sprite image.
---@param x number The X position.
---@param y number The Y position.
function makeStageSprite(tag, image, x, y)
	makeLuaSprite(tag, image, x, y)
	applyStageOffsets(tag)
end
---Is just makeAnimatedLuaSprite.
---@param tag string The sprite tag name.
---@param image string The sprite image.
---@param x number The X position.
---@param y number The Y position.
---@param spriteType string | 'aseprite' | 'ase' | 'json' | 'jsoni8' | 'packer' | 'packeratlas' | 'pac' | 'sparrow' | 'sparrowatlas' | 'sparrowv2' The type of sprite to load.
function makeAnimatedStageSprite(tag, image, x, y, spriteType)
	makeAnimatedLuaSprite(tag, image, x, y, spriteType)
	applyStageOffsets(tag)
end
---Quickly applies stageOffsets to ***any* object**.
---@param tag string The sprite tag name.
function applyStageOffsets(tag)
	setProperty(f(tag, '.x'), getProperty(f(tag, '.x')) + stageOffsets.x)
	setProperty(f(tag, '.y'), getProperty(f(tag, '.y')) + stageOffsets.y)
end

-- Where the magic happens!

function onCreate()
	-- trace(f('Is New: ', isNew(true), ', Is Legacy: ', isLegacy(true), ', Is Beta: ', isBeta(true)), true)
	if version < '0.6' then
		trace(f(
			'Hey this script only works on Psych v0.6 and above!\n',
			'Psych v', version, ' isn\'t compatible with the script whatsoever!'
		))
		return close(true)
	elseif not (isNew(true) or isLegacy(true) or isBeta(true)) then
		trace(f(
			'Hey this script might not work properly on Psych v', version, '!\n',
			'If you wish for the script to work appropriately please use versions...\n',
			'v0.6.3, v0.7.3 or v1.0.4! If the script works perfectly fine then just ignore this message.'
		), true)
	end
end

local lastGf = ''
local lastAlpha = 1 ---@type number
function onCreatePost()
	lastGf = getPropertyFromClass(f(isBeta() and '' or 'states.', 'PlayState'), 'SONG.gfVersion') ---@type string
	if stageOffsets == nil then setStageOffsets() end
	_setOnScripts('curStage', curStage)
	if not isBeta() then runHaxeCode(getTextFromFile('scripts/backend/callbacks.hx')) end
	addScript(f('stages/', curStage))
	callFunc('precacheStage')
	callFunc('onStageCreation', {true})
	callFunc('onStageCreationPost', {true})

	if isBeta() then
		for i = 1, getProperty('eventNotes.length') do
			onEventPushed(
				getProperty(f('eventNotes[', i ,'].event')),
				getProperty(f('eventNotes[', i ,'].value1')),
				getProperty(f('eventNotes[', i ,'].value2'))
			)
		end
	end
end

function onEventPushed(name, value1, value2)
	if name == 'Starting Stage Offsets' then
		setStageOffsets(tonumber(value1), tonumber(value2))
	end

	if name == 'Change The Stage' then
		local valueContents = {v1 = {}, v2 = {}}
		valueContents.v1 = textSplit(value1, ',')
		valueContents.v2 = textSplit(value2, ',')

		if checkFileExists(stageScript(valueContents.v1[1])) and valueContents.v1[1] ~= curStage then
			addScript(f('stages/', valueContents.v1[1]))
			callFunc('precacheStage')
			-- removeScript(f('stages/', valueContents.v1[1])) -- can't do this for some reason
		elseif valueContents.v1[1] ~= curStage then
			trace(f('Stage "', valueContents.v1[1], '" doesn\'t exist.'), true)
		end
	end
end

---@class StageFile
local StageBase = {
	directory = '', ---@type string The asset directory for the library. Goes used for soft coding.
	defaultZoom = 0.9, ---@type number The starting camera zoom.
	isPixelStage = false, ---@type boolean Wether the stage is a pixel stage. Is pretty much deprecated in v0.7 and beyond.
	stageUI = 'normal', ---@type string | 'normal' | 'pixel' The stages ui type.

	boyfriend = {770, 100}, ---@type number[] Boyfriend's starting position.
	girlfriend = {400, 130}, ---@type number[] Girlfriend's starting position.
	opponent = {100, 100}, ---@type number[] Opponent's starting position.
	hide_girlfriend = false, ---@type boolean Wether girlfriend should be hidden.

	camera_boyfriend = {0, 0}, ---@type number[] Boyfriend's camera offset.
	camera_opponent = {0, 0}, ---@type number[] Opponent's camera offset.
	camera_girlfriend = {0, 0}, ---@type number[] Girlfriend's camera offset.
	camera_speed = 1 ---@type number The stages camera speed.
}

---Checks if gf is nil.
---@return boolean result If true, gf is nil.
local function isGfNil()
	runHaxeCode("setVar('isGfNil_varHolder', game.gf == null);")
	return getProperty('isGfNil_varHolder')
end

function onEvent(name, value1, value2)
	if name == 'Change Character' then
		if value1 == 'gf' or value1 == 'girlfriend' or value1 == '1' then
			if isGfNil() then
				lastGf = value2
			end
		elseif value1 == 'dad' or value1 == 'opponent' or value1 == '0' then
		else -- le bf
		end
	end

	if name == 'Change The Stage' then
		local valueContents = {v1 = {}, v2 = {}}

		valueContents.v1 = textSplit(value1, ',')
		local snapChanges = nilCheck(valueContents.v1[2], 'false') == 'true'
		local snapCamera = nilCheck(valueContents.v1[3], 'false') == 'true'

		valueContents.v2 = textSplit(value2, ',')
		for i = 1, 2 do
			valueContents.v2[i] = tonumber(nilCheck(valueContents.v2[i], '0'))
			valueContents.v2[i] = nilCheck(valueContents.v2[i], 0)
		end

		---@type string, string
		local oldStage, newStage = curStage, valueContents.v1[1]
		if checkFileExists(stageScript(newStage, true)) then
			if checkFileExists(stageScript(oldStage)) then -- Stage Removal
				callFunc('onStageDestruction', {snapChanges})
				-- removeScript(f('stages/', oldStage)) -- can't do this for some reason
			end

			trace(f('Changing stage from "', oldStage, '" to "', newStage, '".'), true) -- Stupid print cause yes

			-- Stage Elements

			---The stage to change to.
			---@type StageFile
			local stageGet = parseJson(stageScript(newStage, true):gsub('.json', ''), isChartingMode())

			---The finalized file.
			---@type StageFile
			local jsonFile = {
				directory = nilCheck(stageGet.directory, StageBase.directory),
				defaultZoom = nilCheck(stageGet.defaultZoom, StageBase.defaultZoom),
				isPixelStage = nilCheck(stageGet.isPixelStage, StageBase.isPixelStage),
				stageUI = nilCheck(stageGet.stageUI, StageBase.stageUI),

				boyfriend = nilCheck(stageGet.boyfriend, StageBase.boyfriend),
				girlfriend = nilCheck(stageGet.girlfriend, StageBase.girlfriend),
				opponent = nilCheck(stageGet.opponent, StageBase.opponent),
				hide_girlfriend = nilCheck(stageGet.hide_girlfriend, StageBase.hide_girlfriend),

				camera_boyfriend = nilCheck(stageGet.camera_boyfriend, StageBase.camera_boyfriend),
				camera_opponent = nilCheck(stageGet.camera_opponent, StageBase.camera_opponent),
				camera_girlfriend = nilCheck(stageGet.camera_girlfriend, StageBase.camera_girlfriend),
				camera_speed = nilCheck(stageGet.camera_speed, StageBase.camera_speed)
			}

			setStageOffsets(valueContents.v2[1], valueContents.v2[2])

			if jsonFile.hide_girlfriend then
				if not isGfNil() then
					lastGf = gfName
					lastAlpha = getProperty('gf.alpha')
					runHaxeCode([[
						if (!game.gfMap.exists(gf.curCharacter)) game.gfMap.set(game.gf.curCharacter, game.gf);
						game.gf.alpha = 0.00001;
						game.gf = null;
					]])
					_setOnScripts('gfName', nil)
				end
			else
				if isGfNil() then
					runHaxeCode(f([[
						var prevGf:String = ']], lastGf, [[';
						if (!game.gfMap.exists(prevGf)) game.addCharacterToList(prevGf, 2);
						game.gf = game.gfMap.get(prevGf);
						game.gf.alpha = ]], lastAlpha, [[;
					]]))
					_setOnScripts('gfName', lastGf)
				end
			end

			_setOnScripts('defaultOpponentX', stageOffsets.x + jsonFile.opponent[1])
			_setOnScripts('defaultOpponentY', stageOffsets.y + jsonFile.opponent[2])
			setProperty('DAD_X', defaultOpponentX)
			setProperty('DAD_Y', defaultOpponentY)
			_setOnScripts('defaultGirlfriendX', stageOffsets.x + jsonFile.girlfriend[1])
			_setOnScripts('defaultGirlfriendY', stageOffsets.y + jsonFile.girlfriend[2])
			setProperty('GF_X', defaultGirlfriendX)
			setProperty('GF_Y', defaultGirlfriendY)
			_setOnScripts('defaultBoyfriendX', stageOffsets.x + jsonFile.boyfriend[1])
			_setOnScripts('defaultBoyfriendY', stageOffsets.y + jsonFile.boyfriend[2])
			setProperty('BF_X', defaultBoyfriendX)
			setProperty('BF_Y', defaultBoyfriendY)

			changeCharXY('dad', defaultOpponentX, defaultOpponentY)
			if not isGfNil() then changeCharXY('gf', defaultGirlfriendX, defaultGirlfriendY) end
			changeCharXY('boyfriend', defaultBoyfriendX, defaultBoyfriendY)

			setProperty('opponentCameraOffset[0]', nilCheck(jsonFile.camera_opponent[1], 0))
			setProperty('opponentCameraOffset[1]', nilCheck(jsonFile.camera_opponent[2], 0))
			setProperty('girlfriendCameraOffset[0]', nilCheck(jsonFile.camera_girlfriend[1], 0))
			setProperty('girlfriendCameraOffset[1]', nilCheck(jsonFile.camera_girlfriend[2], 0))
			setProperty('boyfriendCameraOffset[0]', nilCheck(jsonFile.camera_boyfriend[1], 0))
			setProperty('boyfriendCameraOffset[1]', nilCheck(jsonFile.camera_boyfriend[2], 0))

			setProperty('cameraSpeed', nilCheck(jsonFile.camera_speed, 1))

			runHaxeCode('game.moveCameraSection();')
			setProperty('defaultCamZoom', nilCheck(jsonFile.defaultZoom, 0.9))
			if snapCamera then
				runHaxeCode('FlxG.camera.snapToTarget();')
				setProperty('camGame.zoom', getProperty('defaultCamZoom'))
			end
			if isBeta() then
				setPropertyFromClass('PlayState', 'isPixelStage', nilCheck(jsonFile.isPixelStage, false))
			else
				setPropertyFromClass('states.PlayState', 'stageUI', nilCheck(jsonFile.stageUI, nilCheck(jsonFile.isPixelStage, false) and 'pixel' or 'normal'))
			end

			_setOnScripts('curStage', newStage) -- Stage Addition
			if checkFileExists(stageScript(newStage)) then
				-- addScript(f('stages/', newStage)) -- basically useless rn
				callFunc('onStageCreation', {snapChanges})
				callFunc('onStageCreationPost', {snapChanges})
			end
		else
			trace(f('Stage "', newStage, '" doesn\'t exist.'), true)
		end
	end
end