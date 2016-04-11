
v.q = 0

function init(me)
    local q = createQuad("naija/naija2-head")
    local x, y = node_getPosition(me)
    quad_setPosition(q, x, y)
    quad_rotate(q, 360, 1, -1) -- wheee
    v.q = q
end

function update(me, dt)
end

