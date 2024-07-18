--[[
    hudCreator.lua
    
    by Marioman2007
    version - 1.0

    A library designed for creation of HUDs.
    Not multiplayer compatible.

    Check exampleHud.lua for a guide on how to create your own hud.
    Check [documentation].txt for the docs.
]]

local textplus = require("textplus")
local defFont = textplus.loadFont("textplus/font/6.ini")

local hud = {}

hud.defaultPriority = 5
hud.disableVanillaHud = true
hud.leastOpacity = 0
hud.stillTime = 64 -- number of frames of standing still after which the hud can be visible again
hud.extraTime = 64 -- number of frames that get added to the still timer when the value updates

hud.AXIS_X = 1
hud.AXIS_Y = -1

hud.DIR_LEFT  = -1
hud.DIR_RIGHT = 1
hud.DIR_UP    = -1
hud.DIR_DOWN  = 1

hud.TYPE_MOVE      = -1
hud.TYPE_FADE      = 1
hud.TYPE_MOVE_FADE = 0

local nameList = {}
local data = {}
local levelfilename = (not isOverworld and Level.filename()) or ""
local isHudActive = true
local crossImg = Graphics.sprites.hardcoded["33-1"].img

local function getGlData(lenX, lenY)
    local pixelSizeX = 1/lenX
    local pixelSizeY = 1/lenY
    local vt = {}
    local tx = {
        pixelSizeX * 0, pixelSizeY * 5, -- corner 1
        pixelSizeX * 1, pixelSizeY * 2, -- corner 1
        pixelSizeX * 2, pixelSizeY * 1, -- corner 1
        pixelSizeX * 5, pixelSizeY * 0, -- corner 1

        pixelSizeX * (lenX-5), pixelSizeY * 0, -- corner 2
        pixelSizeX * (lenX-2), pixelSizeY * 1, -- corner 2
        pixelSizeX * (lenX-1), pixelSizeY * 2, -- corner 2
        pixelSizeX * lenX,     pixelSizeY * 5, -- corner 2

        pixelSizeX * lenX,     pixelSizeY * (lenY-6), -- corner 3
        pixelSizeX * (lenX-1), pixelSizeY * (lenY-3), -- corner 3
        pixelSizeX * (lenX-3), pixelSizeY * (lenY-1), -- corner 3
        pixelSizeX * (lenX-6), pixelSizeY * lenY,     -- corner 3

        pixelSizeX * 6, pixelSizeY * lenY,     -- corner 4
        pixelSizeX * 3, pixelSizeY * (lenY-1), -- corner 4
        pixelSizeX * 1, pixelSizeY * (lenY-3), -- corner 4
        pixelSizeX * 0, pixelSizeY * (lenY-6), -- corner 4
    }

    -- X coordinates
    for i = 1, #tx, 2 do
        vt[i] = tx[i] * lenX
    end

    -- Y coordinates
    for i = 0, #tx, 2 do
        if i > 0 then
            vt[i] = tx[i] * lenY
        end
    end

    return vt, tx
end

local function getHUDFunction(v)
    return function(a,b,c)
        if (not v.condition or v.condition()) and (not v.filename or v.filename == levelfilename) and v.enabled then
            v:drawFunc(a,b,c)

            if v.renderBack and v.buffer then
                v:drawBackFunc(a,b,c)
            end
        end
    end
end

local function isOnWeirdness(p)
	return (
		p:mem(0x176,FIELD_WORD) ~= 0 -- on an NPC
		or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
	)
end

local function isEveryoneStill()
    for _, p in ipairs(Player.get()) do
        local condition = p.speedX == 0 and (isOnWeirdness(p) or p.speedY == 0)
        if not condition then
            return false
        end
    end
    return true
end

local function getBounds(v)
    local x = v.x + v.extraOffsetX - v.pivot.x * v.width
    local y = v.y + v.extraOffsetY - v.pivot.y * v.height
    return x+camera.x, y+camera.y, x+camera.x+v.width, y+camera.y+v.height
end

local function getDesiredNPCs(v, list)
    local npcList = {}
    if v.npcMap then
        for k, n in ipairs(list) do
            if n.isValid and (not n.isHidden) and ((type(v.npcMap) == "number" and n.id == v.npcMap) or v.npcMap[n.id]) then
                table.insert(npcList, n)
            end
        end
    end
    return npcList
end

local function getOffset(v, x)
    if v.axis == x then
        return v.offset * v.direction
    end
    return 0
end

