local layer
local camera_pos = {}

function onStart()
    layer = Layer.get("second")
end

function onCameraUpdate(camIdx)
    local cam = Camera(camIdx)

    if not camera_pos[camIdx] then
        camera_pos[camIdx] = vector(cam.x, cam.y)
    end

    local difX = camera_pos[camIdx].x - cam.x
    local difY = camera_pos[camIdx].y - cam.y

    -- Text.print(tostring(difX) .. " + " .. tostring(difY), 10, 10)

    layer.speedY = difX
    -- layer.speedX = -difY

    if cam.x ~= camera_pos[camIdx].x then camera_pos[camIdx].x = cam.x end
    if cam.y ~= camera_pos[camIdx].y then camera_pos[camIdx].y = cam.y end  
end