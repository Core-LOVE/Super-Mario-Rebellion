--[[
	quickPipes.lua
	By Marioman2007 - v1.1
	With help from: MrDoubleA, KBM-Quine and Enjl
]]

SaveData.quickPipes = SaveData.quickPipes or {}
SaveData.quickPipes.filename = SaveData.quickPipes.filename or ""
SaveData.quickPipes.entryDirection = SaveData.quickPipes.entryDirection or 0
SaveData.quickPipes.exitDirection = SaveData.quickPipes.exitDirection or 0

local savedata = SaveData.quickPipes
local quickPipes = {}

-- direction constants
quickPipes.UP    = 1
quickPipes.LEFT  = 2
quickPipes.DOWN  = 3
quickPipes.RIGHT = 4

-- set to false to disable fast warping
quickPipes.enabled = true

-- set to false to disable counter rendering
quickPipes.drawCounter = true

-- set to false to disable icon rendering
quickPipes.drawIcons = true

-- whether cross section warps get affected
quickPipes.allowCrossSections = true

-- these can be number or string, or nil for no sound
quickPipes.warpEnterSFX = SFX.open(Misc.resolveSoundFile("sound/extended/warp-short"))
quickPipes.warpExitSFX = SFX.open(Misc.resolveSoundFile("sound/extended/warp-short"))

-- how many frames to wait before exiting
quickPipes.waitTime = 16

-- message that appears when a player tries to enter a warp with insufficient stars, %d is replaced by the number of stars
quickPipes.starMessage = {
	"You need %d star to enter.",
	"You need %d stars to enter.",
}

-- boost given to the player upon exiting a warp
quickPipes.boosts = {
	[quickPipes.UP]    = vector( 0, -4),
	[quickPipes.LEFT]  = vector(-2, 0),
	[quickPipes.DOWN]  = vector( 0, 2),
	[quickPipes.RIGHT] = vector( 2, 0),
}

-- speed of the warping sequence
quickPipes.speeds = {
	[quickPipes.UP]    = vector(0, -3),
	[quickPipes.LEFT]  = vector(-2.5, 0),
	[quickPipes.DOWN]  = vector(0, 3),
	[quickPipes.RIGHT] = vector(2.5, 0),
}

-- offsets of the icons, relative to the center
quickPipes.iconOffsets = {
	[quickPipes.UP]    = {star = vector(  0,-64), lock = vector(  0,-32)},
	[quickPipes.LEFT]  = {star = vector(-64,-16), lock = vector(-32,-16)},
	[quickPipes.DOWN]  = {star = vector(  0, 64), lock = vector(  0, 32)},
	[quickPipes.RIGHT] = {star = vector( 64,-16), lock = vector( 32,-16)},
}

quickPipes.images = {
	star     = Graphics.sprites.hardcoded["33-5"].img,
	cross    = Graphics.sprites.hardcoded["33-1"].img,
	starIcon = Graphics.sprites.background[160].img,
	lockIcon = Graphics.sprites.background[98].img,
}

-- end of customizable stuff

Audio.sounds[17].muted = true

local data = {}
local fileName = Level.filename()

local dirSign = {
	[quickPipes.UP]    = vector( 0, -1),
	[quickPipes.LEFT]  = vector(-1,  0),
	[quickPipes.DOWN]  = vector( 0,  1),
	[quickPipes.RIGHT] = vector( 1,  0),
}

local warpingConditions = {
	[quickPipes.UP] = function(x1, y1, x2, y2, p)
		return p.y <= y1 + 2 and p.y + p.height >= y1 and p.keys.up
	end,

	[quickPipes.LEFT] = function(x1, y1, x2, y2, p)
		return p.x <= x1 + 2 and p.y <= y2 and
		p.y + p.height >= y2 - 2 and p.keys.left
	end,

	[quickPipes.DOWN] = function(x1, y1, x2, y2, p)
		return p.y + p.height >= y2 - 2 and p.y <= y2 and p.keys.down
	end,

	[quickPipes.RIGHT] = function(x1, y1, x2, y2, p)
		return p.x + p.width >= x2 - 2 and p.y <= y2 and
		p.y + p.height >= y2 - 2 and p.keys.right
	end,
}

local function initData(idx)
	data[idx] = data[idx] or {
		enteredPipe = false,
		currentWarp = nil,
		sfxPlayed = false,
		exitBoost = vector(0, 0),
		waitTimer = 0,

		warpEntryDirection = 0,
		warpExitDirection = 0,

		warpEntrySign = vector(0, 0),
		warpExitSign = vector(0, 0),

		warpSpeedEntry = vector(0, 0),
		warpSpeedExit = vector(0, 0),
	}

	return data[idx]
end

local function isOnScreen(x, y, w, h, c)
    if x < c.x - w then
		return false
	elseif x > c.x + c.width then
		return false
	elseif y < c.y - h then
		return false
	elseif y > c.y + c.height then
		return false
	else
		return true
	end
end

