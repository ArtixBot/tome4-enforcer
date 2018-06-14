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
	-- Flashbang: Blind and decaying global speed slow.
	-- Noxious Gas: Reduces outgoing damage and heal mod.
	-- Shrapnel: Bleed.
	name = "Grenade Launcher",
	type = {"steamtech/missile-fire", 1},
	mode = "passive",
	points = 5,
	require = techs_str_req1,
	passives = function(self, t)
		self:setTalentTypeMastery("steamtech/grenades", self:getTalentMastery(t))
	end,
	on_learn = function(self, t)
		self:learnTalent(self.T_GRENADE_FLASHBANG, true, nil, {no_unlearn=true})
		self:learnTalent(self.T_GRENADE_CHEMICAL_GAS, true, nil, {no_unlearn=true})
		self:learnTalent(self.T_GRENADE_SHRAPNEL, true, nil, {no_unlearn=true})
	end,
	on_unlearn = function(self, t)
		self:unlearnTalent(self.T_GRENADE_FLASHBANG)
		self:unlearnTalent(self.T_GRENADE_CHEMICAL_GAS)
		self:unlearnTalent(self.T_GRENADE_SHRAPNEL)
	end,
	info = function(self, t)
		local ret = ""
		local old1 = self.talents[self.T_GRENADE_FLASHBANG]
		local old2 = self.talents[self.T_GRENADE_CHEMICAL_GAS]
		local old3 = self.talents[self.T_GRENADE_SHRAPNEL]
		self.talents[self.T_GRENADE_FLASHBANG] = (self.talents[t.id] or 0)
		self.talents[self.T_GRENADE_CHEMICAL_GAS] = (self.talents[t.id] or 0)
		self.talents[self.T_GRENADE_SHRAPNEL] = (self.talents[t.id] or 0)
		pcall(function()
			local t1 = self:getTalentFromId(self.T_GRENADE_FLASHBANG)
			local t2 = self:getTalentFromId(self.T_GRENADE_CHEMICAL_GAS)
			local t3 = self:getTalentFromId(self.T_GRENADE_SHRAPNEL)
			ret = ([[Attach a heavy "remote propellant device" to your steam generator, siphoning excess steam which you use to bombard foes.
			You can fire one of three grenades up to range 9: Flashbang, Noxious Gas, Shrapnel.
			
			Flashbang: Blinds and reduces global speed of hit targets by %d%% (effects decay by %0.2f%% each turn) in a radius-2 circle for %d turns.
			Chemical Gas: Disperses crippling gases in a radius-3 circle. All units currently within the area of effect deal %d%% reduced damage and have %d%% reduced healing mod, lasting up to 3 turns after leaving the area. The gas lingers for 5 turns.
			Shrapnel: Explodes, sending chunks of shrapnel in a radius-2 circle. All hit units take physical bleed damage over five turns, dealing %d damage overall.]]):
			format(t1.getSlow(self, t) * 100, 100 / t1.getDuration(self, t), t1.getDuration(self, t), t2.getDam(self, t), t2.getMod(self, t), t3.getDam(self, t))
		end)
		self.talents[self.T_GRENADE_FLASHBANG] = old1
		self.talents[self.T_GRENADE_CHEMICAL_GAS] = old2
		self.talents[self.T_GRENADE_SHRAPNEL] = old3
		return ret
	end,
}

