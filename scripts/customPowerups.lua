--[[
    By Marioman2007 [v1.1]
    uses code from anotherpowerup.lua by Emral
]]

SaveData.customPowerups = SaveData.customPowerups or {}

local pm = require("playerManager")
local npcManager = require("npcManager")

local savedata = SaveData.customPowerups
local testModeMenu

if Misc.inEditor() then
    testModeMenu = require("engine/testmodemenu")
end

local apdl
pcall(function() apdl = require("anotherPowerDownLibrary") end)

local cp = {}

cp.powerUpForcedState = 754
cp.powerDownForcedState = 755
cp.mapLevelFilename = "map.lvlx" -- compatibility with level based map such as smwMap

local testMenuWasActive = false
local wasPaused = false
local powerMap = {}
local powerNames = {}
local itemMap = {}
local blacklistedChars = {}
local playerData = {}
local savedataCleared = false

local transformations = {}
local apFields = {"apSounds", "onTick", "onTickEnd", "onDraw"}
local apFieldsReplacement = {"collectSounds", "onTickPowerup", "onTickEndPowerup", "onDrawPowerup"}

local defaultItemMap = {
    [9]   = PLAYER_BIG,
    [184] = PLAYER_BIG,
    [185] = PLAYER_BIG,
    [249] = PLAYER_BIG,
    [250] = PLAYER_BIG,

    [14]  = PLAYER_FIREFLOWER,
    [182] = PLAYER_FIREFLOWER,
    [183] = PLAYER_FIREFLOWER,

    [264] = PLAYER_ICE,
    [277] = PLAYER_ICE,

    [34]  = PLAYER_LEAF,
    [169] = PLAYER_TANOOKIE,
    [170] = PLAYER_HAMMER,
}


------------------------
-- Internal Functions --
------------------------

local function loadAssets(lib, p)
    if not lib then return end

    local iniFile = lib.iniFiles[p.character] or pm.getHitboxPath(p.character, lib.basePowerup)

    Misc.loadCharacterHitBoxes(p.character, lib.basePowerup, iniFile)
    Graphics.sprites[pm.getName(p.character)][lib.basePowerup].img = lib.spritesheets[p.character]
end

local function resetAssets(id, char)
    Misc.loadCharacterHitBoxes(char, id, pm.getHitboxPath(char, id))
    Graphics.sprites[pm.getName(char)][id].img = nil
end

local function SFXPlay(lib, name)
    if lib and lib.collectSounds and lib.collectSounds[name] then
        SFX.play(lib.collectSounds[name])
    end
end

local function isOnMap()
    return isOverworld or Level.filename() == cp.mapLevelFilename
end

local function initData(p)
    playerData[p.idx] = {
        currentPowerup = {},
        oldPowerup = {},
        oldCharacter = p.character,
        lastPowerup = {},
        assetLoaded = false,
        checkedThisFrame = false
    }

    savedata[p.idx] = savedata[p.idx] or {}
end


----------------------------
-- External Use Functions --
----------------------------

-- makes a powerup made for anotherpowerup usable for custom powerup
function cp.convertApPowerup(lib)
    for k, field in ipairs(apFields) do
        if lib[field] then
            lib[apFieldsReplacement[k]] = lib[field]
            lib[field] = nil
        end
    end

    for char, img in ipairs(lib.spritesheets) do
        lib.iniFiles[char] = lib.iniFiles[char] or Misc.resolveFile(pm.getName(char).."-"..lib.name..".ini")
    end
end

-- makes the powerup transform to the given powerup when the player is small
function cp.transformWhenSmall(id, replacement)
    transformations[id] = replacement
end

