local npc_animator = {}

local animationPal = require("scripts/animationPal")

function npc_animator.animator(v, args)
	local data = v.data
	local args = args or {}

    args.frameWidth  = args.frameWidth  or 100
    args.frameHeight = args.frameHeight or 100

    args.scale = args.scale or vector(1,1)
    args.offset = args.offset or vector(0, 0)
    args.pivotOffset = args.pivotOffset or vector(0, 0)

    args.imageDirection = args.imageDirection or DIR_LEFT

    data.args = args
	data.animator = animationPal.createAnimator(args)

	for k,v in pairs(args) do
		rawset(data.animator, k, v)
	end

	local texture = args.texture

	data.sprite = Sprite{
		texture = texture,
		frames = vector(texture.width / args.frameWidth, texture.height / args.frameHeight)
	}
end

function npc_animator.drawAnimator(v, args)
	local data = v.data

    local sprite = data.sprite
    local properties = data.animator
    local args = args or {}

    properties.shader = args.shader
    properties.uniforms = args.uniforms or {}
    properties.attributes = args.attributes or {}
    properties.x = (args.x or v.x) + v.width*0.5
    properties.y = (args.y or v.y) + v.height
    properties.direction = args.direction or v.direction
    -- properties.pivotOffset = properties.pivotOffset
    properties.pivot = args.pivot or vector(0.5,1)
    properties.scale = args.scale or properties.scale

    properties.rotation = args.rotation or 0
    properties.sceneCoords = (args.sceneCoords ~= nil and args.sceneCoords) or true

    sprite.x = math.floor(properties.x + properties.offset.x * properties.direction * properties.imageDirection + properties.pivotOffset.x + 0.5)
    sprite.y = math.floor(properties.y + properties.offset.y + properties.pivotOffset.y + 0.5)

    sprite.scale.x = properties.scale.x*properties.direction*properties.imageDirection
    sprite.scale.y = properties.scale.y

    sprite.rotation = properties.rotation

    sprite.pivot = vector(
        properties.pivot.x + properties.pivotOffset.x/properties.frameWidth,
        properties.pivot.y + properties.pivotOffset.y/properties.frameHeight
    )
    sprite.texpivot = sprite.pivot

    sprite:draw{
        shader = properties.shader,uniforms = properties.uniforms,attributes = properties.attributes,
        priority = properties.priority,sceneCoords = properties.sceneCoords,color = properties.color,
        target = properties.target,
        frame = properties.frame,
    }
end

return npc_animator