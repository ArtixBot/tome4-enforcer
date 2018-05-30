local class = require "engine.class"
local Birther = require "engine.Birther"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"

class:bindHook("ToME:load", function(self, data)
	ActorTalents:loadDefinition("/data-enforcer/talents/techniques/techniques-enforcer.lua")
	ActorTalents:loadDefinition("/data-enforcer/talents/steam/steam-enforcer.lua")
	ActorTemporaryEffects:loadDefinition("/data-enforcer/timed-effects.lua")
	Birther:loadDefinition("/data-enforcer/birth/classes/enforcer.lua")
end)