-- adds a powerup, do not use the doConversion and id arguments
function cp.addPowerup(name, lib, items, doConversion, id)
    if type(name) == "table" then
        lib = name.lib
        items = name.items
        doConversion = name.doConversion
        id = name.id
        name = name.name
    end

    if not name then
        error("Invalid name for a powerup.")
        return
    end

    if type(items) == "number" then
        items = {items}
    end

    local libPath = lib or name

    if type(libPath) ~= "string" then
        error("Invalid library path.")
        return
    end

    lib = require(libPath)
    items = items or {}

    lib.name = name
    lib.id = id or (#powerNames + 7) -- for the default powerups
    lib.items = lib.items or {}
    lib.basePowerup = lib.basePowerup or PLAYER_FIREFLOWER
    lib.collectSounds = lib.collectSounds or lib.apSounds or {upgrade = 6, reserve = 12}

    lib.spritesheets = lib.spritesheets or {}
    lib.iniFiles = lib.iniFiles or {}

    if doConversion then
        cp.convertApPowerup(lib)
        lib._forceProjectileTimer = true
    end

    for k, v in ipairs(items) do
        table.insert(lib.items, v)
    end

    for k, v in ipairs(lib.items) do
        itemMap[v] = name
    end

    table.insert(powerNames, name)
    powerMap[name] = lib

    if lib.onInitPowerupLib then
        lib.onInitPowerupLib()
    end

    if not isOnMap() and not savedataCleared then
        savedata.powerupList = {}
        savedataCleared = true
    end

    if not isOnMap() then
        table.insert(savedata.powerupList, {name = name, lib = libPath, items = items, doConversion = doConversion, id = id})
    end

    return lib
end

-- sets the powerup
function cp.setPowerup(name, p, noEffects)
    local data = playerData[p.idx]
    local canPlay = false
    local replacement = blacklistedChars[p.character] or {}
    
    if type(replacement) == "string" then
        name = replacement
    elseif replacement[name] then
        name = replacement[name]
    end

    if not data or name == "none" then return end

    local lib = powerMap[name]
    local currentPowerup = data.currentPowerup[p.character]

    if type(name) == "number" then
        if currentPowerup then
            resetAssets(currentPowerup.basePowerup, p.character)

            if currentPowerup.onDisable then
                currentPowerup.onDisable(p)
            end
        end

        data.currentPowerup[p.character] = nil
        p.powerup = name
        savedata[p.idx][p.character] = nil
        return
    end

    if not lib then return end

    if not noEffects then
        if (currentPowerup and currentPowerup.name == name) then
            SFXPlay(currentPowerup, "reserve")
            return
        else
            canPlay = true
            p.forcedState = cp.powerUpForcedState
            p.forcedTimer = 0

            -- offset fixing
            if p.powerup == 1 and lib.basePowerup > 1 then
                local ps1 = PlayerSettings.get(pm.getBaseID(p.character), 1)
                local ps2 = PlayerSettings.get(pm.getBaseID(p.character), 2)

                p.powerup = 2
                p.height = ps2.hitboxHeight
                p.y = p.y - (ps2.hitboxHeight - ps1.hitboxHeight)
            end

            data.oldPowerup[p.character] = currentPowerup or p.powerup
        end
    end

    if currentPowerup and name ~= currentPowerup.name then
        resetAssets(currentPowerup.basePowerup, p.character)

        if currentPowerup.onDisable then
            currentPowerup.onDisable(p)
        end
    end

    data.currentPowerup[p.character] = lib
    currentPowerup = data.currentPowerup[p.character]
    p.powerup = lib.basePowerup
    savedata[p.idx][p.character] = lib.name
    loadAssets(currentPowerup, p)
    data.lastPowerup[p.character] = lib.name

    if currentPowerup.onEnable then
        currentPowerup.onEnable(p)
    end

    if canPlay then
        SFXPlay(currentPowerup, "upgrade")
    end
end

-- blacklists a character from using a powerup/all powerups, you can optionally specify a replacement powerup
function cp.blacklistCharacter(char, name, replacement)
    if name and type(blacklistedChars[char]) ~= "string" then
        blacklistedChars[char] = blacklistedChars[char] or {}
        blacklistedChars[char][name] = replacement or "none"
    else
        blacklistedChars[char] = replacement or "none"
    end
end

-- whitelists a character for using a powerup/all powerups
function cp.whitelistCharacter(char, name)
    if type(blacklistedChars[char]) == "string" then
        blacklistedChars[char] = nil
    elseif name then
        blacklistedChars[char][name] = nil
    end
end

-- returns the custom data table of the player
function cp.getData(idx)
    if idx then
        return playerData[idx]
    end

    return playerData
end

-- returns the current powerup
function cp.getCurrentPowerup(p)
    return playerData[p.idx].currentPowerup[p.character]
end

-- returns the name of the current powerup
function cp.getCurrentName(p)
    local currentPowerup = cp.getCurrentPowerup(p)

    if currentPowerup then
        return currentPowerup.name
    end

    return p.powerup
end

-- returns the id of the current powerup
function cp.getCurrentID(p)
    local currentPowerup = cp.getCurrentPowerup(p)

    if currentPowerup then
        return currentPowerup.id
    end

    return p.powerup
end

-- returns a list of powerup names
function cp.getNames()
    return powerNames
end

-- returns a table of powerup libraries indexed by names, if name is provided, it will return the powerup of that name
function cp.getPowerupByName(n)
    if n then
        return powerMap[n]
    end
end

-- returns a powerup by an item
function cp.getPowerupByItem(id)
    if id then
        return itemMap[id]
    end
end

-- adds a item id or a list of ids to a powerup
function cp.addItem(ids, name)
    if not name or not powerMap[name] then
        error("Powerup named '"..name.."' does not exist.")
    end

    local lib = powerMap[name]

    if type(ids) == "number" then
        ids = {ids}
    end

    for k, v in ipairs(ids) do
        if not itemMap[v] then
            table.insert(lib.items, v)
            itemMap[v] = name
        end
    end
end


-----------------------------
-- Compatibility Functions --
-----------------------------

-- These functions are here to have compatibility with powerups made from anotherpowerup.lua
-- Use their counterparts if you're not working with anotherpowerup

-- counterpart: cp.addPowerup(name, lib, items)
function cp.registerPowerup(name)
    cp.addPowerup(name, name, nil, true)
end

-- counterpart: cp.transformWhenSmall(id, replacement)
function cp.registerItemTier(id)
    cp.transformWhenSmall(id, 9)
end

-- counterpart: cp.setPowerup(name, p, noEffects)
function cp.setPlayerPowerup(appower, silent, thisPlayer)
    cp.setPowerup(appower.name, thisPlayer or player, silent)
end

-- counterpart: cp.getCurrentName(p)
function cp.getPowerup(p)
    cp.getCurrentName(p or player)
end


-----------------------
-- Library Functions --
-----------------------

local function handleChanges(p, data, currentPowerup)
    if data.oldCharacter ~= p.character then
        local currentOldPowerup = data.currentPowerup[data.oldCharacter]

        if currentOldPowerup then
            resetAssets(currentOldPowerup.basePowerup, data.oldCharacter)

            if currentOldPowerup.onDisable then
                currentOldPowerup.onDisable(p)
            end
        end

        if savedata[p.idx][p.character] then
            cp.setPowerup(savedata[p.idx][p.character], p, true)
            currentPowerup = data.currentPowerup[p.character]
        end

        data.oldCharacter = p.character
    end

    if (((currentPowerup and p.powerup ~= currentPowerup.basePowerup) or (data.lastPowerup[p.character] ~= cp.getCurrentName(p)))
    and p.forcedState == 0) or p.deathTimer > 0
    then
        if currentPowerup then
            resetAssets(currentPowerup.basePowerup, p.character)

            if currentPowerup.onDisable then
                currentPowerup.onDisable(p)
            end
        end

        data.currentPowerup[p.character] = nil
        savedata[p.idx][p.character] = nil
    end
end

-- register events
function cp.onInitAPI()
    registerEvent(cp, "onStart")
    registerEvent(cp, "onDraw")

    if not isOnMap() then
        registerEvent(cp, "onTick")
        registerEvent(cp, "onTickEnd")
        registerEvent(cp, "onNPCCollect")
        registerEvent(cp, "onPostNPCKill")
        registerEvent(cp, "onPlayerHarm")
        registerEvent(cp, "onBlockHit")
    end
end

-- force powerups to mushrooms
function cp.onBlockHit(e, v, upper, p)
    local nextID = transformations[v.contentID - 1000]
    
    if e.cancelled or not nextID or v.data._custom_alreadyCancelled then return end

    if not p then
        for _, n in NPC.iterateIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1) do
			if n:mem(0x132,FIELD_WORD) > 0 and n:mem(0x136,FIELD_BOOL) then
				p = Player(n:mem(0x132,FIELD_WORD))
			end
		end
    end

    p = p or player

    if p.powerup == 1 then
		v.contentID = nextID + 1000
        v.data._custom_alreadyCancelled = true
        v:hit(upper, p)
        e.cancelled = true
	end
