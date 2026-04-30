----- [[ Script by @rodney528 ]] -----

----- [[ Plans ]] -----
---
--[[

	Figure out pixel stage shenanigans / 90%

]]--

----- [[ Utility Functions ]] -----

---Check's if your running on v1 instances of Psych Engine.
---@param exact? boolean If true, it will look for v1.0.4 specifically.
---@return boolean # The results of the check.
local function isNew(exact)
	return (exact or false) and version == '1.0.4' or version >= '1.0'
end
---Check's if your running on v0.7 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.7.3 specifically.
---@return boolean # The results of the check.
local function isLegacy(exact)
	return (exact or false) and version == '0.7.3' or (version <= '0.7.3' and version >= '0.7')
end
---Check's if your running on v0.6 instances of Psych Engine.
---@param exact? boolean If true, it will look for v0.6.3 specifically.
---@return boolean # The results of the check.
local function isBeta(exact)
	return (exact or false) and version == '0.6.3' or (version <= '0.6.3' and version >= '0.6')
end
-- it would be funny to add smth like "isOutdated" but nah, lol

---String interpolation in lua!
---@param ... any The data to be interpolated.
---@return string # The interpolated data.
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
		part = part or 'nil'
		final = final .. part
	end
	return final
end

---Split's a piece of string into an array of your typing choice.
---@generic input
---@param text string The text to split.
---@param delimiter string What to split by.
---@param renderer? fun(index: integer, piece: string): input Allows you to customize how the data gets returned.
---@return input[] # The split up content.
local function textSplit(text, delimiter, renderer)
	local splitTxt = stringSplit(text, delimiter) ---@type string[]
	local finalArray = {} ---@type input[]
	for index, value in pairs(splitTxt) do
		if type(renderer) == 'function' then
			table.insert(finalArray, renderer(stringTrim(value)))
		else
			table.insert(finalArray, stringTrim(value))
		end
	end
	return finalArray
end

---Useful for prepping imports for runHaxeCode usage.
---@param ... string[] The imports to prep.
---@return string # If on v0.7 or higher, this returns the imports pre-prepped in the haxe language.
local function prepImports(...)
	local final = ''
	for index, path in pairs({...}) do
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
---@return boolean # The state of charting mode.
local function isChartingMode()
	return getPropertyFromClass(f(isBeta() and '' or 'states.', 'PlayState'), 'chartingMode')
end

---A shortcut function for debugPrint, with some extra stuff to it.
---@todo Add "color" argument.
---@param value any What you wish to debugPrint.
---@param isDebug? boolean If true, this will only print when in charting mode or lua debug mode.
local function trace(value, isDebug)
	-- for eventual color support
	local function code()
		-- wrapped in "f" jic you pop a single table in here
		debugPrint(f(value))
	end
	if isDebug or false then
		if isChartingMode() or luaDebugMode then
			code()
		end
	else
		code()
	end
end

---Returns the contents of a json file.
---##### Thanks to my friend @atlasgamer27 for helping me figure this out! lol
---@param path string The file path.
---@param printWarning? boolean If true, it will print a warning if the file doesn't exist.
---@return table | any[] | nil # The jsons contents.
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
		prepImports('haxe.format.JsonParser'),
		[[ setVar('jsonData_varHolder', new JsonParser(']], fileContents, [[').doParse()); ]]
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
		ignoreSelf = ignoreSelf or false
		exclusions = exclusions or {}
		if luaOnly or false then
			setOnLuas(variable, value, ignoreSelf, exclusions)
		else
			setOnScripts(variable, value, ignoreSelf, exclusions)
		end
	end
end

---Used to make callOnScripts usage compatible with older versions.
---@todo Add a workaround for v0.7 always returning true.
---@param func string The function name.
---@param arguments? any[] The function arguments.
---@param ignoreStops? boolean Wether to ignore "Function_Stop" calls.
---@param ignoreSelf? boolean Wether the script should ignore itself. Useful for preventing recursion!
---@param excludedScripts? string[] Specific scripts to not call upon.
---@param excludedValues? any[] Values to prevent from being returned.
---@param luaOnly? boolean If true, it only calls callOnLuas when on newer versions.
---@return any # Note: Always returns true on v0.7 for some reason? Might add a workaround, but I'm unsure atm.
local function _callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues, luaOnly)
	arguments = arguments or {}
	ignoreStops = ignoreStops or false
	ignoreSelf = ignoreSelf or true
	excludedScripts = excludedScripts or {}
	if isBeta() then
		return callOnLuas(func, arguments, ignoreSelf, excludedScripts)
	else
		excludedValues = excludedValues or {}
		if luaOnly or false then
			return callOnLuas(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues)
		else
			return callOnScripts(func, arguments, ignoreStops, ignoreSelf, excludedScripts, excludedValues)
		end
	end
end

----- [[ The Scripts Utility Functions ]] -----

---Helper class for X and Y positions.
---@class LuaPoint
LuaPoint = {
	x = 0, ---@type number The X position.
	y = 0 ---@type number The Y position.
}

---The stage position offset.
---@type LuaPoint
stageOffsets = nil

---Helper function for setting the stage offsets.
---@param x number The X offset.
---@param y number The Y offset.
local function setStageOffsets(x, y)
	_setOnScripts('stageOffsets', {
		x = x or 0,
		y = y or 0
	})
end

