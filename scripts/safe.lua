-- FG: Based on some code from our sequel mod.
-- This file patches global and local environments
-- to complain very loudly about errors,
-- instead of silently ignoring most of them.

if not rawget(_G, "getInterfaceFunctionNames") then
    local f = debugLog
    if not rawget(_G, ".safeFailedDidComplain") then
        f = errorLog
        rawset(_G, ".safeFailedDidComplain", true)
    end
    f("Can't load safe.lua -- API function getInterfaceFunctionNames() missing.\nContinuing in the best hopes that nothing will go wrong.")
    return
end

assert(_scriptfuncs, "_scriptfuncs undefined")
assert(_scriptvars, "_scriptvars undefined")

local function dummy()
end

local function dummyTrue()
    return true
end

-- it is true, can be called, and is a table, so it will not cause further errors hopefully (now wish it was also a string)
local universalDummy = setmetatable({}, { __call = dummy } )


local vmetaProto = {
    __index = function(t, k)
        error("[V PROTO] Trying to read undefined instance local: " .. tostring(k))
    end,
}

local vmetaInstance = {
    __index = function(t, k)
        errorLog("Trying to read undefined instance local: " .. tostring(k))
        rawset(t, k, universalDummy) -- to prevent "attempt to call a nil value" and etc. Especially prevent further messagebox spam!
        return universalDummy
    end,
    __newindex = function(t, k, val)
        rawset(t, k, val)
        debugLog("Warning: Set undeclared instance local [" .. type(val) .. "]: " .. tostring(k) .. " = " .. tostring(val)) -- TODO: make this errorLog
        playSfx("click")
    end,
}

local function fortifyVtable(v, proto)  
    if proto then
        setmetatable(v, vmetaProto)
    else
        setmetatable(v, vmetaInstance)
    end
end

local function errorHandler(s)
    s = tostring(s)
    errorLog(s)
    return s
end


local safeWrap
do
    local ARGS = {}
    local NUMARGS = 0
    local CALLFUNC = false
    local select = select
    local unpack = unpack

    local function _fillArgs(f, ...)
        CALLFUNC = f
        NUMARGS = select("#", ...)
        for i = 1, NUMARGS do
            ARGS[i] = select(i, ...)
        end
    end

    local function _callHelper(f)
        return CALLFUNC(unpack(ARGS, 1, NUMARGS)) -- this safely handles returned NILs or NILs in ARGS
    end

    safeWrap = function(f)
        local call = true
        
        local function _callHelperLocal(ok, ...)
            call = ok
            return ...
        end

        return function(...)
            if not call then
                return
            end

            _fillArgs(f, ...)
            return _callHelperLocal(xpcall(_callHelper, errorHandler))
        end
    end
end

local function safeWrapInterfaceFuncs(env)
    for _, name in pairs(getInterfaceFunctionNames()) do
        local f = rawget(env, name)
        if f and f ~= dummy and f ~= dummyTrue then
            local wf = safeWrap(f)
            rawset(env, name, wf)
        end
    end
end

local function setDefaultGlobalFuncs(env)
    -- prevent "attempt to call a nil value" from engine side
    if not rawget(env, "damage") then
        rawset(env, "damage", dummyTrue) -- damage() must either fail or return true, otherwise the game assumes false and everything is invincible by default
    end
    for _, name in pairs(getInterfaceFunctionNames()) do
        if not rawget(env, name) then
            rawset(env, name, dummy)
        end
    end
end


local function fortify(env)
    env = env or _G
    setDefaultGlobalFuncs(env)
    safeWrapInterfaceFuncs(env)
end


-- this function must never raise an error, otherwise the program will crash
local function onCreateScript(tab, sc, functable)

    local vars = rawget(_scriptvars, sc) -- we know this is set *before* _scriptfuncs sends us here
    if vars then
        rawset(vars, ".scriptName", sc)
        rawset(vars, ".funcTable", functable)
    else
        errorLog("onCreateScript OOPS -- " .. tostring(sc))
    end
    rawset(functable, ".scriptName", sc)
    
    -- patch the init function to install the v metatable with very restrictive checks
    local realinit = functable.init or dummy -- we know this is at least set by setDefaultGlobalFuncs() in fortify()
    assert(realinit, "No init function for script " .. sc) -- this WILL crash if failed
    functable.init = function(...)
        -- when this function is called, the engine has already copied all instance locals from the template
        fortifyVtable(_G.v, false) -- this will access the currently active script's v table
        return realinit(...)
    end
    
    fortify(functable)
    
    -- do the set, or it will crash
    rawset(tab, sc, functable) -- _scriptfuncs[sc] = functable{init(), update(), etc.}
end

debugLog("safe.lua: setting _scriptfuncs metatable...")
setmetatable(_scriptfuncs, {
    __newindex = onCreateScript
})


local debug = rawget(_G, "debug")
local OG = rawget(_G, ".originalFuncs")
if not OG then
    OG = {}
    rawset(_G, ".originalFuncs", OG)
end

if not rawget(_G, "INTERNAL") then
    INTERNAL = setmetatable({},
        { __index = function(t, k) return OG[k] or _G[k] end,
          __newindex = function(t, k, val) errorLog("INTERNAL: Attempt to set key: " .. tostring(k)) end
        })
end

local function formatStack(lvl)
    if debug then
        if not lvl then lvl = 1 end
        return debug.traceback("", lvl) or "[No traceback available]"
    end
    return "[No debug library available]"
end

local function override(fname, ovf)
    debugLog("Registering function override: " .. fname)
    if not OG[fname] then
        OG[fname] = _G[fname]
    end
    _G[fname] = ovf
end

local function restore(fname)
    local of = OG[fname]
    if of then
        _G[fname] = of
        return true
    end
    return false
end

local function ov_errorLog(s)
   local tr = formatStack(3)
   INTERNAL.errorLog(s .. "\n" .. tr)
   return s
end

for fname, _ in pairs(OG) do
    restore(fname)
end

override("errorLog", ov_errorLog)
-- can override more if needed


debugLog("safe.lua established")
