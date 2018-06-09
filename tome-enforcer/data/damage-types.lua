-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009 - 2018 Nicolas Casalini
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

local initState = engine.DamageType.initState
local useImplicitCrit = engine.DamageType.useImplicitCrit

-- Damages a range of resources

newDamageType{
	name = "chemical gas", type = "CHEMICAL_GAS",
	projector = function(src, x, y, type, dam, state)
		state = initState(state)
		useImplicitCrit(src, state)
		local target = game.level.map(x, y, Map.ACTOR)
		if target then
			if target:canBe("poison") then
				target:setEffect(target.EFF_CHEMICAL_GAS, 3, { power=dam.power, heal_factor=dam.heal_factor })
			end
		end
	end,
}