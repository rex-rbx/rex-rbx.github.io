-- source-public is not the same as open source.
-- all rights reserved, except for the use of this software aligning with the intended use
-- prevent scripts from stealing all ur adopt me pets
local ESEC = getgenv().ExtraSecurity
local FuncHashHook;
local clonefunction = clonefunction or clonefunc or function(f) local f = f return function(...) return f(...) end end
local getfunctionhash = getfunctionhash and clonefunction(getfunctionhash) or debug.getfunctionhash and clonefunction(debug.getfunctionhash) or function() return error("no...", 2) end
local require = clonefunction(require)
local assert = clonefunction(assert)
local typeof = clonefunction(typeof)
local DInfo = clonefunction(debug.info)
local remove = clonefunction(table.remove)
local create = clonefunction(table.create)
local gsub = clonefunction(string.gsub)
local next = clonefunction(next)
local ipairs = clonefunction(ipairs)
local pairs = clonefunction(pairs)
local pcall = clonefunction(pcall)
local getgc = getgc and clonefunction(getgc) or function() return create(1000, {}) end
local checkcaller = checkcaller and clonefunction(checkcaller) or function() return true end
local find = clonefunction(table.find)
local error = clonefunction(error)
local Getupvalue = getupvalue and clonefunction(getupvalue) or debug.getupvalue and clonefunction(debug.getupvalue) or function() return nil end
local Getupvalues = getupvalues and clonefunction(getupvalues) or debug.getupvalues and clonefunction(debug.getupvalues) or function() return {} end

local gchooks;

local Loads = require(game:GetService("ReplicatedStorage"):WaitForChild("Fsys")).load
local RouterClient = Loads("RouterClient")
local blocked = {"SettingsAPI/SetSetting", "TradeAPI/ConfirmTrade", "TradeAPI/AcceptNegotiation", "TradeAPI/AddItemToOffer", "TradeAPI/SendTradeRequest", getgenv().ExtraSecurity and "DataAPI/GetAllServerData"}

local OG_Get = RouterClient.OG_Get
local __get__ = function(ToGet, ...)
    assert(typeof(ToGet) == "string", "Expected argument #1 to be of type string, got "..typeof(ToGet))
    local gsubbed = gsub(ToGet, "%z", "")
    if checkcaller() and find(blocked, gsubbed) then
        return error("Attempt to access blocked library: "..gsubbed, 2)
    end
    return OG_Get(ToGet, ...)
end

RouterClient.get = __get__

getupvalue = function(func, index, ...) -- ... is to "imitate" the fact that C Closures are varardic
    if typeof(func) ~= "function" then
        error('non-functions are not supported', 2)
    end

    if func == OG_Get or func == __get__ or func == gchooks or func == FuncHashHook then
        return error("Attempt to access upvalues of a blocked function", 2)
    end
    local s, r = pcall(Getupvalue, func, index, ...)
    if ESEC and not s then
        return error("Sorry, but for security reasons, walking the stack is prohibited.", 2)
    end
    return r
end

getupvalues = function(func, ...)
    if typeof(func) ~= "function" then
        error('non-functions are not supported', 2)
    end

    if func == OG_Get or func == __get__ or func == gchooks or func == FuncHashHook then
        return {}
    end

    local s, r = pcall(Getupvalues, func, ...)
    if ESEC and not s then
        return error("Sorry, but for security reasons, walking the stack is prohibited.", 2)
    end
    return r
end

FuncHashHook = function(func)
    if typeof(func) ~= "function" then
        error('non-functions are not supported', 2)
    end
    if func == OG_Get or func == __get__ or func == gchooks then
        return error("Attempt to access hash of a blocked function", 2)
    end

    return getfunctionhash(func)
end

local Debug = debug

debug = setmetatable({getupvalue = getupvalue, getupvalues = getupvalues}, {
    __index = function(_, k)
        if k == "getupvalue" then
            return getupvalue -- incase they do metatable fuckery on debug to get the original
        elseif k == "getupvalues" then
            return getupvalues
        elseif ESEC and k == "getfunctionhash" then
            return FuncHashHook
        else
            return Debug[k]
        end
    end,
    __newindex = function()
        return error("Attempt to modify read-only table", 2)
    end
})

if ESEC then
    debug = {info = Debug.info, traceback = Debug.traceback}
    getupvalues = nil
    getupvalue = nil
    getgenv().getupvalues = nil
    getgenv().getupvalue = nil
    getgenv().debug = debug
    gchooks = function(...)
        local Orig = getgc(...)
        for i,v in next, Orig do
            if typeof(v) == "function" and (v == OG_Get or v == __get__ or v == gchooks or v == FuncHashHook or DInfo(v, "n") == "get_remote_from_cache") then
                remove(Orig, i)
                if Orig[i] then
                    Orig[i] = nil -- incase table.remove doesn't shift the table down
                end
            end
        end
        return Orig
    end
    getgc = gchooks
    getgenv().getgc = gchooks
    getfunctionhash = FuncHashHook
    getgenv().getfunctionhash = FuncHashHook
else
    getgenv().debug = debug
    getgenv().getupvalue = getupvalue
    getgenv().getupvalues = getupvalues
end
