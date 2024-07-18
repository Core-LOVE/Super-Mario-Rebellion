local lib3d = require("lib3d")
local data = require("scripts/data")

local cameraCentre = Transform(vector.zero3, vector.quatid, vector.one3)
local cameraRotation = {
    x = 0,
    y = 0,
    z = 0,
}

local objs = {}

local function createWall(v)
    local obj = lib3d.Box{
        position = vector(v.x + v.width * .5, v.y + v.height * .5, -32), 
        rotation = vector.quatid, 
        height = v.height,
        width = v.width,
        depth = 32,
        uv = lib3d.uv.UNWRAP,
        material = lib3d.Material(nil, {
            texture=Graphics.sprites.block[v.id].img,
            roughness=1,
            occlusion=1,
            metallic=0,
            emissive=0
        }, {}, {
            UNLIT = true,
            TONEMAP = false,
            ALPHAMODE = 1,
        })
    }

    return obj
end

function onStart()
    for k,v in Block.iterate() do
        if v.id == 25 then
            createWall(v)
        end
    end

    lib3d.camera.transform.parent = cameraCentre
    lib3d.camera.renderscale = 1 
end

function onDraw()
    cameraCentre.position = vector(camera.x + data.screen[1] * .5, camera.y + data.screen[2] * .5, 0) + vector(0, 0, -lib3d.camera.flength)
end