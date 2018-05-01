local class = require "engine.class"
local Birther = require "engine.Birther"
local ActorTalents = require "engine.interface.ActorTalents"

class:bindHook("ToME:load", function(self, data)
	ActorTalents:loadDefinition("/data-enforcer/talents/techniques/techniques-enforcer.lua")
	ActorTalents:loadDefinition("/data-enforcer/talents/steam/steam-enforcer.lua")
	Birther:loadDefinition("/data-enforcer/birth/classes/enforcer.lua")
end)