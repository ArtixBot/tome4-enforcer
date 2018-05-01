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

newTalent{
	-- Fire one of three grenade types.
	-- Flashbang: Stun and blind.
	-- Noxious Gas: Damage and global speed reduction.
	-- Shrapnel: Bleed.
	name = "Grenade Launcher",
	type = {"steamtech/missile-fire", 1},
	points = 5,
	cooldown = 10,
	mode = "sustained",
	require = steamreq1,
	tactical = { BUFF=2 },
	requires_target = true,
	range = 10,
	drain_steam = 4, -- 1 less than starting steam generator
	getSplash = function(self, t) return self:combatTalentSteamDamage(t, 2, 50) end,
	getReduction = function(self, t) return self:combatTalentLimit(t, 40, 5, 25) end,
	getResists = function(self, t) return self:combatTalentLimit(t, 40, 5, 20) end,
	activate = function(self, t)
		local ret = {}
		self:talentTemporaryValue(ret, "on_melee_hit", {[DamageType.FIRE] = t.getSplash(self, t)})
		self:talentTemporaryValue(ret, "resists", {all=t.getResists(self, t)})
		self:talentTemporaryValue(ret, "reduce_detrimental_status_effects_time", t.getReduction(self, t))
		return ret
	end,
	deactivate = function(self, t, p)
		return true
	end,
	info = function(self, t)
		return ([[Equipped with you at all times is the steam-powered "Grenade Launcher," nominally used for crowd control purposes.
		The GC-001 comes equipped with three tinkers: Flashbang, Noxious Gas, and Shrapnel.
		
		Flashbang: Stuns and blinds targets in a radius-XX circle for XX turns.
		
		Noxious Gas: Disperses crippling gases in a radius-XX circle. All units currently within the area of effect deal XX reduced damage and have XX reduced global speed. The gas lingers for XX turns.
		
		Shrapnel: Explodes, sending chunks of shrapnel in a radius-XX circle. All hit units bleed for XX damage over XX turns.
		
		Using any one of these abiltiies places the other two on a short cooldown, as the GC-001 needs time to fabricate another grenade. Effects increase with Steampower.]])
	end,
}

newTalent{
	-- Enhances next grenade.
	-- Flashbang: Adds incendiary elements, burning all targets.
	-- Noxious Gas: Infuses antimagic elements, silencing targets and burning magical resources.
	-- Shrapnel: Overloads the grenade, increasing area of effect and shredding armor.
	name = "Volatile Chemicals",
	type = {"steamtech/missile-fire", 2},
	points = 5,
	require = steamreq2,
	cooldown = 12,
	steam = 30,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 2, 240) end,
	tactical = { DISABLE = 1 },
	range = 10,
	reflectable = true,
	proj_speed = 2,
	requires_target = true,
	target = function(self, t)
		return {type="bolt", range=self:getTalentRange(t), talent=t, friendlyfire=false, selffire=false, display={display=' ', particle="arrow", particle_args={tile="shockbolt/npc/mechanical_drone_mind_drone"}}}
	end,
	getFail = function(self, t) return self:combatTalentLimit(t, 50, 19, 35) end, -- Limit < 50%
	getReduction = function(self, t) return self:combatTalentLimit(t, 70, 25, 65) end, -- Limit < 50%
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end

		local lx, ly
		local a = math.atan2(y - self.y, x - self.x) + math.pi / 2
		local l = core.fov.line(self.x, self.y, self.x + 10 * math.cos(a), self.y + 10 * math.sin(a))
		local nb = 0
		while nb < 2 do
			lx, ly = l:step() if not lx then break end
			local tg = self:getTalentTarget(t)
			tg.start_x = lx
			tg.start_y = ly
			self:projectile(tg, x, y, DamageType.MIND_DRONE, {dam=0, fail=t.getFail(self, t), reduction=t.getReduction(self, t)})
			nb = nb + 1
		end
		a = a + math.pi
		nb = 0
		local l = core.fov.line(self.x, self.y, self.x + 10 * math.cos(a), self.y + 10 * math.sin(a))
		while nb < 2 do
			lx, ly = l:step() if not lx then break end
			local tg = self:getTalentTarget(t)
			tg.start_x = lx
			tg.start_y = ly
			self:projectile(tg, x, y, DamageType.MIND_DRONE, {dam=0, fail=t.getFail(self, t), reduction=t.getReduction(self, t)})
			nb = nb + 1
		end
		local tg = self:getTalentTarget(t)
		self:projectile(tg, x, y, DamageType.MIND_DRONE, {dam=0, fail=t.getFail(self, t), reduction=t.getReduction(self, t)})

		return true
	end,
	info = function(self, t)
		return ([[Enhance the next grenade you fire with volatile elements, augmenting its effects.
		
		Flashbang: Incorporates incendiary elements, causing all hit targets to burn for XX damage over XX turns.
		
		Noxious Gas: Incorporates antimagic elements, silencing all targets in the area of effect and burning XX arcane resource(s) per turn.
		
		Shrapnel: Overloads the grenade with excessive steam, increasing area of effect by XX tiles and shredding XX Armor for XX turns.
		
		Effects increase with Steampower.]])
	end,
}