local function getPivOffset(x, gap)
    if x == 0 then
        return gap
    elseif x == 0.5 then
        return 0
    elseif x == 1 then
        return -gap
    end
end

function hud.getList()
    return nameList
end

function hud.getData(n)
    if n then
        return data[n]
    end
    return data
end

function hud.activate(active)
    if active == nil then
        isHudActive = not isHudActive
    elseif type(active) == "boolean" then
        isHudActive = active
    else
        error("hudCreator.activate() only accepts a boolean value.")
    end
end

function hud.isActive()
    return isHudActive
end

function hud.defaultDraw(v, camIdx, vanillaPriority, isSplit)
    local x = v.x + v.xOffset - v.pivot.x * v.width
    local y = v.y + v.yOffset - v.pivot.y * v.height

    if v.img then
        Graphics.drawImageWP(v.img, x, y, v.opacity, v.priority)
    end

    if v.getFunc then
        local text = tostring(v.getFunc() or "")

        textplus.print{
            text = text,
            x = x+v.textOffsetX,
            y = y+v.textOffsetY,
            color = Color.white*v.opacity,
            priority = v.priority,
            font = v.font,
            xscale = v.textScale,
            yscale = v.textScale,
        }
    end

    if v.drawCross then
        Graphics.drawImageWP(crossImg, x+v.crossOffsetX, y+v.crossOffsetY, v.opacity, v.priority)
    end
end

function hud.defaultDrawBack(v, camIdx, vanillaPriority, isSplit)
    local x     = v.x + v.xOffset - v.pivot.x * v.backWidth
    local y     = v.y + v.yOffset - v.pivot.y * v.backHeight

    Graphics.drawBox{
        texture = v.buffer,
        x = x+v.backOffsetX,
        y = y+v.backOffsetY,
        w = v.backWidth,
        h = v.backHeight,
        color = v.backColor..math.max(v.opacity-0.5, v.leastBGAlpha),
        priority = v.priority-0.0000001
    }
end