---@todo Maybe have it return an array to allow both lua and haxe at the same time?
---@param stage string The stage file name.
---@param isJson? boolean If true, it will add the json file extension instead detecting the scripts extension.
---@return string
local function stageScript(stage, isJson)
	local hehePath = f('stages/', stage)
	if isJson or false then
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
	ignoreAlreadyRunning = ignoreAlreadyRunning or false
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

----- [[ Where the magic happens! ]] -----

function onCreate()
	--[[ trace(f(
		'\nIs New: ', isNew(true), ' (v1.0.4)\n',
		'Is Legacy: ', isLegacy(true), ' (v0.7.3)\n',
		'Is Beta: ', isBeta(true), ' (v0.6.3)\n',
		'Is Outdated: ', version < '0.6', ' (v0.5.2)'
	), true) ]]

	if version < '0.6' then
		trace(f(
			'\nHey, this script only works on Psych v0.6 and above!\n',
			'Psych v', version, ' isn\'t compatible with the script whatsoever!'
		))
		return close(true)
	elseif not (isNew(true) or isLegacy(true) or isBeta(true)) then
		trace(f(
			'\nHey, this script might not work properly on Psych v', version, '!\n',
			'If you wish for the script to work appropriately, please use versions...\n',
			'v0.6.3, v0.7.3 or v1.0.4! If the script works perfectly fine, then just ignore this message.'
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
		-- onEventPushed fix
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
		local stage = textSplit(value1, ',')[1] ---@type string

		if checkFileExists(stageScript(stage)) and stage ~= curStage then
			addScript(f('stages/', stage))
			callFunc('precacheStage')
			-- removeScript(f('stages/', stage)) -- can't do this for some reason
		elseif stage ~= curStage then
			trace(f('Stage "', stage, '" doesn\'t exist.'), true)
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

---@enum CharType
CharType = {
	BF = 0,
	DAD = 1,
	GF = 2
}

function onEvent(name, value1, value2)
	if name == 'Change Character' then
		local charType = nil ---@type CharType
		if stringTrim(value1:lower()) == 'gf' or stringTrim(value1:lower()) == 'girlfriend' then
			charType = CharType.GF
		elseif stringTrim(value1:lower()) == 'dad' or stringTrim(value1:lower()) == 'opponent' then
			charType = CharType.DAD
		elseif not isNew() then
			charType = math.floor(tonumber(value1))
			if type(charType) ~= 'number' then
				charType = CharType.BF
			end
		else
			charType = CharType.BF
		end

		if charType == CharType.GF then
			if isGfNil() then
				lastGf = value2
			end
		end
	end

	if name == 'Change The Stage' then
		local valueContents = {v1 = {}, v2 = {}}

		valueContents.v1 = textSplit(value1, ',') ---@type string[]
		local snapChanges = (valueContents.v1[2] or 'false') == 'true'
		local snapCamera = (valueContents.v1[3] or 'false') == 'true'

		valueContents.v2 = textSplit(value2, ',', function (index, piece) return tonumber(piece) or 0 end)
		while #valueContents.v2 < 2 do table.insert(valueContents.v2, 0) end

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
			---@todo Parse all jsons at once and put them in an array for repeated use.
			---@type StageFile
			local stageGet = parseJson(stageScript(newStage, true):gsub('.json', ''), isChartingMode())

			---The finalized file.
			---@type StageFile
			local jsonFile = {
				directory = stageGet.directory or StageBase.directory,
				defaultZoom = stageGet.defaultZoom or StageBase.defaultZoom,
				isPixelStage = stageGet.isPixelStage or StageBase.isPixelStage,
				stageUI = stageGet.stageUI or StageBase.stageUI,

				boyfriend = stageGet.boyfriend or StageBase.boyfriend,
				girlfriend = stageGet.girlfriend or StageBase.girlfriend,
				opponent = stageGet.opponent or StageBase.opponent,
				hide_girlfriend = stageGet.hide_girlfriend or StageBase.hide_girlfriend,

				camera_boyfriend = stageGet.camera_boyfriend or StageBase.camera_boyfriend,
				camera_opponent = stageGet.camera_opponent or StageBase.camera_opponent,
				camera_girlfriend = stageGet.camera_girlfriend or StageBase.camera_girlfriend,
				camera_speed = stageGet.camera_speed or StageBase.camera_speed
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

			setProperty('opponentCameraOffset[0]', jsonFile.camera_opponent[1] or 0)
			setProperty('opponentCameraOffset[1]', jsonFile.camera_opponent[2] or 0)
			setProperty('girlfriendCameraOffset[0]', jsonFile.camera_girlfriend[1] or 0)
			setProperty('girlfriendCameraOffset[1]', jsonFile.camera_girlfriend[2] or 0)
			setProperty('boyfriendCameraOffset[0]', jsonFile.camera_boyfriend[1] or 0)
			setProperty('boyfriendCameraOffset[1]', jsonFile.camera_boyfriend[2] or 0)

			setProperty('cameraSpeed', jsonFile.camera_speed or 1)

			runHaxeCode('game.moveCameraSection();')
			setProperty('defaultCamZoom', jsonFile.defaultZoom or 0.9)
			if snapCamera then
				runHaxeCode('FlxG.camera.snapToTarget();')
				setProperty('camGame.zoom', getProperty('defaultCamZoom'))
			end
			if isBeta() then
				setPropertyFromClass('PlayState', 'isPixelStage', jsonFile.isPixelStage or false)
			else
				setPropertyFromClass('states.PlayState', 'stageUI', jsonFile.stageUI or ((jsonFile.isPixelStage or false) and 'pixel' or 'normal'))
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