--[[
This file sets all the important stuff needed by other nodes.

In this case, the lists of available clothing items and
what sets they belong in. And keeps track of current selected items.

Also keeps Naija with the correct clothing items.
]]--

dofile("scripts/stuff.lua")
STOPPED = false
local n = getNaija()
local origScaleX, origScaleY = entity_getScale(n)

function init(me)
	entity_setRiding(n, n)
	entity_scale(n, 2, 2)
	avatar_toggleCape(false)
	--local bone = entity_getBoneByIdx(n, 0)
	--bone_setTexture(bone, "naija/dfn-body")
end

function update(me, dt)
	--setCostume(COSTUMES[BODY].."_body")
	--setCostume(COSTUMES[ARMS].."-arms")
	--setCostume(COSTUMES[LEGS].."-legs")
	if(not STOPPED) then
		if(COSTUMES[HEAD] == "naija2") then
			setCostume("")
		else
			setCostume(COSTUMES[HEAD])
		end
		avatar_toggleCape(false)
	end
end

function msg(me, msg)
	if(msg == "stop") then
		STOPPED = true
		entity_setRiding(n, nil)
		entity_scale(n, origScaleX, origScaleY)
		avatar_toggleCape(true)
	end
end