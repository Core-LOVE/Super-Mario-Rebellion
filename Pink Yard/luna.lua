local effect = Particles.Emitter(0, 0, "p_fallingleaf.ini")
effect:AttachToCamera(camera)
effect:setPrewarm(24)

function onCameraDraw()
	if player.section < 2 then
		effect:Draw()
	end
end