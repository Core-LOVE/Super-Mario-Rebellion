local block = {}

block.idMap = {}

block.settings = {
	bumpable = true,
	
	npcbounce = 9,
	playerbounce = 6,
	playerbounceheight = Defines.jumpheight + 5,
}

local blockManager = require 'blockManager'
local blockutils = require("blocks/blockutils")

local shader = Shader()
shader:compileFromFile(nil, "scripts/shaders/wobbly.frag")

local drawArgs = {
	texture = Graphics.loadImageResolved("block-767r.png"),

	x = 0,
	y = 0,

	sceneCoords = true,
	shader = shader,
	uniforms = {
		time = lunatime.tick() * .01
	},
	priority = -65,
}

function block.onCameraDrawBlock(v, cam_idx)
	if v.isHidden or v:mem(0x5A, FIELD_BOOL) or not blockutils.visible(Camera(cam_idx), v.x, v.y, v.width, v.height) then return end
	
	drawArgs.x = v.x
	drawArgs.y = v.y
	drawArgs.uniforms.time = lunatime.tick() * .01

	Graphics.drawBox(drawArgs)
end

function block.register(config)
	local config = table.join(config, block.settings)
	blockManager.setBlockSettings(config)
	blockManager.registerEvent(config.id, block, 'onCameraDrawBlock')

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

local function pop(v)
	SFX.play(91)
	Effect.spawn(768, v.x, v.y)
	Effect.spawn(767, v.x + v.width * 0.25, v.y + v.height * 0.25)
	v:remove(false)
	
	local id = v.contentID
	if v.data._basegame.content then
		id = v.data._basegame.content
	end
	
	v.contentID = 0
	
	for k,p in ipairs(Player.get()) do
		if p.y < v.y then
			v.data.up = 1
		else
			v.data.up = -1
		end
    end
	
	if id > 1000 then
		local n = NPC.spawn(id-1000,v.x + 0.5 * v.width - 0.5 * NPC.config[id - 1000].width, v.y - 0.5 * v.height - 0.5 * NPC.config[id - 1000].height + ((v.data.up + 1) * 32),section)
		n.forcedState = 0
		n.speedY = 3.5 * (v.data.up - 1)
		n.direction = -Player.getNearest(v.x + v.width/2, v.y + v.height).direction
	elseif (id >= 1 and id < 100 and v.id ~= 756) or (id >= 1 and id < 100 and v.id == 756) then
		for i=1,id do
			local coin = NPC.spawn(10,v.x + 0.5 * v.width - 0.5 * NPC.config[10].width, v.y + 0.5 * v.height - 0.5 * NPC.config[10].height, section)
			coin.speedX = RNG.randomInt(-3,3)
			coin.speedY = RNG.randomInt(-5,-9) * -v.data.up
			coin.ai1 = 1;
		end
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
	registerEvent(block, "onPostBlockHit")
	registerEvent(block, "onStart")
end

function block.onPostBlockHit(v, upper, pl)
	if block.idMap[v.id] and not v.isHidden then
		pop(v)
	end
end

return block