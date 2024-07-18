--[[

    Cape for anotherpowerup.lua
    by MrDoubleA

    Credit to JDaster64 for making a SMW physics guide and ripping SMA4 Mario/Luigi sprites
    Custom Toad and Link sprites by Legend-Tony980 (https://www.deviantart.com/legend-tony980/art/SMBX-Toad-s-sprites-Fourth-Update-724628909, https://www.deviantart.com/legend-tony980/art/SMBX-Link-s-sprites-Sixth-Update-672269804)
    Custom Peach sprites by Lx Xzit and Pakesho
    SMW Mario and Luigi graphics from AwesomeZack

    Credit to FyreNova for generally being cool (oh and maybe working on a SMBX38A version of this, too)

]]

local ai = require("scripts/powerups/ai/cape")

local apt = {}
-- apt.basePowerup = PLAYER_BIG

apt.spritesheets = {
    [CHARACTER_MARIO] = Graphics.loadImageResolved("graphics/mario/mario_cape.png"),
    [CHARACTER_LUIGI] = Graphics.loadImageResolved("graphics/luigi/luigi_cape.png"),
    -- Graphics.loadImageResolved("peach-ap_cape.png"),
    -- Graphics.loadImageResolved("toad-ap_cape.png"),
    -- Graphics.loadImageResolved("link-ap_cape.png"),
}

apt.iniFiles = {
    Misc.resolveFile("graphics/mario/mario_cape.ini"),
    Misc.resolveFile("graphics/luigi/luigi_cape.ini"),
}

apt.capeSpritesheets = {
    Graphics.loadImageResolved("graphics/mario/mario_cape_cape.png"),
    Graphics.loadImageResolved("graphics/luigi/luigi_cape_cape.png"),
    -- Graphics.loadImageResolved("peach-ap_cape_cape.png"),
    -- Graphics.loadImageResolved("toad-ap_cape_cape.png"),
    -- Graphics.loadImageResolved("link-ap_cape_cape.png"),
}

apt.apSounds = {
    upgrade = SFX.open(Misc.resolveSoundFile("sound/cape_get")),
    reserve = 12
}

apt.items = {851}


apt.cheats = {"needacape","needafeather"}

ai.register(apt)


function apt.onEnable()
    ai.onEnable(apt)
end
function apt.onDisable()
    ai.onDisable(apt)
end

function apt.onTick()
    ai.onTick(apt)
end
function apt.onTickEnd()
    ai.onTickEnd(apt)
end
function apt.onDraw()
    ai.onDraw(apt)
end


return apt