function hud.addElement(name, args)
    name = name or "UN-DEF"
    args = args or {}

    if type(args.img) == "string" then
		args.img = Graphics.loadImageResolved(args.img)
	end

    if type(args.font) == "string" then
        args.font = textplus.loadFont(args.font)
    end

    if not args.font then args.font = defFont end

    if args.drawCross == nil and args.img then
        args.drawCross = true
    end

    if args.showOnUpdate == nil and args.stillBehavior then
        args.showOnUpdate = true
    end

    local npcids     = args.npcList or 0
    local axis       = math.sign(args.axis or hud.AXIS_X)
    local imgW       = (args.img and args.img.width) or 0
    local imgH       = (args.img and args.img.height) or 0
    local scale      = args.textScale or 1
    local gap        = args.gap or args.space or 8
    local imgGWidth  = (args.img and imgW+gap) or 0 -- image width + gap
    local crossWidth = (args.drawCross and crossImg.width+gap) or 0 -- cross width + gap
    local getFunc    = args.getFunc or function() end
    local textLen    = 2

    if getFunc then
        textLen = math.max(#tostring(getFunc() or ""), 2) -- most counters use 2 digits
    end

    if not args.width then
        args.width = imgGWidth + crossWidth + ((args.font.cellWidth + args.font.spacing)*scale*textLen)
    end

    if not args.height then
        args.height = math.max(imgH, args.font.cellHeight*scale)
    end

    local w         = math.max(args.width, 1)
    local h         = math.max(args.height, 1)
    local backScale = args.backScale or 2
    local border    = args.backBorder or 4
    local bw        = (args.backWidth or w+border*2)/backScale
    local bh        = (args.backHeight or h+border*2)/backScale
    local buffer    = args.buffer or args.captureBuffer
    local vt        = args.vt or args.vertexCoords
    local tx        = args.tx or args.textureCoords
    local pivot     = args.pivot or args.align or Sprite.align.TOPLEFT
    local leastOpacity = args.leastOpacity or args.leastAlpha or hud.leastOpacity

    local entry = {
        name          = name,
        img           = args.img,
        font          = args.font,
        x             = args.x or 0,
        y             = args.y or 0,
        width         = w,
        height        = h,
        priority      = args.priority or hud.defaultPriority,
        leastOpacity  = leastOpacity,
        gap           = gap,

        textOffsetX   = args.textOffsetX or imgGWidth+crossWidth,
        textOffsetY   = args.textOffsetY or math.max(imgH, crossImg.height)-args.font.cellHeight*scale+2,
        textScale     = scale,

        drawCross     = args.drawCross,
        crossOffsetX  = args.crossOffsetX or imgGWidth,
        crossOffsetY  = args.crossOffsetY or imgH-crossImg.height,

        drawBackdrop  = args.drawBackdrop,
        backBorder    = border,
        backOffsetX   = args.backOffsetX or getPivOffset(pivot.x, -border),
        backOffsetY   = args.backOffsetY or getPivOffset(pivot.y, -border),
        backWidth     = bw*backScale,
        backHeight    = bh*backScale,
        backColor     = args.backColor or Color.black,
        backScale     = backScale,
        leastBGAlpha  = args.leastBackOpacity or args.leastBackAlpha or leastOpacity/2,

        condition     = args.condition,
        hideType      = args.hideType or hud.TYPE_MOVE_FADE,
        axis          = axis,
        pivot         = pivot,
        direction     = math.sign(args.direction or hud.DIR_LEFT),
        getFunc       = getFunc,
        drawFunc      = args.drawFunc or hud.defaultDraw,
        drawBackFunc  = args.drawBackFunc or hud.defaultDrawBack,
        filename      = args.filename,
        moveSpeed     = args.moveSpeed or 2,
        fadeSpeed     = args.fadeSpeed or 0.075,
        overlapOffset = args.overlapOffset or (axis == hud.AXIS_X and math.floor(w/2) or axis == hud.AXIS_Y and math.floor(h/2)),
        hideOverlap   = args.hideOverlap,
        stillBehavior = args.stillBehavior,
        showOnUpdate  = args.showOnUpdate,
        npcMap        = (type(npcids) == "number" and npcids > 0 and {[npcids] = true}) or (type(npcids) == "table" and table.map(npcids)),
        enabled       = true,

        -- internal fields, but can be modified, at your own risk
        opacity       = 1,
        offset        = 0,
        xOffset       = 0,
        yOffset       = 0,
        moveType      = 1,
        overlapping   = false,
        stillTimer    = hud.stillTime,
        lastValue     = nil,
        extraOffsetX  = 0,
        extraOffsetY  = 0,
        renderBack    = args.drawBackdrop,
    }

    if args.drawBackdrop then
        local vt2, tx2 = getGlData(bw, bh)
        buffer = buffer or Graphics.CaptureBuffer(bw, bh)
        vt = vt or vt2
        tx = tx or tx2

        Graphics.glDraw{
            primitive = Graphics.GL_TRIANGLE_FAN,
            vertexCoords = vt,
            textureCoords = tx,
            target = buffer,
            priority = -1000000,
        }

        entry.buffer = buffer
    end

    table.insert(nameList, name)
    data[name] = entry
    Graphics.addHUDElement(getHUDFunction(entry))

    return entry
end

registerEvent(hud, "onStart")
registerEvent(hud, "onDraw")

function hud.onStart()
    if hud.disableVanillaHud then
        Graphics.overrideHUD(function(a,b,c) end)
    end
end

function hud.onDraw()
    for _, k in ipairs(nameList) do -- I refuse to use pairs
        local v = data[k]
        v.overlapping = (#Player.getIntersecting(getBounds(v)) > 0) or (#getDesiredNPCs(v, NPC.getIntersecting(getBounds(v))) > 0)

        if v.stillTimer <= hud.stillTime then
            v.stillTimer = (isEveryoneStill() and math.min(v.stillTimer + 1, hud.stillTime)) or 0
        else
            v.stillTimer = math.max(v.stillTimer - 1, hud.stillTime)
        end
        
        if (v.overlapping and v.hideOverlap) or (v.stillTimer < hud.stillTime and v.stillBehavior) or (not isHudActive) then
            v.moveType = -1
        else
            v.moveType = 1
        end

        if v.hideType ~= hud.TYPE_FADE then
            v.offset  = math.clamp(v.offset + v.moveSpeed * -v.moveType, 0, v.overlapOffset)
        end

        if v.hideType ~= hud.TYPE_MOVE then
            v.opacity = math.clamp(v.opacity + v.fadeSpeed * v.moveType, v.leastOpacity, 1)
        end

        v.xOffset = v.extraOffsetX + getOffset(v, hud.AXIS_X)
        v.yOffset = v.extraOffsetY + getOffset(v, hud.AXIS_Y)

        if v.showOnUpdate and v.getFunc then
            if v.lastValue ~= v.getFunc() then
                v.stillTimer = hud.stillTime + hud.extraTime
            end
            v.lastValue = v.getFunc()
        end
    end
end

return hud