--[[

	Written by MrDoubleA
	Please give credit!

	Sleeping Galoomba Concept and Graphics by Thomas (https://www.smwcentral.net/?p=section&a=details&id=24079)

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local galoomba = {}


galoomba.TYPE = {
    NORMAL = 0,
    STUNNED = 1,
    WINGED = 2,
    SLEEPING = 3,
    SLEEPING_WINGED = 4,
}

local normalTypes = table.map{galoomba.TYPE.NORMAL,galoomba.TYPE.SLEEPING}
local wingedTypes = table.map{galoomba.TYPE.WINGED,galoomba.TYPE.SLEEPING_WINGED}
local sleepingTypes = table.map{galoomba.TYPE.SLEEPING,galoomba.TYPE.SLEEPING_WINGED}


galoomba.sharedSettings = {
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = false,
	
	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

    luahandlesspeed = true,
}


galoomba.idList = {}
galoomba.idMap  = {}


function galoomba.register(npcID)
	npcManager.registerEvent(npcID, galoomba, "onTickEndNPC")
    npcManager.registerEvent(npcID, galoomba, "onDrawNPC")

    table.insert(galoomba.idList,npcID)
    galoomba.idMap[npcID] = true
end

function galoomba.onInitAPI()
    registerEvent(galoomba,"onNPCHarm")
end


local function initialise(v,data,config)
    data.initialized = true

    data.timer = 0
    data.hopCounter = 0

    data.rotation = 0

    data.isSleeping = (not not sleepingTypes[config.galoombaType])

    data.dontWalk = false

    data.animationTimer = 0
    data.wingAnimationTimer = 0
end


local function getPlayerDistance(v)
    local closestPlayer
    local closestDistance = math.huge
    local closestXDistance = math.huge
    local closestYDistance = math.huge

    for _,p in ipairs(Player.get()) do
        if p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) then
            local xDistance = (p.x + p.width *0.5) - (v.x + v.width *0.5)
            local yDistance = (p.y + p.height*0.5) - (v.y + v.height*0.5)
            local totalDistance = math.sqrt(xDistance*xDistance + yDistance*yDistance)

            if totalDistance < closestDistance then
                closestPlayer = p
                closestDistance = totalDistance
                closestXDistance = xDistance
                closestYDistance = yDistance
            end
        end
    end

    return closestPlayer,closestDistance,closestXDistance,closestYDistance
end


local function doStun(v,data,config)
    if config.stunnedID ~= nil then
        v:transform(config.stunnedID)
    end
    config = NPC.config[v.id]

    initialise(v,data,config)

    v.speedX = 0
    v.speedY = config.kickedSpeedY

    v:mem(0x136,FIELD_BOOL,true)

    data.rotation = 180 * v.direction
end

local function kickStunned(v,data,config, culprit)
    if type(culprit) == "Player" then
        if v.x+v.width*0.5 < culprit.x+culprit.width*0.5 then
            v.direction = DIR_LEFT
        else
            v.direction = DIR_RIGHT
        end

        v:mem(0x12E,FIELD_WORD,10)
        v:mem(0x130,FIELD_WORD,culprit.idx)
    end

    v:mem(0x136,FIELD_BOOL,true)

    v.speedX = config.kickedSpeedX * v.direction
    v.speedY = config.kickedSpeedY

    SFX.play(9)
end

local function handleAnimation(v,data,config)
    local direction = v.direction
    local frame = 0

    local shakeTimer = 0


    -- Find frame
    if config.galoombaType == galoomba.TYPE.STUNNED then
        shakeTimer = (data.timer - (config.recoverTime - config.shakeTime))
    end
        

    local frameCount = config.frames / (config.wingFrames or 1)

    frame = math.floor(data.animationTimer / config.framespeed)

    if sleepingTypes[config.galoombaType] then
        if data.isSleeping then
            if config.sleepFrames > 1 then
                frame = math.floor(data.animationTimer / config.sleepFramespeed) % (config.sleepFrames*2 - 2)

                if frame >= config.sleepFrames then
                    frame = config.sleepFrames - (frame - config.sleepFrames) - 2
                end
            else
                frame = 0
            end
        else
            frame = (frame % (frameCount - config.sleepFrames)) + config.sleepFrames
        end
    else
        frame = frame % frameCount
    end

    if wingedTypes[config.galoombaType] then
        if data.isSleeping then
            frame = frame + (config.wingFrames - 1)*frameCount
        else
            frame = frame + (math.floor(data.wingAnimationTimer / config.wingFramespeed) % config.wingFrames)*frameCount
        end
    end


    -- Advance animation
    if shakeTimer > 0 or data.dontWalk then
        data.animationTimer = data.animationTimer + 2
    elseif sleepingTypes[config.galoombaType] and math.sign(v.speedX) ~= v.direction and not data.isSleeping then
        data.animationTimer = data.animationTimer + 1.5
    else
        data.animationTimer = data.animationTimer + 1
    end

    if wingedTypes[config.galoombaType] then
        if data.isSleeping then
            data.wingAnimationTimer = 0
        elseif data.hopCounter >= config.hopCount then -- final jump
            data.wingAnimationTimer = data.wingAnimationTimer + 2
        elseif data.hopCounter > 0 then -- hopping
            data.wingAnimationTimer = data.wingAnimationTimer + 1
        else -- walking
            data.wingAnimationTimer = 0
        end
    end


    -- Update rotation
    if shakeTimer > 0 then
        data.rotation = math.sin((shakeTimer / 12) * math.pi * 2) * 25
    else
        if data.rotation > 0 then
            data.rotation = math.max(0,data.rotation - 14)
        else
            data.rotation = math.min(0,data.rotation + 14)
        end

        if math.abs(data.rotation) >= 90 then
            direction = -direction
        end
    end
    

    v.animationFrame = npcutils.getFrameByFramestyle(v,{frame = frame,direction = direction})
end


function galoomba.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

    local config = NPC.config[v.id]

	if not data.initialized then
		initialise(v,data,config)
	end


    if config.galoombaType == galoomba.TYPE.STUNNED and v:mem(0x138,FIELD_WORD) == 0 then
        -- Slow it down
        if v:mem(0x12C,FIELD_WORD) == 0 then
            if v.collidesBlockBottom then
                if v.speedX > 0 then
                    v.speedX = math.max(0,v.speedX - 0.35)
                elseif v.speedX < 0 then
                    v.speedX = math.min(0,v.speedX + 0.35)
                end
            else
                if v.speedX > 0 then
                    v.speedX = math.max(0,v.speedX - 0.05)
                elseif v.speedX < 0 then
                    v.speedX = math.min(0,v.speedX + 0.05)
                end
            end

            -- Reset timer if .CantHurt > 0
            if v:mem(0x12E,FIELD_WORD) > 0 then
                data.timer = 0
            end
        end

        -- Wake up
        data.timer = data.timer + 1

        if data.timer >= config.recoverTime and v.collidesBlockBottom then
            -- Jump out of player's arms
            if v:mem(0x12C,FIELD_WORD) > 0 then
                local p = Player(v:mem(0x12C,FIELD_WORD))

                p:harm()

                p:mem(0x154,FIELD_WORD,0)
                v:mem(0x12C,FIELD_WORD,0)
            end

            v.speedY = config.recoverHopSpeed
            v.collidesBlockBottom = false

            v:transform(config.recoverID)
            initialise(v,data,config)
            config = NPC.config[v.id]

            data.rotation = 180 * v.direction
            data.dontWalk = true

            data.isSleeping = false
        end
    end


	if v:mem(0x12C, FIELD_WORD) > 0 -- Grabbed
	or v:mem(0x136, FIELD_BOOL)     -- Thrown
	or v:mem(0x138, FIELD_WORD) > 0 -- Contained within
	then
        handleAnimation(v,data,config)
        return
    end

	
    if config.galoombaType ~= galoomba.TYPE.STUNNED then
        if data.dontWalk then
            data.dontWalk = (data.dontWalk and not v.collidesBlockBottom)
        elseif sleepingTypes[config.galoombaType] then
            local closestPlayer,totalDistance,xDistance,yDistance = getPlayerDistance(v)

            if data.isSleeping then
                if totalDistance <= config.wakeDistance then
                    v.speedX = 0
                    v.speedY = config.wakeUpSpeed

                    data.isSleeping = false
                    data.dontWalk = true
                else
                    if v.speedX > 0 then
                        v.speedX = math.max(0,v.speedX - config.deceleration)
                    else
                        v.speedX = math.min(0,v.speedX + config.deceleration)
                    end
                end
            else
                if totalDistance > config.sleepDistance then
                    data.isSleeping = true
                else
                    if xDistance ~= 0 then
                        v.direction = math.sign(xDistance)
                    end

                    v.speedX = math.clamp(v.speedX + config.acceleration*v.direction,-config.speed,config.speed)

                    if v:mem(0x120,FIELD_BOOL) and (v.collidesBlockBottom or v.speedY > 0) then
                        v.speedY = -3
                    end
                end
            end
        else
            v.speedX = config.speed * v.direction
        end

        -- Hopping
        if wingedTypes[config.galoombaType] and not data.dontWalk and not data.isSleeping and v.collidesBlockBottom then
            data.timer = data.timer + 1

            if data.timer >= config.preHopTime then
                data.hopCounter = data.hopCounter + 1

                if data.hopCounter > config.hopCount then
                    data.timer = 0
                    data.hopCounter = 0

                    if config.hopTurnsAround then
                        v.direction = -v.direction
                    end
                elseif data.hopCounter >= config.hopCount then
                    v.speedY = config.hopSpeedBig
                else
                    v.speedY = config.hopSpeedSmall
                end
            end
        end
    else
        for _,p in ipairs(Player.getIntersecting(v.x,v.y,v.x+v.width,v.y+v.height)) do
            if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)
            and (v:mem(0x12E,FIELD_WORD) <= 0 or v:mem(0x130,FIELD_WORD) ~= p.idx)
            then
                kickStunned(v,data,config,p)
            end
        end
    end

    handleAnimation(v,data,config)
end


local lowPriorityStates = table.map{1,3,4}

function galoomba.onDrawNPC(v)
    if v.despawnTimer <= 0 or v.isHidden then return end

    local config = NPC.config[v.id]
    local data = v.data

    if not data.initialized then
		initialise(v,data,config)
	end


    local texture = Graphics.sprites.npc[v.id].img

    if data.sprite == nil or data.sprite.texture ~= texture then
        data.sprite = Sprite{texture = texture,frames = npcutils.getTotalFramesByFramestyle(v),pivot = Sprite.align.CENTRE}
    end

    local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

    data.sprite.x = v.x + v.width*0.5 + config.gfxoffsetx
    data.sprite.y = v.y + v.height - config.gfxheight*0.5 + config.gfxoffsety

    data.sprite.rotation = data.rotation

    data.sprite:draw{frame = v.animationFrame+1,priority = priority,sceneCoords = true}

    npcutils.hideNPC(v)
end


function galoomba.onNPCHarm(eventObj,v,reason,culprit)
    if not galoomba.idMap[v.id] then return end

    local config = NPC.config[v.id]
    local data = v.data

    if not data.initialized then
		initialise(v,data,config)
	end

    if reason == HARM_TYPE_JUMP then
        if normalTypes[config.galoombaType] then
            doStun(v,data,config)
            SFX.play(9)
        elseif wingedTypes[config.galoombaType] then
            v:transform(config.normalID)
            SFX.play(9)
        elseif config.galoombaType == galoomba.TYPE.STUNNED then
            kickStunned(v,data,config,culprit)
        end
        
        eventObj.cancelled = true
        return
    elseif reason == HARM_TYPE_FROMBELOW or reason == HARM_TYPE_TAIL then
        if v:mem(0x26,FIELD_WORD) == 0 then
            if config.galoombaType ~= galoomba.TYPE.STUNNED then
                doStun(v,data,config)
            else
                v:mem(0x136,FIELD_BOOL,true)
                data.timer = 0
            end

            SFX.play(9)

            v.speedY = -5

            v:mem(0x26,FIELD_WORD,10) 
        end

        eventObj.cancelled = true
        return
    end
end


return galoomba