local shapeshifter = {}

shapeshifter.activated = {}

function shapeshifter.activate(p)
	if shapeshifter.activated[p] then return end

	p.forcedState = FORCEDSTATE_INVISIBLE
	
	shapeshifter.activated[p] = true
end

return shapeshifter