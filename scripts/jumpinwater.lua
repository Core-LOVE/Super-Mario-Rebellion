--[[
	jumpinwater.lua v1.0 by "Master" of Disaster

	A quick library that lets the player dive into water more seemlessly instead of losing all of their momentum 

	crediting would be as fresh as jumping into water on a summer day is
]]--

local jumpinwater = {
	keepSpeed = 0.4,		-- how much speed you are preserving when you jump into water
	loseSpeed = 0.2,	-- how quickly you are losing extra speed (doesn't affect speed <= 3) after you jump into water
	minKeepSpeed = 1,	-- the minimum amount of (y) speed the player needs to even keep their momentum. Used so you can jump out of water easier.
	
	inWater = false,	-- used to detect whether the player just touched water
	extraspeedX = 0,	-- speed that gets added to the player's speed
	extraspeedY = 0,	-- ^
	
}

local prevspeedX = 0	-- previous speed of the player. Used to know how much speed the player had when jumping into water
local prevspeedY = 0
local checkColliderX = Colliders.Rect(0,0,1,1,0)	-- a collider that checks whether the player would clip into floor when still preserving momentum. If so, then the player will not be sped up anymore
local checkColliderY = Colliders.Rect(0,0,1,1,0)	-- ^ but for Y. spliced so you don't lose Y speed when you should only loose X speed and so on.

registerEvent(jumpinwater,"onTick")

local function blockFilter(o)
    if not (o.isHidden or not ((Block.PLAYERSOLID_MAP[o.id] or Block.SOLID_MAP[o.id]) or (jumpinwater.extraspeedY > 0 and Block.SEMISOLID_MAP[o.id] and player.y + player.height < o.y))) then
        return true	-- check whether it's a solid block, playersolid block or a semisolid while you are going downwards. latter check also checks whether it's the top of a semisolid specifically
    end
end

function jumpinwater.onTick()
	checkColliderX.x = player.x + player.width * 0.5 + jumpinwater.extraspeedX
	checkColliderX.y = player.y + player.height * 0.5
	checkColliderX.width = player.width
	checkColliderX.height = player.height
	
	checkColliderY.x = player.x + player.width * 0.5
	checkColliderY.y = player.y + player.height * 0.5 + jumpinwater.extraspeedY
	checkColliderY.width = player.width
	checkColliderY.height = player.height
	
	
	for p, b in ipairs(Colliders.getColliding{a = checkColliderX, btype = Colliders.BLOCK, filter = blockFilter}) do
		jumpinwater.extraspeedX = -jumpinwater.extraspeedX * 0.2
	end
	for p, b in ipairs(Colliders.getColliding{a = checkColliderY, btype = Colliders.BLOCK, filter = blockFilter}) do
		jumpinwater.extraspeedY = -jumpinwater.extraspeedY * 0.2
	end
	for p, b in ipairs(Colliders.getColliding{a = checkColliderX, btype = Colliders.NPC, filter = function(o) if not (o.isHidden or o.isFriendly or not NPC.PLAYERSOLID_MAP[o.id]) then return true end end}) do
		jumpinwater.extraspeedX = -jumpinwater.extraspeedX * 0.2
	end
	for p, b in ipairs(Colliders.getColliding{a = checkColliderY, btype = Colliders.NPC, filter = function(o) if not (o.isHidden or o.isFriendly or not NPC.PLAYERSOLID_MAP[o.id]) then return true end end}) do
		jumpinwater.extraspeedY = -jumpinwater.extraspeedY * 0.2
	end
	
	if player.speedY * jumpinwater.extraspeedY < 0 then
		jumpinwater.extraspeedY = 0
	end
	if player.speedX * jumpinwater.extraspeedX < 0 then
		jumpinwater.extraspeedX = 0
	end
	
	if player:mem(0x34,FIELD_WORD) ~= 0 then	-- player is in water
		if not jumpinwater.inWater then	-- just touched water
			jumpinwater.extraspeedX = prevspeedX * jumpinwater.keepSpeed
			if math.abs(prevspeedY) > jumpinwater.minKeepSpeed then
				jumpinwater.extraspeedY = prevspeedY * jumpinwater.keepSpeed
			end
			jumpinwater.inWater = true
		end
		--if jumpinwater.extraspeedX == 0 and jumpinwater.extraspeedY == 0 then return end
		
		if math.abs(jumpinwater.extraspeedX) <= 3 and math.abs(player.speedX) < math.abs(jumpinwater.extraspeedX) then
			player.speedX = jumpinwater.extraspeedX
			jumpinwater.extraspeedX = 0
		elseif math.abs(jumpinwater.extraspeedX) > 3 then
			player.x = player.x + jumpinwater.extraspeedX
			if jumpinwater.extraspeedX > 0 then
				jumpinwater.extraspeedX = jumpinwater.extraspeedX - jumpinwater.loseSpeed
			else
				jumpinwater.extraspeedX = jumpinwater.extraspeedX + jumpinwater.loseSpeed
			end
		end
		if math.abs(jumpinwater.extraspeedY) <= 3 and math.abs(player.speedY) < math.abs(jumpinwater.extraspeedY) then
			player.speedY = jumpinwater.extraspeedY
			jumpinwater.extraspeedY = 0
		elseif math.abs(jumpinwater.extraspeedY) > 3 then
			player.y = player.y + jumpinwater.extraspeedY
			if jumpinwater.extraspeedY > 0 then
				jumpinwater.extraspeedY = jumpinwater.extraspeedY - jumpinwater.loseSpeed
			else
				jumpinwater.extraspeedY = jumpinwater.extraspeedY + jumpinwater.loseSpeed
			end
		end
		
	else
		jumpinwater.inWater = false
		prevspeedX = player.speedX
		prevspeedY = player.speedY 
	end
end


return jumpinwater