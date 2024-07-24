local block = {}
block.idMap = {}

block.settings = {
	bumpable = true,
	
	npcbounce = 9,
	playerbounce = 6,
	playerbounceheight = Defines.jumpheight + 5,
}

local blockManager = require 'blockManager'

function block.register(config)
	local config = table.join(config, block.settings)
	blockManager.setBlockSettings(config)
	
	block.idMap[config.id] = true
end

local function touch(v, p)
	local blockCfg = Block.config[v.id]
	SFX.play(3)
	
	v:hit(true, p)
	
	if type(p) == "Player" then
		p:mem(0x11C, FIELD_WORD, blockCfg.playerbounceheight)
		p.speedY = -blockCfg.playerbounce
		
		if p.keys.jump or p.keys.altJump then
			SFX.play(1)
		end
	else
		local cfg = NPC.config[p.id]
		
		local sY = blockCfg.npcbounce
		
		if cfg.isheavy then
			sY = sY * .5
		end
		
		p.speedY = -sY
	end
end

function block.onTickEnd()
    for k,p in ipairs(Player.get()) do
        if p:isGroundTouching() then
            for k,v in Block.iterateIntersecting(p.x, p.y + p.height, p.x + p.width, p.y + p.height + 1) do
                if v.y >= p.y + p.height and block.idMap[v.id] then
					touch(v, p)
                end
            end
        end
    end
	
	for k,p in NPC.iterate() do
		if p.collidesBlockBottom then
            for k,v in Block.iterateIntersecting(p.x, p.y + p.height, p.x + p.width, p.y + p.height + 1) do
                if v.y >= p.y + p.height and block.idMap[v.id] then
					touch(v, p)
                end
            end	
		end
	end
end

function block.onInitAPI()
	registerEvent(block, 'onTickEnd')
end

return block