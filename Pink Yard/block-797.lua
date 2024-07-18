local blockmanager = require("blockmanager")
local blockutils = require("blocks/blockutils")

local blockID = BLOCK_ID

local block = {}

blockmanager.setBlockSettings({
	id = blockID,
})

local function transform(v)
	local effect = Effect.spawn(751, v)
	v.isHidden = true
	
	Routine.waitFrames(16)
	effect:kill()
	
	if v.isValid then
		v:transform(blockID + 1)
		v.isHidden = false
	end
end

local function npcfilter(v)
	return (v.id == 92) and (v:mem(0x12C, FIELD_WORD) == 0)
end

function block.onTickEndBlock(self)
	if blockutils.hiddenFilter(self) and  blockutils.isInActiveSection(self) and blockutils.isOnScreen(self, 800) then
		local c = Colliders.getColliding{a = blockutils.getHitbox(self, 2), btype = Colliders.NPC, filter = npcfilter }
		for _,n in ipairs(c) do
			-- if #Colliders.getColliding{a = blockutils.getHitbox(self, 2), btype = Colliders.Player} ~= 0 then return end
		
			Routine.run(transform, self)
			break
		end
	end
end

function block.onInitAPI()
    blockmanager.registerEvent(blockID, block, "onTickEndBlock")
end

return block