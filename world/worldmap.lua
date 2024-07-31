local worldmap = {}

local lib3d = require("lib3d")

-- worldmap.camera_distance = -250
worldmap.camera_distance = -320
worldmap.camera_rotation = vector(45, 0, 0)
worldmap.camera_rotation_worldwide = true

worldmap.lowest_z = 500

worldmap.water_plane = lib3d.Plane({
	position = vector(-200000, -200608, worldmap.lowest_z),
	width = 4000,
	height = 4000,
	material = lib3d.Material(nil, {	
		texture = Graphics.sprites.
	}, {}, {
		UNLIT = true,
		TONEMAP = false,
		ALPHAMODE = 1,
	})
})

worldmap.start_block_id = 1
worldmap.billboards = {}

function worldmap.billboard(plane)
	table.insert(worldmap.billboards, plane)
	return plane
end

worldmap.player = worldmap.billboard(lib3d.Box({
	position = vector(0, 0, 0),
	width = 32,
	height = 32,
	depth = 32,
	material = lib3d.Material(nil, {	
		color = Color.white
		-- texture = Graphics.sprites.npc[1].img,
	}, {}, {
		UNLIT = true,
		TONEMAP = false,
		ALPHAMODE = 1,
	})
}))

function worldmap.block(v)
	local settings = v.data._settings._global

	return v.x + settings.x, v.y + settings.y, (worldmap.lowest_z + settings.z) - (settings.depth * .5)
end

function worldmap.plane(v)
	local x, y, z = worldmap.block(v)
	
	return lib3d.Plane({
		position = vector(x + v.width * .5, y + v.height * .5, z), 
		height = v.height,
		width = v.width,
		material = lib3d.Material(nil, {	
			texture= Graphics.sprites.block[v.id].img,
		}, {}, {
			UNLIT = true,
			TONEMAP = false,
			ALPHAMODE = 1,
		})
	})
end

function worldmap.box(v)
	local settings = v.data._settings._global

	local x, y, z = worldmap.block(v)

	return lib3d.Box({
		position = vector(x + v.width * .5, y + v.height * .5, z), 
		rotation = vector.quatid, 
		height = v.height,
		width = v.width,
		depth = settings.depth,
		material = lib3d.Material(nil, {	
			texture= Graphics.sprites.block[v.id].img,
		}, {}, {
			UNLIT = true,
			TONEMAP = false,
			ALPHAMODE = 1,
		})
	})
end

function worldmap.onStart()
	lib3d.camera.renderscale = 1
	lib3d.camera.fov = 120

	for k,b in Block.iterate() do
		local settings = b.data._settings._global
		local obj

		if settings.isPlane then
			obj = worldmap.plane(b)
		else
			obj = worldmap.box(b)
		end

		if b.id == worldmap.start_block_id then
			worldmap.player.position = vector(obj.x, obj.y, obj.z)
			worldmap.player.z = worldmap.player.z - 32
		end
	end
end

function worldmap.onCameraDraw()
	local rotation = worldmap.camera_rotation

    lib3d.camera.transform.position = vector(camera.x + camera.width * .5, camera.y + camera.height * .5, -lib3d.camera.flength - worldmap.camera_distance)

	lib3d.camera.transform.rotation = vector.quat(rotation.x, rotation.y, rotation.z)

	-- Text.print(tostring(rotation.x), 10, 10)
end

function worldmap.onTickEnd()
	local rotation = worldmap.camera_rotation
	local speed = 0.5

	-- for k,v in ipairs(worldmap.billboards) do
	-- 	v.transform:lookAt(lib3d.camera.transform.position)
	-- end
	-- worldmap.camera_distance = worldmap.camera_distance + speed
	-- rotation.x = rotation.x + speed
end

function worldmap.onInitAPI()
	registerEvent(worldmap, 'onStart')
	registerEvent(worldmap, 'onTickEnd')
	registerEvent(worldmap, 'onCameraDraw')
end

return worldmap