newTalent{
	-- After firing a grenade, dash to an adjacent tile.
	-- Clears mental debuffs at lvl 3+.
	name = "Blast Manuevers",
	type = {"steamtech/missile-fire", 2},
	points = 5,
	require = techs_str_req2,
	steam = 10,
	no_energy = true,
	tactical = { CLOSEIN = 3, ESCAPE = 3 },
	cooldown = function(self, t) return math.ceil(11 - self:getTalentLevel(t)) end,
	getClear = function(self, t)
		if self:getTalentLevel(t) >= 5 then
			return 2
		elseif self:getTalentLevel(t) >= 3 then return 1
		else return 0
		end
	end,
	range = 2,	-- Would've preferred 1 but targeting screwery occurs if it's at 1.
	target = function(self, t) return {type="hit", range=self:getTalentRange(t), talent = t} end,
	on_pre_use = function(self, t, silent)
		if not self:hasEffect(self.EFF_BLAST_MANUEVERS) then
			if not silent then
				game.logPlayer(self, "You must fire a grenade for this talent to be available!")
			end
			return false
		end
		return true
	end,
	callbackOnTalentPost = function(self, t, ab, ret)
		if (ab.id == self.T_GRENADE_FLASHBANG or ab.id == self.T_GRENADE_CHEMICAL_GAS or ab.id == self.T_GRENADE_SHRAPNEL) and ret == true then
			if self:isTalentCoolingDown(t) then
				-- Reduce cooldown if on it.
				self:alterTalentCoolingdown(self.T_BLAST_MANUEVERS, -1)
			else
				self:setEffect(self.EFF_BLAST_MANUEVERS, 1, {})
			end
		end
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y then return end
		if self.x == x and self.y == y then return end
		if core.fov.distance(self.x, self.y, x, y) > self:getTalentRange(t) or not self:hasLOS(x, y) then return end

		if target or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move", self) then
			game.logPlayer(self, "You must have an empty space to reposition to.")
			return false
		end

		-- Since this ability can't even be used unless we have the specific buff, this check is unnecessary but better safe than sorry.
		if self:hasEffect(self.EFF_BLAST_MANUEVERS) then
			self:removeEffect(self.EFF_BLAST_MANUEVERS)
			game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_whispery_bright"})
			game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_heavy_bright"})
			game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_dark"})

			self:move(x, y, true)
			
			-- Mental debuff clear @level 3+
			if self:getTalentLevel(t) >= 3 then
				local effs = {}
				local count = t.getClear(self, t)

				-- Go through all mental effects
				for eff_id, p in pairs(self.tmp) do
					local e = self.tempeffect_def[eff_id]
					if e.type == "mental" and e.status == "detrimental" then
						effs[#effs+1] = {"effect", eff_id}
					end
				end

				for i = 1, t.getClear(self, t) do
					if #effs == 0 then break end
					local eff = rng.tableRemove(effs)

					if eff[1] == "effect" then
						self:removeEffect(eff[2])
						count = count - 1
					end
				end
				game.logSeen(self, "#LIGHT_BLUE#Blast Manuevers clears %s's mind!", self.name:capitalize())
			end
		end
		
		return true
	end,
	info = function(self, t)
		return ([[Firing a grenade disperses steam from auxillary vents, which can be directed to propel you in any direction.
		In effect, this talent can be activated one turn after firing any grenade to instantly move to an unoccupied tile within range 2. If this talent is on cooldown firing a grenade instead reduces this talent's cooldown by one turn.
		At talent level 3, the steam vapours invigorate you, clearing up to %d detrimental mental effect(s).]]):format(t.getClear(self, t))
	end,
}

newTalent{
	name = "Shock and Awe",
	type = {"steamtech/missile-fire", 3},
	mode = "passive",
	points = 5,
	require = techs_str_req3,
	getConfPwr = function(self, t) return self:combatTalentScale(t, 10, 25) end,
	getPoiDmg = function(self, t) return self:combatTalentScale(t, 8, 15) end,	-- The true value of the crippling poison is talent failure, not damage.
	getPoiFail = function(self, t) return self:combatTalentScale(t, 10, 22) end,
	getRadUp = function(self, t)
		if self:getTalentLevel(t) >= 3 then
			return 2
		else
			return 1
		end
	end,
	info = function(self, t)
		return ([[Enhances your grenades' effects.
		Grenade: Flashbang now emits piercing soundwaves which induce confusion (%d%% power) in hit targets for 3 turns.
		Grenade: Chemical Gas disperses a neurotoxic agent on impact; targets caught in the initial blast are afflicted with crippling poison, dealing %d nature damage and giving talents a %d%% chance to fail, for 3 turns.
		Grenade: Shrapnel fires shrapnel at extreme speeds, increasing area of effect by %d.]]):
		format(t.getConfPwr(self, t), t.getPoiDmg(self, t), t.getPoiFail(self, t), t.getRadUp(self, t))
	end,
}

newTalent{
	-- Chance for free grenade launches!
	name = "Hair Trigger Mechanism",
	type = {"steamtech/missile-fire", 4},
	mode = "sustained",
	points = 5,
	require = techs_str_req4,
	cooldown = 6,	-- Prevent players from picking a grenade, then swapping to a new one immediately after landing the previous one.
	drain_steam = 3,
	no_energy = true,
	no_npc_use = true,
	no_sustain_autoreset = true,
	getChance = function(self, t) return self:combatTalentScale(t, 9, 27) end,	-- Only one grenade can be fired this way / turn so AoE shots don't carpet bomb the area.
	activate = function(self, t)
		local talent = self:talentDialog(require("mod.dialogs.talents.EnforcerHairTrigger").new(self))
		if talent then
			return {talent = talent, rest_count = 0} 
		else return nil end
	end,
	deactivate = function(self, t, p)
		return true
	end,
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		-- Maybe a bit excessive on the checks, but hey better that than Lua errors.
		if self:isTalentActive(t.id) and self:getTalentFromId(self:isTalentActive(t.id).talent) ~= nil and rng.percent(t.getChance(self, t)) and not self.turn_procs.hair_trigger then
			local talent = self:isTalentActive(t.id).talent
			self:forceUseTalent(talent, {ignore_energy = true, ignore_cd = true, ignore_ressources=true, no_talent_fail = true, force_target={x = target.x, y = target.y}})
			game.logSeen(self, "#LIGHT_BLUE#%s's Hair Trigger Mechanism activates!", self.name:capitalize())
			self.turn_procs.hair_trigger = true
		end
	end,
	info = function(self, t)
		local talent = self:isTalentActive(t.id) and self:getTalentFromId(self:isTalentActive(t.id).talent).name or "None"
		return ([[Select a grenade skill.
		Every time you fire your steamgun there's a %d%% chance that the selected grenade is launched at the same location you fired at.
		Grenades fired in this manner are instant, ignore available resources, do not incur cooldowns, and activate both Blast Manuevers and Shock and Awe.
		This bonus grenade can only trigger once per turn, and does not trigger from melee attacks.
		
		Currently Selected Grenade: %s]]):format(t.getChance(self, t), talent)
	end,
}

-- GRENADE TALENTS --

newTalent{
	name = "Grenade: Flashbang", short_name = "GRENADE_FLASHBANG",
	type = {"steamtech/grenades", 1},
	points = 5,
	range = 9,
	radius = 2,
	cooldown = 14,
	steam = 10,
	proj_speed = 6,
	hide = true,
	direct_hit = true,
	tactical = { ATTACKAREA = 2, DISABLE = 2 },
	getSlow = function(self, t) return self:combatTalentScale(t, 0.20, 0.40) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 3, 5)) end,
	target = function(self, t) return {type="ball", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, friendlyfire = false, talent = t, display={particle="bolt_light", particle_args={size_factor=0.75}, trail="lighttrail"}} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		
		game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_whispery_bright"})
		game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_heavy_bright"})
		
		-- Getting the particle effects to work on this ~as originally intended~ is unbelievably infuriating.
		-- Finally done though.
		self:projectile(tg, x, y, function(px, py, tg, self)
			game.level.map:particleEmitter(px, py, 1, "light")
			
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			target:setEffect(target.EFF_FLASHBANG_BLIND, t.getDuration(self, t), {power=t.getSlow(self, t), orig_dur = t.getDuration(self, t), apply_power=self:combatSteampower()})
			if self:knowTalent(self.T_SHOCK_AND_AWE) then
				local confPow = self:callTalent(self.T_SHOCK_AND_AWE, "getConfPwr")
				target:setEffect(target.EFF_CONFUSED, 3, {power = confPow})
			end
				
		end)
		
		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		return ([[Launch a flashbang grenade which quickly travels towards the target area.
		Once it lands the grenade detonates, emitting a bright flash of light that blinds and slows (intensity %d%%, before scaling down) all enemies in a 2-tile radius around it for %d turns.
		The slow's intensity decays by %0.2f%% each turn.
		Negative effect application chance increases with Steampower.]]):format(t.getSlow(self, t) * 100, t.getDuration(self, t), 100 / t.getDuration(self, t))
	end,
}