end

-- carry powerups between levels
function cp.onStart()
    if isOnMap() and savedata.powerupList then
        for k, args in ipairs(savedata.powerupList) do
            cp.addPowerup(args)
        end
    end

    for _, p in ipairs(Player.get()) do
        initData(p)

        if Misc.inEditor() then
            savedata[p.idx] = {}
        end

        if savedata[p.idx][p.character] then
            cp.setPowerup(savedata[p.idx][p.character], p, true)
        end
    end
end

-- data initialization and forced state mangement
function cp.onTick()
    for _, p in ipairs(Player.get()) do
        if not playerData[p.idx] then
            initData(p)
        end

        local data = playerData[p.idx]
        local currentPowerup = data.currentPowerup[p.character]

        if currentPowerup and currentPowerup.onTickPowerup then
            currentPowerup.onTickPowerup(p)
        end

        if currentPowerup and currentPowerup._forceProjectileTimer and p.mount < 2 then
            if p.character ~= CHARACTER_LINK then
                p:mem(0x160, FIELD_WORD, 3)
            else
                p:mem(0x162, FIELD_WORD, 29)
            end
        end

        -- powering up
        if p.forcedState == cp.powerUpForcedState then
            p.forcedTimer = math.min(p.forcedTimer + 1, 50)

            local frame = math.floor(p.forcedTimer / 5) % 2

            if p.forcedTimer == 50 then
                p.forcedState = 0
                p.forcedTimer = 0
                data.assetLoaded = false
                p:mem(0x140, FIELD_WORD, 50)
                data.oldPowerup[p.character] = nil
                loadAssets(currentPowerup, p)

            elseif frame == 0 and not data.assetLoaded then
                local oldPowerup = data.oldPowerup[p.character]
                data.assetLoaded = true

                if type(oldPowerup) ~= "number" then
                    local iniFile = oldPowerup.iniFiles[p.character] or pm.getHitboxPath(p.character, oldPowerup.basePowerup)

                    Misc.loadCharacterHitBoxes(p.character, currentPowerup.basePowerup, iniFile)
                    Graphics.sprites[pm.getName(p.character)][currentPowerup.basePowerup].img = oldPowerup.spritesheets[p.character]

                else
                    local replacement = nil

                    if oldPowerup ~= currentPowerup.basePowerup then
                        replacement = Graphics.sprites[pm.getName(p.character)][oldPowerup].img
                    end

                    Misc.loadCharacterHitBoxes(p.character, currentPowerup.basePowerup, pm.getHitboxPath(p.character, oldPowerup))
                    Graphics.sprites[pm.getName(p.character)][currentPowerup.basePowerup].img = replacement
                end

            elseif frame == 1 and data.assetLoaded then
                data.assetLoaded = false
                loadAssets(currentPowerup, p)

            end
        elseif p.forcedState == cp.powerDownForcedState then
            p.forcedTimer = math.min(p.forcedTimer + 1, 50)

            local frame = math.floor(p.forcedTimer / 5) % 2

            if p.forcedTimer == 50 then
                p.forcedState = 0
                p.forcedTimer = 0
                data.assetLoaded = false
                p:mem(0x140, FIELD_WORD, 50)

                resetAssets(currentPowerup.basePowerup, p.character)

                if currentPowerup.onDisable then
                    currentPowerup.onDisable(p)
                end
        
                data.currentPowerup[p.character] = nil
                savedata[p.idx][p.character] = nil

            elseif frame == 0 and not data.assetLoaded then
                data.assetLoaded = true
                loadAssets(currentPowerup, p)

            elseif frame == 1 and data.assetLoaded then
                data.assetLoaded = false
                resetAssets(currentPowerup.basePowerup, p.character)

            end
        end
    end
