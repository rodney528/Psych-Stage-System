--[[ Variables ]]--

---The current stage.
---@type string
curStage = getPropertyFromClass(version >= '0.7' and 'states.PlayState' or 'PlayState', 'curStage')

---The stage position offset.
stageOffsets = {
	x = 0, ---@type number The X position.
	y = 0 ---@type number The Y position.
}



--[[ Callbacks ]]--

---Called when a stage needs to be precached.
function precacheStage()
	-- precache stage object images
end

---Called when a stage is created.
---@param snapChanges boolean Wether the changes are immediate or not.
function onStageCreation(snapChanges)
	if curStage == 'name' then
		-- create stage objects
	end
end

---Called when a stage is destroyed.
---@param snapChanges boolean Wether the changes are immediate or not.
function onStageDestruction(snapChanges)
	if curStage == 'name' then
		-- destroy stage objects
	end
end



--[[ Functions ]]--

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
	setProperty(tag .. '.x', getProperty(tag .. '.x') + stageOffsets.x)
	setProperty(tag .. '.y', getProperty(tag .. '.y') + stageOffsets.y)
end