newTalent{
	name = "Grenade: Chemical Gas", short_name = "GRENADE_CHEMICAL_GAS",
	type = {"steamtech/grenades", 1},
	points = 5,
	range = 9,
	radius = 3,
	cooldown = 14,
	steam = 10,
	proj_speed = 6,
	hide = true,
	direct_hit = true,
	tactical = { ATTACKAREA = 2, DISABLE = 2 },
	getDam = function(self, t) return self:combatTalentScale(t, 12, 26) end,
	getMod = function(self, t) return self:combatTalentScale(t, 23, 45) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 5, 9)) end,
	target = function(self, t) return {type="ball", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, friendlyfire = false, talent = t, display={particle="bolt_light", particle_args={size_factor=0.75}, trail="lighttrail"}} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		
		game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_whispery_bright"})
		game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_dark"})
		
		local damType = DamageType.COSMETIC
		local damDealt = 0
		
		if self:knowTalent(self.T_SHOCK_AND_AWE) then
			local a = self:callTalent(self.T_SHOCK_AND_AWE, "getPoiDmg")
			local b = self:callTalent(self.T_SHOCK_AND_AWE, "getPoiFail")
			damType = DamageType.CRIPPLING_POISON
			damDealt = {src = self, dur = 3, dam = a * 3, fail = b}
		end
		
		-- The projectile itself doesn't deal damage (at least until Shock and Awe). As it turns out, cosmetic is a damage type and it doesn't clog the logs. How convenient!
		self:projectile(tg, x, y, damType, damDealt, function(self, tg, x, y, grids)
			game.level.map:addEffect(self,
				x, y, 5,	-- Effect epicenter location and duration.
				DamageType.CHEMICAL_GAS, {power = t.getDam(self, t), heal_factor = t.getMod(self, t)},	-- Damage type / damage dealt.
				3,	-- Effect radius.
				5, 5, 	-- Ball effect, angle. 5 for center.
				{type="vapour"}	--Overlay effect.
			)
		end)
		
		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		return ([[Launch a chemical gas grenade which quickly travels towards the target area.
		Once it lands the grenade activates, dispersing a field of crippling vapors in a radius 3 circle, lasting 5 turns.
		All units (friend or foe) inside the target area are poisoned, reducing damage dealt by %d%% and healing mod by %d%%.
		This lasts up to 3 turns once outside the area of effect (but is indefinite otherwise).]]):format(t.getDam(self, t), t.getMod(self, t))
	end,
}