local function drawIcon(w, img, pos, p, c)
	local x = w.entranceX + w.entranceWidth/2 + pos.x - img.width/2
	local y = w.entranceY + w.entranceHeight/2 + pos.y - img.height/2

	if not isOnScreen(x, y, img.width, img.height, c) then return end

	--Graphics.drawBox{x = x, y = y, w = img.width, h = img.height, color = Color.blue..0.5, sceneCoords = true}
	
	Graphics.drawImageToSceneWP(img, x, y, p)
end

local function isHoldingKey(p)
	return (p:mem(0x12, FIELD_BOOL) or (p.holdingNPC and p.holdingNPC.id == 31))
end

local function validityCheck(w, p)
	return (
		-- is valid and is not hidden
		w.isValid and (not w.isHidden) and (not w.fromOtherLevel) and

		-- is a downwards pipe and not on a clown car
		w.warpType == 1 and p.mount ~= MOUNT_CLOWNCAR and

		-- has a key?
		(not w.locked or isHoldingKey(p))
	)
end

local function setupCFG(cfg, entry, exit)
	cfg.warpEntrySign = dirSign[entry]
	cfg.warpExitSign = dirSign[exit]

	cfg.warpSpeedEntry = quickPipes.speeds[entry] or vector(0, 0)
	cfg.warpSpeedExit = quickPipes.speeds[exit] or vector(0, 0)

	cfg.exitBoost = quickPipes.boosts[exit]
end

local function resetData(s)
	s.filename = ""
	s.entryDirection = 0
	s.exitDirection = 0
end

-- may be necessary for external use
function quickPipes.getData(idx)
	if idx then
		return data[idx]
	end

	return data
end

-- used to make the given player enter the given warp
function quickPipes.enterWarp(p, w)
	local heldNPC = p.holdingNPC
	local cfg = data[p.idx]

	if (not w) or (not validityCheck(w, p)) then return end

	-- not enough stars
	if mem(0x00B251E0, FIELD_WORD) < w.starsRequired then
		local s = quickPipes.starMessage[math.min(w.starsRequired, 2)]

		Text.showMessageBox(string.format(s, w.starsRequired))

		return
	end

	local eventObj = {cancelled = false}

	quickPipes.onPipeEnter(eventObj, w, p)

	if eventObj.cancelled then return end

	if quickPipes.warpEnterSFX then
		SFX.play(quickPipes.warpEnterSFX)
	end

	-- release held item
	if not w.allowItems then
		p:mem(0x154, FIELD_WORD, 0)
	end

	--[[
	Misc.dialog(
		"filename:    "..tostring(w.levelFilename),
		"warp number: "..tostring(w.warpNumber),
		"from level:  "..tostring(w.fromOtherLevel),
		"to level:    "..tostring(w.toOtherLevel)
	)
	]]

	-- handle keys
	if w.locked then
		if heldNPC and heldNPC.id == 31 then
			Effect.spawn(10, heldNPC.x + heldNPC.width/2, heldNPC.y + heldNPC.height/2)
			heldNPC:kill()
		else
			p:mem(0x12, FIELD_BOOL, false)
		end

		w.locked = false
	end

	-- exitDirection doesn't work the same as entranceDirection
	-- entranceDirection is 1, 2, 3, 4: up, left, down, right
	-- but exitDirection is 1, 2, 3, 4: down, right, up, left

	cfg.warpEntryDirection = w.entranceDirection
	cfg.warpExitDirection = ((w.exitDirection + 1 ) % 4) + 1

	setupCFG(cfg, cfg.warpEntryDirection, cfg.warpExitDirection)

	cfg.currentWarp = w
	cfg.sfxPlayed = false

	if w.toOtherLevel then
		savedata.filename = w.levelFilename
		savedata.entryDirection = cfg.warpEntryDirection
		savedata.exitDirection = cfg.warpExitDirection
	else
		resetData(savedata)
	end

	p:mem(0x15E, FIELD_WORD, w.idx + 1)
	p.forcedState = FORCEDSTATE_PIPE
	p.forcedTimer = 0

	return true
end

function quickPipes.enterLogic(p, w, forced)
	local cfg = data[p.idx]

	if (w and w.warpType == 1) and (w.entranceSection == w.exitSection or quickPipes.allowCrossSections) then
		p:mem(0x15C, FIELD_WORD, 2)

		local canEnterPipe = warpingConditions[w.entranceDirection](
			w.entranceX,
			w.entranceY,
			w.entranceX + w.entranceWidth,
			w.entranceY + w.entranceHeight,
		p) or forced

		if canEnterPipe and p.forcedState == 0 and (not cfg.enteredPipe) then
			cfg.enteredPipe = quickPipes.enterWarp(p, w) or false

			if cfg.enteredPipe then
				quickPipes.onPostPipeEnter(w, p)
				p:mem(0x4A, FIELD_BOOL, false)
				return true
			end
		end
	end

	return false
end

