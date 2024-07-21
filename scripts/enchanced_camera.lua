local enchanced_camera = {}

enchanced_camera.distance = 52
enchanced_camera.speed = 0.0005
enchanced_camera.delay = 32

function enchanced_camera.get(camIdx)
	if enchanced_camera[camIdx] == nil then
		enchanced_camera[camIdx] = {
			x = 0,
			y = 0,
			t = 0,
			direction = 0,
		}
	end

	return enchanced_camera[camIdx]
end

local function setDirection(encam, p)
	Routine.waitFrames(enchanced_camera.delay)

	encam.direction = p.direction
	encam.t = 0
end

function enchanced_camera.onCameraUpdate(camIdx)
	local cam = Camera(camIdx)
	local p = Player(camIdx)
	local section = p.sectionObj

	local encam = enchanced_camera.get(camIdx)
	encam.t = (encam.t + enchanced_camera.speed)

	if encam.t > 1 then encam.t = 1 end

	if (encam.direction ~= p.direction) then
		Routine.run(setDirection, encam, p)
	end

	encam.x = math.lerp(encam.x, enchanced_camera.distance * encam.direction, encam.t)

	cam.x = cam.x + encam.x
	cam.x = math.clamp(cam.x, section.boundary.left, section.boundary.right - cam.width)
end

function enchanced_camera.onInitAPI()
	registerEvent(enchanced_camera, 'onCameraUpdate')
end

return enchanced_camera