newTalent{
	name = "Blastback",
	type = {"steamtech/missile-fire", 3},
	points = 5,
	cooldown = 20,
	steam = 30,
	require = steamreq3,
	tactical = { CURE = function(self, t, target)
		local nb = 0
		for eff_id, p in pairs(self.tmp) do
			local e = self.tempeffect_def[eff_id]
			if e.status == "detrimental" and e.type == "mental" then nb = nb + 1 end
		end
		return nb
	end},
	no_energy = true,
	requires_target = true,
	range = 5,
	getNum = function(self, t) return math.floor(self:combatTalentScale(t, 1, 5)) end,
	action = function(self, t)

		-- Pick valid targets for transfer attempt
		local tgts = {}
		self:project({type="ball", radius=5}, self.x, self.y, function(px, py)
			local act = game.level.map(px, py, Map.ACTOR)
			if not act or self:reactionToward(act) >= 0 then return end
			tgts[#tgts+1] = act
		end)

		-- Transfer the debuffs before they're removed in the filter function
		local cleansed = self:removeEffectsFilter(function(eff)
			if eff.status == "detrimental" and eff.type == "mental" then
				if #tgts > 0 then
					local target = rng.table(tgts)
					local newp = self:copyEffect(eff.id)
					newp.src = self
					newp.apply_power = self:combatSteampower()
					target:setEffect(eff.id, newp.dur, newp)
				end
				return true
			else
				return false
			end
		end, t.getNum(self, t))
		
		return true
	end,
	info = function(self, t)
		return ([[Utilize all your steam reserves to deliver a rocket-powered shrapnel blast from the GC-001, dealing XX damage and causing targets to burn for XX damage over XX turns in a XX-radius cone.
		The sheer force of the blast pushes you back XX tiles.
		Damage scales based on remaining Steam reserves and Steampower.]])
	end,
}

newTalent{
	-- Buff which removes all grenade cooldowns while active.
	name = "Bombardment",
	type = {"steamtech/missile-fire", 4},
	points = 5,
	require = steamreq4,
	cooldown = 0,
	no_npc_use = true,
	getPower = function(self, t) return math.floor(60 + self:combatTalentScale(t, 10, 50)) end,
	getCooldownMod = function(self, t) return math.floor(140 - self:combatTalentLimit(t, 60, 5, 40)) end,
	on_learn = function(self, t)
		if self:getTalentLevelRaw(t) == 1 then self:addMedicalInjector(t) end
		self.inscriptions_data.MIND_INJECTION = {
			power = t.getPower(self, t),
			cooldown_mod = t.getCooldownMod(self, t),
			cooldown = 1,
		}
	end,
	on_unlearn = function(self, t)
		self.inscriptions_data.MIND_INJECTION = {
			power = t.getPower(self, t),
			cooldown_mod = t.getCooldownMod(self, t),
			cooldown = 1,
		}
		if self:getTalentLevelRaw(t) == 0 then self:removeMedicalInjector(t) self.inscriptions_data.MIND_INJECTION = nil end
	end,
	action = function(self, t)
		game.bignews:saySimple(120, "#LIGHT_BLUE#Mind Injection selected to be used first by salves.")
		game.logPlayer(self, "This medical injector will now be used first if available when using medical salves.")
		self:setFirstMedicalInjector(t)
		return false
	end,
	info = function(self, t)
		return ([[Overcharge your GC-001 to dangerous levels for a short time.
		For XX turns, all grenades are empowered and all grenade cooldowns are removed.
		
		Utilizing Blastback while Bombardment is active disables the GC-001 from sheer heat strain; all Grenade skills are disabled for 50 turns and you take XX self-damage.
		However, Blastback gains XX increased range, deals +XX damage, and gains 100% fire resistance penetration.]])
	end,
}
