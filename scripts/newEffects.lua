local cfg = require("base/game/effectconfig")

function cfg.onTick.TICK_STOMP(v)
	v.xScale = v.xScale + 0.25
	v.yScale = v.yScale + 0.25

	v.opacity = v.opacity - 0.05

	if v.xScale > 3 then
		v:kill()
	end
end

function cfg.onTick.TICK_TIEM_SPARKLE(v)
	v.xScale = v.xScale - 0.1
	v.yScale = v.yScale - 0.1

	v.opacity = v.opacity - 0.01

	if v.animationFrame == 0 then
		if v.timer == 1 then
			v:kill()
		end
	else
		v.timer = 2
	end
end