end

-- character/powerup changes
function cp.onTickEnd()
    for _, p in ipairs(Player.get()) do
        local data = playerData[p.idx]
        
        if data then
            local currentPowerup = data.currentPowerup[p.character]

            if currentPowerup and currentPowerup.onTickEndPowerup then
                currentPowerup.onTickEndPowerup(p)
            end

            handleChanges(p, data, currentPowerup)
            data.checkedThisFrame = true
        end
    end
end

-- test mode menu
function cp.onDraw()
    for _, p in ipairs(Player.get()) do
        local data = playerData[p.idx]

        if data then
            local currentPowerup = data.currentPowerup[p.character]

            -- Fight test mode menu
            if (Misc.inEditor() and (testModeMenu.active or (not testModeMenu.active and testMenuWasActive))) or lunatime.tick() == 1 or lunatime.drawtick() == 1 then
                loadAssets(currentPowerup, p)
            end

            if not data.checkedThisFrame then
                handleChanges(p, data, currentPowerup)
                data.checkedThisFrame = true
            end

            data.checkedThisFrame = false

            if isOnMap() then
                if isOverworld and (Misc.isPaused() or (not Misc.isPaused() and wasPaused) or (Misc.isPaused() and not wasPaused)) then
                    loadAssets(currentPowerup, p)
                end
            else
                if currentPowerup and currentPowerup.onDrawPowerup then
                    currentPowerup.onDrawPowerup(p)
                end
            end
        end

        --[[
        Text.print("vanilla: "..p:mem(0x46, FIELD_WORD), 0, 0)
        Text.print(cp.getCurrentID(p), 0, 30)
        Text.print(savedata[p.idx][p.character],0,60)

        Graphics.drawBox{
            x = p.x, y = p.y,
            width = p.width,
            height = p.height,
            sceneCoords = true,
            color = Color.blue..0.5,
        }
        ]]
    end

    if Misc.inEditor() then
        testMenuWasActive = testModeMenu.active
    end

    wasPaused = Misc.isPaused()
