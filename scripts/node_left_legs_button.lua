function init(me)
end

function update(me, dt)
	node_setCursorActivation(me, true)
end

function activate(me)
	repeat
		LEGS = LEGS - 1
		if(LEGS < 1) then
			LEGS = #COSTUMES
		end
	until(not COSTUMES[COSTUMES[LEGS]].legs)
	
	SET_LEGS(COSTUMES[LEGS])
end