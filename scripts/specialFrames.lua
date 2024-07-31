local specialFrames = {}

function specialFrames.define(max, starting)
	local v = {
		frametimer = 0,
		frame = starting or 0,
		maxFrame = max,
		framespeed = 8,
	}

	v.update = function(v)
		v.frametimer = (v.frametimer + 1)

		if (v.frametimer >= v.framespeed) then
			v.frame = (v.frame + 1) % v.maxFrame
			v.frametimer = 0
		end
	end

	return v
end

return specialFrames