-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2017 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

newTalentType{ allow_random=true, is_steam=true, type="steamtech/missile-fire", name = "remote launcher", description = "Utilize a steamtech launcher for widespread crowd-control." }
newTalentType{ allow_random=true, is_steam=true, type="steamtech/shield-augments", name = "shield augments", description = "Reinforce your shield with custom tinkers for improved retaliatory capabilities." }
newTalentType{ allow_random=true, is_steam=true, type="steamtech/reinforcement", name = "reinforcement", description = "Maintaining order isn't a solo task!" }
newTalentType{ allow_random=true, is_steam=true, type="steamtech/grenades", name = "grenades", on_mastery_change = function(self, m, tt) if self:knowTalentType("technique/missile-fire") ~= nil then self.talents_types_mastery[tt] = self.talents_types_mastery["technique/missile-fire"] end end, description = "Fire in the hole!" }

steamgun_range = Talents.main_env.archery_range

-- Generic requires for techs_dex based on talent level
techs_dex_req1 = {
	stat = { dex=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
techs_dex_req2 = {
	stat = { dex=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
techs_dex_req3 = {
	stat = { dex=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
techs_dex_req4 = {
	stat = { dex=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}
techs_dex_req5 = {
	stat = { dex=function(level) return 44 + (level-1) * 2 end },
	level = function(level) return 16 + (level-1)  end,
}

-- Generic requires for techs_str based on talent level
techs_str_req1 = {
	stat = { str=function(level) return 12 + (level-1) * 2 end },
	level = function(level) return 0 + (level-1)  end,
}
techs_str_req2 = {
	stat = { str=function(level) return 20 + (level-1) * 2 end },
	level = function(level) return 4 + (level-1)  end,
}
techs_str_req3 = {
	stat = { str=function(level) return 28 + (level-1) * 2 end },
	level = function(level) return 8 + (level-1)  end,
}
techs_str_req4 = {
	stat = { str=function(level) return 36 + (level-1) * 2 end },
	level = function(level) return 12 + (level-1)  end,
}
techs_str_req5 = {
	stat = { str=function(level) return 44 + (level-1) * 2 end },
	level = function(level) return 16 + (level-1)  end,
}

-- Generic talents (no stat requirement).
techs_req1 = {
	level = function(level) return 0 + (level-1) end,
}
techs_req2 = {
	level = function(level) return 4 + (level-1) end,
}
techs_req3 = {
	level = function(level) return 8 + (level-1) end,
}
techs_req4 = {
	level = function(level) return 12 + (level-1) end,
}
techs_req5 = {
	level = function(level) return 16 + (level-1) end,
}

-- Generic high level talents (no stat requirement).
techs_high_req1 = {
	level = function(level) return 10 + (level-1) end,
}
techs_high_req2 = {
	level = function(level) return 14 + (level-1) end,
}
techs_high_req3 = {
	level = function(level) return 18 + (level-1) end,
}
techs_high_req4 = {
	level = function(level) return 22 + (level-1) end,
}
techs_high_req5 = {
	level = function(level) return 26 + (level-1) end,
}

load("/data-enforcer/talents/steam/missile-fire.lua")
load("/data-enforcer/talents/steam/shield-augments.lua")
load("/data-enforcer/talents/steam/reinforcement.lua")