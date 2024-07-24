local block = {}
local id = BLOCK_ID
local jumpblock = require 'jumpblock'

jumpblock.register{
	id = id,
	npcbounce = 10,
	playerbounce = 9,
}

return block