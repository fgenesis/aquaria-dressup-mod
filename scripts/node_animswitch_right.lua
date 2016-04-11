if v == nil then v = {} end

local ANIMS = COSTUMES.anims

v.text = 0

function init(me)
	node_setCursorActivation(me, true)
	local x, y = node_getPosition(getNode("animtextpos"))
	v.text = createArialTextBig(ANIMS[ANIM], 1500, x, y)
	text_setAlign(v.text, ALIGN_CENTER)
    text_scale(v.text, 1.2, 1.2)
end

function update(me, dt)
	if(not STOPPED) then
		entity_setState(getNaija(), 1234)
		if(entity_getAnimationName(getNaija()) ~= ANIMS[ANIM]) then
			entity_animate(getNaija(), ANIMS[ANIM], -1)
		end
		text_setText(v.text, ANIMS[ANIM])
	else
		text_setText(v.text, "")
	end
end

function activate(me, dt)
	ANIM = ANIM + 1
	if(ANIM > #ANIMS) then
		ANIM = 1
	end
end