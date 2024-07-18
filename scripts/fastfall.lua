--[[
					FASTFALL.lua by MrNameless
		A library made to somewhat replicate Super Mario World's
					methods of handling gravity.
			
	CREDITS:
	MrDoubleA - Made the SMW-Mario Costume that the isOnGround() function is taken from & what the isHoldingJump() function is based off on.
	
	TO DO:
	-Try to find a different way to handle falling speed instead of Defines.player_grav to prevent possible clashing with codes/libraries that also use it. 
	 (^^ DONE! via adding to the player's Y-speed with a speed mutltiplier ^^)
	-Implement proper deacceleration into the slowfall speed cap in a way that precisely matches any set caps that has decimals in it. (Ex: fastfall.slowfallCap = 8.3 -> player.speedY = player.speedY - something)
	-Refine/optimize some code if possible.
	
	Version = 2.0.0
]]--
local fastfall = {}

fastfall.slowfallCapToggle = true --toggle to enable a speedcap when slowfalling (default is true)
fastfall.slowfallCap = 9 -- the maximum speed for slowfalling (default is 9)
fastfall.fastfallSpeed = 0.1 -- speed multiplier when fastfalling (default is 0.2)

local function isOnGround(p) -- Check to see if the player is on the ground. (Taken straight from the SMW-Mario Costume lua file in the "costume" folder.)
	return (
		p.speedY == 0 
		or p:mem(0x176,FIELD_WORD) ~= 0 
		or p:mem(0x48,FIELD_WORD) ~= 0 -- on a slope
	)
end

local function isHoldingJump(p) -- Check to see if the player is pressing either jump buttons.
	return (
		p.keys.jump == KEYS_DOWN
		or p.keys.altJump == KEYS_DOWN
	)
end

function fastfall.onTickEnd()
	for _,p in ipairs(Player.get()) do 
		if not isOnGround(p) and not p:mem(0x36, FIELD_BOOL) then 
			if isHoldingJump(p) then
				p.fallSpeed = 0
				p.isSlowfalling = true
			else
				p.fallSpeed = fastfall.fastfallSpeed
			end	

			if fastfall.slowfallCapToggle == true and p.speedY > fastfall.slowfallCap and p.isSlowfalling == true then
				p.speedY = fastfall.slowfallCap
				p.isSlowfalling = false
			elseif p.speedY < 12 then
				p.speedY = p.speedY + p.fallSpeed
			end
		else
			p.fallSpeed = 0 
		end
	end
end

function fastfall.onDraw() -- this lua event is for testing purposes only. ignore this
	for _,p in ipairs(Player.get()) do 
		Text.print("IS ON GROUND?",50, 80)
		Text.print(isOnGround(p),50,100)
		Text.print("HOLDING JUMP?",50, 140)
		Text.print(isHoldingJump(p),50,160)
		Text.print("FALLSPEED MULTIPLIER",50,200)
		Text.print(p.fallSpeed,50,220) 
		Text.print("SPEED Y",50, 260)
		Text.print(p.speedY,50,280)
	end
end

function fastfall.onInitAPI()
	registerEvent(fastfall,"onTickEnd")
	--registerEvent(fastfall,"onDraw") --Uncomment this for testing purposes only, ignore this otherwise
end
	
return fastfall