newTalent{
	name = "Grenade: Shrapnel", short_name = "GRENADE_SHRAPNEL",
	type = {"steamtech/grenades", 1},
	points = 5,
	range = 9,
	radius = function(self, t)
		if self:knowTalent(self.T_SHOCK_AND_AWE) then
			return 2 + self:callTalent(self.T_SHOCK_AND_AWE, "getRadUp")
		else
			return 2
		end
	end,
	cooldown = 14,
	steam = 10,
	proj_speed = 6,
	direct_hit = true,
	hide = true,
	tactical = { ATTACKAREA = 2, DISABLE = 2 },
	getDam = function(self, t) return self:combatTalentSteamDamage(t, 85, 300) end,
	getDuration = function(self, t) return math.floor(self:combatTalentScale(t, 5, 9)) end,
	target = function(self, t) return {type="ball", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, friendlyfire = false, talent = t, display={particle="bolt_light", particle_args={size_factor=0.75}, trail="lighttrail"}} end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		
		game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_heavy_bright"})
		game.level.map:particleEmitter(self.x, self.y, 2, "vapour_explosion", {radius=1, life=rng.range(10, 15), smoke="particles_images/smoke_dark"})
		
		self:projectile(tg, x, y, DamageType.BLEED, t.getDam(self, t), function(self, tg, tx, ty, grids)
			game.level.map:particleEmitter(x, y, tg.radius, "ball_earth", {radius = tg.radius, tx=x, ty=y})
		end)
		
		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		return ([[Launch a shrapnel grenade which quickly travels towards the target area.
		Once it lands the grenade explodes, hurling shrapnel in a radius %d circle.
		Hit targets take %d physical damage over six turns. Allies are unaffected.
		Damage increases with Steampower.]]):format(self:getTalentRadius(t), t.getDam(self, t))
	end,
}
