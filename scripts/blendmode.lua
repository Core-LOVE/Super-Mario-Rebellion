local blendmode = {}

blendmode.shaders = {}

local bg = Graphics.CaptureBuffer()

local uniforms = {
	iBackdrop = bg
}

function blendmode.get(name)
	if blendmode.shaders[name] == nil then
		local sh = Shader()
		sh:compileFromFile(nil, Misc.resolveFile("scripts/shaders/blendmode/" .. name .. ".frag"))

		blendmode.shaders[name] = sh
	end

	uniforms.iBackdrop = bg
	return blendmode.shaders[name], uniforms
end

function blendmode.onStart()
	bg = Graphics.CaptureBuffer()
end

function blendmode.onDraw()
	bg:captureAt(0)
end

function blendmode.onInitAPI()
	registerEvent(blendmode, 'onStart')
	registerEvent(blendmode, 'onDraw')
end

return blendmode