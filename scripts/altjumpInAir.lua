local altjump = {}

local afterimages = require("scripts/afterimages")

altjump.graphics = {
	[1] = Graphics.loadImageResolved('graphics/spin-1.png'),
	[2] = Graphics.loadImageResolved('graphics/spin-2.png'),
}

altjump.current = {}
altjump.timer = {}

local powerupStates = table.map{
    FORCEDSTATE_POWERUP_BIG,FORCEDSTATE_POWERDOWN_SMALL,FORCEDSTATE_POWERUP_FIRE,FORCEDSTATE_POWERUP_LEAF,FORCEDSTATE_POWERUP_TANOOKI,
    FORCEDSTATE_POWERUP_HAMMER,FORCEDSTATE_POWERUP_ICE,FORCEDSTATE_POWERDOWN_FIRE,FORCEDSTATE_POWERDOWN_ICE,FORCEDSTATE_MEGASHROOM,
}

function altjump.onTick()
	for k,v in ipairs(Player.get()) do
		if not v:mem(0x50, FIELD_BOOL) and v.keys.altJump and not v:isOnGround() then

			SFX.play(33, 0.75)
			SFX.play('sound/kssu-hammer.wav', 0.1)

			v:mem(0x50, FIELD_BOOL, true)
			v.speedY = -4

			altjump.current[v] = true
	    	altjump.timer[v] = (4 * 4)

	    	for i = 1, 9 do
	    		local e = Effect.spawn(999, v)
	    		e.speedX = math.random(-1, 1)
	    		e.speedY = math.random(-1, 1)	    
	    		e.opacity = 0.1
	    	end
		end

		if altjump.current[v] then
			afterimages.create(v, 8)
		end

		if v:isOnGround() and altjump.current[v] then
			altjump.current[v] = nil
			altjump.timer[v] = nil
		end
	end
end

local bigPowerupFrames = {1,2,1,2,1,2,3,2,3,2,3,2,3}
local bigPowerup = {}
local bigPowerupTexture = {
	[CHARACTER_MARIO] = Graphics.loadImageResolved("graphics/mario/mario-powerup.png"),
}

function altjump.onTickEnd()
	for k,v in ipairs(Player.get()) do
  		Defines.levelFreeze = (powerupStates[v.forcedState] or mem(0x00B2C62E,FIELD_WORD) > 0)
  		
  		if (v.forcedState == FORCEDSTATE_POWERUP_BIG) or v.forcedState == FORCEDSTATE_POWERDOWN_SMALL then
  			local frame = bigPowerupFrames[math.floor(v.forcedTimer / 4) + 1]

  			if frame and frame == 2 then
  				bigPowerup[v] = frame
				v:mem(0x142, FIELD_BOOL, true)
  			else
  				v.frame = 1
  				bigPowerup[v] = nil
				v:mem(0x142, FIELD_BOOL, false)
  			end
  		else
  			bigPowerup[v] = nil
  		end
  	end
end

local frames = {
	[1] = 1,
	[13] = 2,
	[15] = 2,
}

function altjump.onCameraDraw()
	for v in pairs(bigPowerup) do
		local texture = bigPowerupTexture[v.character]

		local w = (v.width - texture.width) * .5
		local h = (v.height - 48)

		local x = v.x + w
		local y = v.y + h

		local sourceY = (v.direction == 1 and 48) or 0

		Graphics.drawImageToSceneWP(texture, x, y, 0, sourceY, 30, 48, -26)
	end

	for p in pairs(altjump.current) do
		altjump.timer[p] = altjump.timer[p] - 1

		local xOff, yOff = 0, 0

		local img1 = altjump.graphics[1]
		local img2 = altjump.graphics[2]

	    local width = img2.width
	    local height = img2.height / 3
	    local width2 = img1.width
	    local height2 = img1.height / 3

	    -- Text.print(tostring(p.frame), 10, 10)
	    local frame = frames[p.frame]

	    if frame == nil or altjump.timer[p] < 0 then
	    	altjump.current[p] = nil
	    	altjump.timer[p] = nil
	    	return
	    end

	    if altjump.timer[p] % 4 >= 3 then
	    	frame = frame + 1
	    end

	    Graphics.drawImageToSceneWP(img1, p.x + p.width/2 - width/2 + xOff, p.y + p.height/2 - height/2 + yOff, 0, frame * height, width, height, -24)
	    Graphics.drawImageToSceneWP(img2, p.x + p.width/2 - width2/2 + xOff, p.y + p.height/2 - height2/2 + yOff, 0, frame * height2, width2, height2, -26)
	end
end

function altjump.onInitAPI()
	registerEvent(altjump, 'onTickEnd')
	registerEvent(altjump, 'onTick')
	registerEvent(altjump, 'onCameraDraw')
end

return altjump