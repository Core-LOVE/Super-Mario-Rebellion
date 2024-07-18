local hud = {}

local hudCreator = require("scripts/hudCreator")
local data = require("scripts/data")
local starcoin   = require("npcs/ai/starcoin")

hud.font_name = "textplus/font/1.ini"

hud.coins = hudCreator.addElement("coins", {
    img           = Graphics.loadImageResolved("graphics/hud/coin.png"),
    font          = hud.font_name,
    x             = data.screen[1] * .3,
    y             = 22,
    getFunc       = function() return mem(0x00B2C5A8, FIELD_WORD) end,
})

hud.clovers = hudCreator.addElement("clovers", {
    img           = Graphics.loadImageResolved("graphics/hud/clover.png"),
    font          = hud.font_name,
    x             = (data.screen[1] * .3) - 6,
    y             = 44,
    getFunc       = function() return mem(0x00B251E0, FIELD_WORD) end,
})

hud.score = hudCreator.addElement("score", {
    font        = hud.font_name,
    x           = (data.screen[1] * .7) + 46,
    y           = 22,
    pivot       = Sprite.align.TOPRIGHT,
    getFunc     = function() return string.format("%.7d", Misc.score()) end,
})

function hud.drawItemBox(v, camIdx, vanillaPriority, isSplit)
    local x    = v.x + v.xOffset - v.pivot.x * v.width
    local y    = v.y + v.yOffset - v.pivot.y * v.height

    Graphics.drawImageWP(v.img, x, y, v.opacity, v.priority)

    if player.reservePowerup > 0 then
        local img = Graphics.sprites.npc[player.reservePowerup].img
        local config = NPC.config[player.reservePowerup]
        local gfxwidth = config.gfxwidth
        local gfxheight = config.gfxheight
    
        if gfxwidth == 0 then
            gfxwidth = config.width
        end
        
        if gfxheight == 0 then
            gfxheight = config.height
        end

        local nx     = v.x + v.xOffset - v.pivot.x * gfxwidth
        local ny     = v.y + v.yOffset - v.pivot.y * gfxheight

        Graphics.drawImageWP(img, nx, ny, 0, 0, gfxwidth, gfxheight, v.opacity, v.priority)
    end
end

local itembox_texture = Graphics.loadImageResolved("graphics/hud/itembox.png")

hud.itembox = hudCreator.addElement("itembox", {
    img         = itembox_texture,
    x           = data.screen[1] * .5,
    y           = 44,
    width       = itembox_texture.width,
    height      = itembox_texture.height,
    pivot       = Sprite.align.CENTER,
    leastAlpha  = 0.5,
    hideOverlap = true,
    axis        = hud.AXIS_Y,
    hideType    = hud.TYPE_FADE,
    direction   = hud.DIR_UP,
    getFunc     = function() return player.reservePowerup end,
    condition   = function() return Graphics.getHUDType(player.character) == Graphics.HUD_ITEMBOX end,
    -- drawBackdrop = true,
    drawFunc     = hud.drawItemBox,
})

local starCol    = Graphics.sprites.hardcoded["51-1"].img
local starUncol  = Graphics.sprites.hardcoded["51-0"].img

local function drawStarcoins(v, camIdx, vanillaPriority, isSplit)
    local x    = v.x + v.xOffset - v.pivot.x * v.width
    local y    = v.y + v.yOffset - v.pivot.y * v.height

    v.extraOffsetY = (Graphics.getHUDType(player.character) == Graphics.HUD_ITEMBOX and 26) or 0
    v.width = (starCol.width+2)*starcoin.count(LevelName) - 2

    if v.width > 1 then
        for i, value in ipairs(starcoin.getLevelList(LevelName)) do
            local img = starCol

            if value == 0 then
                img = starUncol
            end

            Graphics.drawImageWP(img, x + (i-1)*(starCol.width+v.gap), y, v.opacity, v.priority)
        end
    end
end

hudCreator.addElement("starcoins", {
    x             = (data.screen[1] * .7) + 46,
    y             = 22,
    width         = 0,
    height        = starCol.height,
    gap           = 2,
    -- hideOverlap   = true,
    pivot         = Sprite.align.TOPRIGHT,
    -- axis          = hud.AXIS_Y,
    -- direction     = hud.DIR_DOWN,
    -- stillBehavior = true,
    overlapOffset = starCol.height,
    condition     = function() return starcoin.count(LevelName) > 0 end,
    getFunc       = function() return starcoin.getLevelCollected(LevelName) end,
    drawFunc      = drawStarcoins,
})

return hud