end

-- item collection stuff
function cp.onNPCCollect(e, v, p)
    if not playerData[p.idx] or e.cancelled or v.data._custom_thing then
        return
    end

    local currentPowerup = cp.getCurrentPowerup(p)
    local vanillaPower = defaultItemMap[v.id]
    local powerName = itemMap[v.id]
    local initalStateItem = p:mem(0x46, FIELD_WORD)

    -- check if the npc collected sets the player's powerup to the base powerup of the current custom powerup
    if currentPowerup and vanillaPower == currentPowerup.basePowerup and vanillaPower ~= PLAYER_BIG then
        p.forcedState = cp.powerDownForcedState
        p.forcedTimer = 0
        e.cancelled = true

        -- prevent the reserve item sfx from playing and also handle reserve box stuff
        local oldStateItem = p:mem(0x46, FIELD_WORD)
        local oldMuted = Audio.sounds[12].muted

        Audio.sounds[12].muted = true
        v.data._custom_thing = true
        v:collect(p)
        p.reservePowerup = 0
        SFX.play(6)

        p:mem(0x46, FIELD_WORD, oldStateItem)
        Audio.sounds[12].muted = oldMuted
    end

    -- update hearts and state item
    if vanillaPower or powerName then
        if Graphics.getHUDType(p.character) == Graphics.HUD_HEARTS and not vanillaPower then
            p:mem(0x16, FIELD_WORD, p:mem(0x16, FIELD_WORD) + 1)
        end

        if vanillaPower == PLAYER_BIG and p.powerup == 1 then
            p:mem(0x46, FIELD_WORD, v.id)

        elseif vanillaPower ~= PLAYER_BIG then
            if p.powerup > 1 and p:mem(0x46, FIELD_WORD) > 0 then
                p.reservePowerup = p:mem(0x46, FIELD_WORD)
                v.data._custom_queued = true

                playerData[p.idx].queuePowerup = p.reservePowerup
            end
    
            p:mem(0x46, FIELD_WORD, v.id)
        end
    end

    -- set the player's powerup
    if powerName then
        if p.powerup == PLAYER_BIG and initalStateItem == 0 and p.reservePowerup == 0 then
            p.reservePowerup = 9
        end

        cp.setPowerup(powerName, p)
        p:mem(0x46, FIELD_WORD, v.id)

        if v:mem(0x138, FIELD_WORD) ~= 2 then
            Misc.givePoints(NPC.config[v.id].score, vector(p.x, p.y), true)
        end
    end
end

-- fix the players' reserve powerup
function cp.onPostNPCKill(v, r)
    local p = npcManager.collected(v, r)

    if not p or not playerData[p.idx] or not v.data._custom_queued then
        return
    end

    local data = playerData[p.idx]

    if data.queuePowerup then
        p.reservePowerup = data.queuePowerup
        data.queuePowerup = nil
    end
end

-- handle last collected item
function cp.onPlayerHarm(e, p)
    if not playerData[p.idx] or not apdl or p.powerup <= 2 then return end
    p:mem(0x46, FIELD_WORD, 9)
end

return cp