-- used to render the star counter on the warp
function quickPipes.renderCounter(w, p, c)
	if w:mem(0x8C, FIELD_WORD) == 0 then return end
	
	local text = w:mem(0x8A, FIELD_WORD).."/"..w:mem(0x8C, FIELD_WORD)
	local starImg = quickPipes.images.star
	local crossImg = quickPipes.images.cross

	local width = (starImg.width + crossImg.width + 8 + #text * 18)
	local x = p.x + p.width/2 - width/2
	local y = math.min(w.entranceY + w.entranceHeight, p.y + p.height) - 96
	local priority = -5

	Graphics.drawImageToSceneWP(starImg, x, y, priority)
	Graphics.drawImageToSceneWP(crossImg, x + starImg.width + 4, y + 2, priority)
	
	Text.printWP(text, x + starImg.width + crossImg.width + 8 - c.x, y - c.y, priority)
end

-- used to render lock and star icons
function quickPipes.renderIcons(w, c)
	local priority = -64.9
	local offset = quickPipes.iconOffsets[w.entranceDirection]
	local images = quickPipes.images

	-- stars
	if mem(0x00B251E0, FIELD_WORD) < w.starsRequired then
		drawIcon(w, images.starIcon, offset.star, priority, c)
	end

	-- locks
	if w.locked then
		drawIcon(w, images.lockIcon, offset.lock, priority, c)
	end
end

-- register events
function quickPipes.onInitAPI()
	registerEvent(quickPipes, "onTick")
	registerEvent(quickPipes, "onCameraDraw")

	registerCustomEvent(quickPipes, "onPipeEnter") -- runs before any changes happen, can be cancelled
	registerCustomEvent(quickPipes, "onPostPipeEnter") -- runs after successfully entered, can't be cancelled

	registerCustomEvent(quickPipes, "onPipeExit") -- runs before anything happens, can't be cancelled
	registerCustomEvent(quickPipes, "onPostPipeExit") -- runs after everything happened, can't be cancelled
end

-- main logic
function quickPipes.onTick()
	for _, p in ipairs(Player.get()) do

		local cfg = initData(p.idx)

		-- entering pipes
		if quickPipes.enabled then
			if p.forcedState == FORCEDSTATE_PIPE and savedata.filename == fileName then
				cfg.enteredPipe = true
				setupCFG(cfg, savedata.entryDirection, savedata.exitDirection)
				resetData(savedata)
			end

			for k, w in ipairs(Warp.getIntersectingEntrance(
				(p.x - 4) + p.speedX,
				(p.y - 4) + p.speedY,
				(p.x - 4) + (p.width + 4) + p.speedX,
				(p.y - 4) + (p.height + 4) + p.speedY
			)) do
				
				local entered = quickPipes.enterLogic(p, w, false)

				if entered then
					break
				end
			end
		end

		-- movement
		if cfg.enteredPipe then

			-- just got outside
			if p.forcedState ~= FORCEDSTATE_PIPE then
				quickPipes.onPipeExit(cfg.currentWarp, p)

				p.speedX = cfg.exitBoost.x
				p.speedY = cfg.exitBoost.y

				cfg.enteredPipe = false
				
				cfg.warpEntryDirection = 0
				cfg.warpExitDirection = 0

				cfg.warpEntrySign = vector(0, 0)
				cfg.warpExitSign = vector(0, 0)
				cfg.exitBoost = vector(0, 0)
				cfg.waitTimer = 0

				quickPipes.onPostPipeExit(cfg.currentWarp, p)

				cfg.currentWarp = nil

			-- inside
			else

				-- entering
				if p.forcedTimer <= 0 then
					p.x = p.x + cfg.warpSpeedEntry.x - 0.5 * cfg.warpEntrySign.x
					p.y = p.y + cfg.warpSpeedEntry.y - cfg.warpEntrySign.y

				-- exiting
				elseif cfg.waitTimer > quickPipes.waitTime then
					p.x = p.x + cfg.warpSpeedExit.x - 0.5 * cfg.warpExitSign.x
					p.y = p.y + cfg.warpSpeedExit.y - cfg.warpExitSign.y

				-- waiting
				else
					cfg.waitTimer = cfg.waitTimer + 1

					if cfg.waitTimer == quickPipes.waitTime and quickPipes.warpExitSFX then
						SFX.play(quickPipes.warpExitSFX)
					end
				end
			end
		end
	end
end

-- render counters
function quickPipes.onCameraDraw(camIdx)
	if not quickPipes.enabled then return end

	for k, w in ipairs(Warp.get()) do
		local colPlayers = Player.getIntersecting(
			w.entranceX,
			w.entranceY,
			w.entranceX + w.entranceWidth,
			w.entranceY + w.entranceHeight
		)

		local p = colPlayers[#colPlayers]

		if w.warpType == 1 and (not w.isHidden) and (not w.fromOtherLevel) then
			if quickPipes.drawIcons then
				quickPipes.renderIcons(w, Camera(camIdx))
			end

			if p and p.forcedState == 0 and (not data[p.idx].enteredPipe) and quickPipes.drawCounter then
				quickPipes.renderCounter(w, p, Camera(camIdx))
			end
		end
	end
end

return quickPipes