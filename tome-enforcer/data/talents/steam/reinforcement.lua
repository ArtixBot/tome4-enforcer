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
	-- Deploy a friendly turret. It shoots at enemies within range each turn to apply negative status effects.
	name = "Riot Turret",
	type = {"steamtech/reinforcement", 1},
	require = steamreq1,
	range = 1,
	points = 5,
	steam = 20,
	cooldown = 18,
	tactical = { ATTACKAREA = {LIGHTNING = 2} },
	requires_target = true,
	getArmor = function(self, t) return self:combatTalentSteamDamage(t, 5, 75) end,
	getHP = function(self, t) return self:combatTalentSteamDamage(t, 10, 1000) end,
	action = function(self, t)
		local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, simple_dir_request=true, talent=t}
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty then return nil end
		local _ _, _, _, tx, ty = self:canProject(tg, tx, ty)
		target = game.level.map(tx, ty, Map.ACTOR)
		if target == self then target = nil end

		-- Find space
		local x, y = util.findFreeGrid(tx, ty, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "Not enough space to summon!")
			return
		end
		
		local NPC = require "mod.class.NPC"
		local m = NPC.new{
			type = "construct", subtype = "sentry",
			display = "*", color=colors.BLUE,
			name = "Riot Turret", faction = self.faction, image = "object/mechanical_core.png",
			autolevel = "none",
			ai = "summoned", ai_real = "tactical", ai_state = { talent_in=1, },
			level_range = {1, 1}, exp_worth = 0,
			body = { INVEN = 10, MAINHAND = 1, QUIVER = 1},
			power_source = {steam=true},

			max_life = self:steamCrit(t.getHP(self, t)),
			life_rating = 0,
			never_move = 1,

			combat_atk = 300,	-- Diminishing returns means 300 raw accuracy is needed for 100 effective accuracy.

			combat_armor_hardiness = 100,
			combat_armor = t.getArmor(self, t),
			resists = {all = 25},

			negative_status_effect_immune = 1,
			cant_be_moved = 1,
			
			resolvers.talents{
				[self.T_SHOOT]=1,
				[self.T_STEAM_POOL]=1,
				[self.T_RUBBER_ROUNDS]=1,
				
				[Talents.T_SUBJUGATION] = self:getTalentLevelRaw(self.T_SUBJUGATION),
				[Talents.T_SUBDUED_TARGETS] = self:getTalentLevelRaw(self.T_SUBDUED_TARGETS),
				[Talents.T_STAY_DOWN] = self:getTalentLevelRaw(self.T_STAY_DOWN),
				[Talents.T_HUNKERED_EXPLOITS] = self:getTalentLevelRaw(self.T_HUNKERED_EXPLOITS),
				
				[Talents.T_AREA_DENIAL] = self:getTalentLevelRaw(self.T_MASTERFUL_CRAFTSMANSHIP),
				[Talents.T_REACTIVE_ARMOR] = self:getTalentLevelRaw(self.T_MASTERFUL_CRAFTSMANSHIP),
			},
			
			-- Turret mastery will scale with user masteries as appropriate.
			-- Since talents_type_mastery just adds to a talents category value, and all start at 1, subtract by 1 and then add the user's category masteries.
			talents_types_mastery = {
				["steamtech/other"] = -1 + self:getTalentTypeMastery("steamtech/reinforcement"),
				["technique/suppression"] = -1 + self:getTalentTypeMastery("technique/suppression"),
			},
			
			
			resolvers.equip{
				{type="weapon", subtype="steamgun", name="iron steamgun", base_list="mod.class.Object:/data-orcs/general/objects/steamgun.lua", autoreq=true, ego_chance=-1000},
				{type="ammo", subtype="shot", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"}, ego_chance=-1000 },
			},

			summoner = self, summoner_gain_exp=true,
			summon_time = 11,	-- The ability cast itself takes 1 turn.
		}
		
		m.summoner_steampower = self:combatSteampower()
		m.combatSteampower = function(self) return self.summoner_steampower end

		m:resolve() m:resolve(nil, true)
		m:forceLevelup(self.level)
		game.zone:addEntity(game.level, m, "actor", x, y)
		return true
	end,
	info = function(self, t)
		return ([[Deploy a riot turret adjacent to you, lasting 10 turns.
		The turret has %d health, %d armor, and 100 effective Accuracy. It inherits your effective Steampower stat.
		#{italic}#If you have invested points into the Suppression tree then the Riot Turret gains those talents as well.#{normal}#
		
		Every turn it fires pain-maximizing rubber rounds. #YELLOW#Beware of friendly fire!#WHITE#
		These deal negligible damage, but targets which fail a physical save are inflicted with a 2-turn random detrimental physical effect: stun, pin, confuse, or cripple.
		The turret's health, armor, Steampower, and debuff chance increases with your Steampower.]]):format(t.getHP(self, t), t.getArmor(self, t))
	end,
}

newTalent{
	-- Deploy a friendly thumper. It emits shockwaves each turn which has a 80/20% chance to daze/stun, respectively.
	name = "Sonic Pulser",
	type = {"steamtech/reinforcement", 2},
	require = steamreq2,
	range = 6,
	points = 5,
	steam = 20,
	cooldown = 24,
	tactical = { ATTACKAREA = {LIGHTNING = 2} },
	requires_target = true,
	getArmor = function(self, t) return self:combatTalentSteamDamage(t, 10, 100) end,
	getHP = function(self, t) return self:combatTalentSteamDamage(t, 15, 1250) end,
	target = function(self, t) return {type="bolt", nowarning=true, radius=2, range=self:getTalentRange(t), nolock=true, simple_dir_request=true, talent=t} end, -- for the ai
	action = function(self, t)
		local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, simple_dir_request=true, talent=t}
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty then return nil end
		local _ _, _, _, tx, ty = self:canProject(tg, tx, ty)
		target = game.level.map(tx, ty, Map.ACTOR)
		if target == self then target = nil end

		-- Find space
		local x, y = util.findFreeGrid(tx, ty, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "Not enough space to summon!")
			return
		end
		
		local NPC = require "mod.class.NPC"
		local m = NPC.new{
			type = "construct", subtype = "sentry",
			display = "*", color=colors.BLUE,
			name = "Sonic Pulser", faction = self.faction, image = "object/tinkers_fatal_attractor_t5.png",
			autolevel = "none",
			ai = "summoned", ai_real = "tactical",
			level_range = {1, 1}, exp_worth = 0,
			body = { INVEN = 10, MAINHAND = 1, QUIVER = 1},
			power_source = {steam=true},

			max_life = self:steamCrit(t.getHP(self, t)),
			life_rating = 0,
			never_move = 1,

			combat_armor_hardiness = 100,
			combat_armor = t.getArmor(self, t),
			resists = {all = 35},

			negative_status_effect_immune = 1,
			cant_be_moved = 1,
			
			resolvers.talents{
				[self.T_STEAM_POOL]=1,
				[Talents.T_SHOCKWAVE_PULSE] = self:getTalentLevelRaw(self.T_SONIC_PULSER),
				
				[Talents.T_DOWNING_PULSE] = self:getTalentLevelRaw(self.T_MASTERFUL_CRAFTSMANSHIP),
				[Talents.T_REACTIVE_ARMOR] = self:getTalentLevelRaw(self.T_MASTERFUL_CRAFTSMANSHIP),
			},
			
			talents_types_mastery = {
				["steamtech/other"] = -1 + self:getTalentTypeMastery("steamtech/reinforcement"),
			},

			summoner = self, summoner_gain_exp=true,
			summon_time = 11,	-- The ability cast itself takes 1 turn.
		}
		

		m:resolve() m:resolve(nil, true)
		m:forceLevelup(self.level)
		game.zone:addEntity(game.level, m, "actor", x, y)
		return true
	end,
	info = function(self, t)
		return ([[Deploy a resilient sonic pulser up to 6 tiles away which lasts for 10 turns.
		The pulser has %d health and %d armor.
		
		Every other turn, the pulser emits sonic shockwaves affecting units in a 2-tile radius around itself.
		This shockwave disrupts enemies, placing all activatable (non-sustained, non-passive) talents on a 1-turn cooldown. Allies are unaffected.
		Health and armor scale with Steampower.]]):format(t.getHP(self, t), t.getArmor(self, t))
	end,
}

newTalent{
	-- Deploy a friendly turret which fires arcing bolts of lightning with a 25% chance to strip beneficial effects from hit targets.
	name = "Tesla Sentinel",
	type = {"steamtech/reinforcement", 3},
	require = steamreq3,
	points = 5,
	cooldown = 24,
	steam = 15,
	tactical = { BUFF=2 },
	getArmor = function(self, t) return self:combatTalentSteamDamage(t, 6, 65) end,
	getHP = function(self, t) return self:combatTalentSteamDamage(t, 8, 800) end,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 12, 150) end, -- For info.
	target = function(self, t) return {type="bolt", nowarning=true, radius=2, range=self:getTalentRange(t), nolock=true, simple_dir_request=true, talent=t} end, -- for the ai
	action = function(self, t)
		local tg = {type="bolt", nowarning=true, range=self:getTalentRange(t), nolock=true, simple_dir_request=true, talent=t}
		local tx, ty, target = self:getTarget(tg)
		if not tx or not ty then return nil end
		local _ _, _, _, tx, ty = self:canProject(tg, tx, ty)
		target = game.level.map(tx, ty, Map.ACTOR)
		if target == self then target = nil end

		-- Find space
		local x, y = util.findFreeGrid(tx, ty, 5, true, {[Map.ACTOR]=true})
		if not x then
			game.logPlayer(self, "Not enough space to summon!")
			return
		end
		
		local NPC = require "mod.class.NPC"
		local m = NPC.new{
			type = "construct", subtype = "sentry",
			display = "*", color=colors.BLUE,
			name = "Tesla Sentinel", faction = self.faction, image = "object/tinkers_voltaic_sentry_t5.png",
			autolevel = "none",
			ai = "summoned", ai_real = "tactical", ai_state = { talent_in=1, },
			level_range = {1, 1}, exp_worth = 0,
			body = { INVEN = 10, MAINHAND = 1, QUIVER = 1},
			power_source = {steam=true},

			max_life = self:steamCrit(t.getHP(self, t)),
			life_rating = 0,
			never_move = 1,
			
			combat_steampower = self:combatSteampower(),

			combat_armor_hardiness = 100,
			combat_armor = t.getArmor(self, t),
			resists = {all = 15},

			negative_status_effect_immune = 1,
			cant_be_moved = 1,
			
			resolvers.talents{
				[self.T_STEAM_POOL]=1,
				[Talents.T_VOLTAIC_CHAINBOLT] = self:getTalentLevelRaw(self.T_TESLA_SENTINEL),
				
				[Talents.T_LEVIN_CHAINBOLT] = self:getTalentLevelRaw(self.T_MASTERFUL_CRAFTSMANSHIP),
				[Talents.T_REACTIVE_ARMOR] = self:getTalentLevelRaw(self.T_MASTERFUL_CRAFTSMANSHIP),
			},

			talents_types_mastery = {
				["steamtech/other"] = -1 + self:getTalentTypeMastery("steamtech/reinforcement"),
			},
			
			summoner = self, summoner_gain_exp=true,
			summon_time = 11,	-- The ability cast itself takes 1 turn.
		}
		
		m.summoner_steampower = self:combatSteampower()
		m.combatSteampower = function(self) return self.summoner_steampower end
		
		m:resolve() m:resolve(nil, true)
		m:forceLevelup(self.level)
		game.zone:addEntity(game.level, m, "actor", x, y)
		return true
	end,
	info = function(self, t)
		return ([[Deploy a tesla sentinel next to you, lasting 10 turns.
		The sentinel has %d life and %d armor. It inherits your effective Steampower stat.
		
		Every turn, the sentinel fires piercing chain lightning, hitting up to 3 targets for up to %d lightning damage each.
		Each target may have one random beneficial effect stripped from it (25%% chance).
		#YELLOW#The bolt will never specifically target you, but you can be struck by the bolt's travel path.#WHITE#
		Health, armor, and damage scale with steampower.]]):format(t.getHP(self, t), t.getArmor(self, t), t.getDamage(self, t))
	end,
}

newTalent{
	-- Enhances all turrets.
	name = "Masterful Craftsmanship",
	type = {"steamtech/reinforcement", 4},
	points = 5,
	require = steamreq4,
	mode = "passive",
	getRetal = function(self, t) return self:combatTalentScale(t, 15, 35) end,	-- Not sure how to grab stats of a talent assigned to a different unit altogether, so just copying over these.
	getThreshold = function(self, t) return self:combatTalentLimit(t, 50, 95, 65), 1 end,
	getRadius = function(self, t)
		if self:getTalentLevel(t) >= 3 then
			return 5
		else
			return 4
		end
	end,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 20, 250) end,
	info = function(self, t)
		return ([[Your turrets are masterfully crafted, granting them additional talents.

		#YELLOW#Area Denial#WHITE# (Riot Turret): Fires weapon in a %d radius circle around itself, applying on-hit effects.
		#YELLOW#Downing Pulse#WHITE# (Sonic Pulser): Emits a shockwave that affects all units in a 2-tile radius: pins and stuns targets for 1 turn.
		#YELLOW#Levin Chainbolt#WHITE# (Tesla Sentinel): Fires a single-target lightning round which deals at most %d lightning damage and strips one beneficial effect from hit targets.
		#GREY#Reactive Armor#WHITE# (All): Turrets inflict %d physical damage against melee attackers and cannot take a blow that causes them to lose more than %d%% of their max life.
		
		Additional talent details can be viewed by inspecting the summoned unit.]]):
		format(t.getRadius(self, t), t.getDamage(self, t), t.getRetal(self, t), t.getThreshold(self, t))
	end,
}

-- TURRET TALENTS --

newTalent{
	name = "Rubber Rounds",
	type = {"steamtech/other",1},
	points = 5,
	mode = "passive",
	range = steamgun_range,
	requires_target = true,
	reflectable = true,
	callbackOnArcheryAttack = function(self, t, target, hitted, crit, weapon, ammo, damtype, mult, dam)
		mult = 0
		dam = dam * 0
		
		local effects = {target.EFF_STUNNED, target.EFF_PINNED, target.EFF_CONFUSED, target.EFF_CRIPPLE}
		while #effects > 0 do
			local effect = rng.tableRemove(effects)
			if not target:hasEffect(effect) then
				if effect == target.EFF_STUNNED then -- sun
					if target:canBe("stun") then
						target:setEffect(effect, 2, {apply_power=self:combatSteampower()})
					end
					return
				elseif effect == target.EFF_PINNED then	-- pin
					if target:canBe("pin") then
						target:setEffect(effect, 2, {apply_power=self:combatSteampower()})
					end
					return
				elseif effect == target.EFF_CONFUSED then
					if target:canBe("confused") then
						target:setEffect(effect, 2, {apply_power=self:combatSteampower(), power=25})
					end
					return
				elseif effect == target.EFF_CRIPPLE then -- cripple
					target:setEffect(effect, 2, {apply_power=self:combatSteampower(), speed=0.25})
					return
				end
			end
		end
	end,
	info = function(self, t)
		return ([[This unit fires rubber rounds, applying one of stun, pin, confuse (25% power), or cripple (25% power) for 2 turns if the target fails a physical save.
		The chance to apply effects increases with Steampower.]])
	end,
}

newTalent{
	name = "Shockwave Pulse",
	type = {"steamtech/other", 1},
	points = 5,
	range = 0,
	radius = 2,
	cooldown = 2,
	tactical = {ATTACKAREA = 2},
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire = false, friendlyfire = false, talent=t}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		self:project(tg, self.x, self.y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			
			local tids = {}
			for tid, lev in pairs(target.talents) do
				local t = target:getTalentFromId(tid)
				if t and not target.talents_cd[tid] and t.mode == "activated" and not t.innate then tids[#tids+1] = t end
			end
			
			while #tids > 0 do
				local t = rng.tableRemove(tids)
				if not t then break end
				target.talents_cd[t.id] = 2
			end
			
			-- Sanity check so that players don't see themselves as being disrupted in the log even when they're not.
			if target:reactionToward(self) < 0 then
				game.logSeen(target, "#LIGHT_BLUE#%s is disrupted by the pulse!", target.name:capitalize())
			end
			
		end)
		
		if core.shader.active(4) then
			game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_spike", {radius=tg.radius * 2, allow=core.shader.allow("distort")})
		end
		game:playSoundNear(self, "talents/earth")
		
		return true
	end,
	info = function(self, t)
		return ([[Thump the ground with immense force, emitting a radius-2 shockwave which places all activatable talents of hit targets on cooldown for 1 turn.]])
	end,
}

-- It's just chain lightning, but nerfed and now has a chance to apply negative status effects.
newTalent{
	name = "Voltaic Chainbolt",
	type = {"steamtech/other", 1},
	points = 5,
	range = 10,
	cooldown = 1,
	tactical = { ATTACKAREA = {LIGHTNING = 2} }, --note: only considers the primary target
	range = 10,
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	target = function(self, t) return {type="bolt", range=self:getTalentRange(t), talent=t} end,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 12, 150) end,
	getTargetCount = function(self, t) return 3 end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local fx, fy = self:getTarget(tg)
		if not fx or not fy then return nil end

		local nb = t.getTargetCount(self, t)
		local affected = {}
		local first = nil

		self:project(tg, fx, fy, function(dx, dy)
			print("[Chain lightning] targetting", fx, fy, "from", self.x, self.y)
			local actor = game.level.map(dx, dy, Map.ACTOR)
			if actor and not affected[actor] then
				affected[actor] = true
				first = actor

				print("[Chain lightning] looking for more targets", nb, " at ", dx, dy, "radius ", 10, "from", actor.name)
				self:project({type="ball", selffire=false, x=dx, y=dy, radius=10, range=0}, dx, dy, function(bx, by)
					local actor = game.level.map(bx, by, Map.ACTOR)
					if actor and not affected[actor] and self:reactionToward(actor) < 0 then
						print("[Chain lightning] found possible actor", actor.name, bx, by, "distance", core.fov.distance(dx, dy, bx, by))
						affected[actor] = true
					end
				end)
				return true
			end
		end)

		if not first then return end
		local targets = { first }
		affected[first] = nil
		local possible_targets = table.listify(affected)
		print("[Chain lightning] Found targets:", #possible_targets)
		for i = 2, nb do
			if #possible_targets == 0 then break end
			local act = rng.tableRemove(possible_targets)
			targets[#targets+1] = act[1]
		end

		local sx, sy = self.x, self.y
		for i, actor in ipairs(targets) do

			local tgr = {type="beam", range=self:getTalentRange(t), selffire=false, talent=t, x=sx, y=sy}
			print("[Chain lightning] jumping from", sx, sy, "to", actor.x, actor.y)
			local dam = self:spellCrit(t.getDamage(self, t))
			self:project(tgr, actor.x, actor.y, DamageType.LIGHTNING_DAZE, {dam=rng.avg(rng.avg(dam / 3, dam, 3), dam, 5), daze=self:attr("lightning_daze_tempest") or 0})
			if core.shader.active() then game.level.map:particleEmitter(sx, sy, math.max(math.abs(actor.x-sx), math.abs(actor.y-sy)), "lightning_beam", {tx=actor.x-sx, ty=actor.y-sy}, {type="lightning"})
			else game.level.map:particleEmitter(sx, sy, math.max(math.abs(actor.x-sx), math.abs(actor.y-sy)), "lightning_beam", {tx=actor.x-sx, ty=actor.y-sy})
			end

			sx, sy = actor.x, actor.y
			
			-- Dispel beneficial effects.
			local effs = {}
			for eff_id, p in pairs(actor.tmp) do
				local e = actor.tempeffect_def[eff_id]
				if e.type ~= "other" and e.status == "beneficial" then
					effs[#effs+1] = {"effect", eff_id}
				end
			end
			
			if #effs == 0 then --do nothing.
			else
				local eff = rng.tableRemove(effs)
				if rng.percent(25) then
					game.logSeen(actor, "#LIGHT_BLUE#%s has had a beneficial effect stripped!", actor.name:capitalize())
					actor:removeEffect(eff[2])
				end
			end
		end

		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local targets = t.getTargetCount(self, t)
		return ([[Fires a chaining bolt of electricity dealing up to %0.2f damage and forking to another target.
		It can hit up to %d additional targets up to 10 grids apart. Each hit target has a 25%% chance to have a random beneficial effect removed.
		Damage increases with Steampower.]]):
		format(t.getDamage(self, t), targets)
	end,
}

-- MASTERFUL CRAFTSMANSHIP TALENTS--

newTalent{
	-- Melee retaliation + max damage caps.
	name = "Reactive Armor",
	type = {"steamtech/other", 1},
	points = 5,
	require = steamreq4,
	mode = "passive",
	getRetal = function(self, t) return self:combatTalentScale(t, 15, 35) end,
	getThreshold = function(self, t) return self:combatTalentLimit(t, 50, 95, 65), 1 end,
	passives = function(self, t, p)
		self:talentTemporaryValue(p, "on_melee_hit", {[DamageType.PHYSICAL]=t.getRetal(self, t)})
		self:talentTemporaryValue(p, "flat_damage_cap", {all = t.getThreshold(self, t)})
	end,
	info = function(self, t)
		return ([[This unit is outfitted in reactive kinetic plating. It can no longer take a blow that deals more than %d%% of its maximum life.
		Also, melee attackers take %d physical retaliation damage.]]):format(t.getThreshold(self, t), t.getRetal(self, t))
	end,
}

newTalent{
	-- AoE shot.
	name = "Area Denial",
	type = {"steamtech/other", 1},
	points = 5,
	random_ego = "attack",
	cooldown = 4,
	range = 0,
	radius = function(self, t) if self:getTalentLevel(t) >= 3 then return 5 else return 4 end end,
	tactical = { ATTACKAREA = { weapon = 4 }},
	requires_target = true,
	target = function(self, t)
		local weapon, ammo = self:hasArcheryWeapon()
		return {type = "ball", range = self:getTalentRange(t), radius = self:getTalentRadius(t), selffire = false, friendlyfire = false, talent = t }
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y, target = self:getTarget(tg)
		if not x or not y then return nil end
		local _ _, x, y = self:canProject(tg, x, y)
		
		local target = game.level.map(x, y, game.level.map.ACTOR)
		
		if not target then return end
		local targets = self:archeryAcquireTargets(tg, {x=target.x, y=target.y, no_energy=true, infinite=true, type="steamgun"})
		
		if not targets then return nil end
		self:archeryShoot(targets, t, {type = "hit", speed = 200, primaryeffect=tg.radius, primarytarget=target})
		
		return true
	end,
	info = function(self, t)
		return ([[Fire in a radius-%d circle around this unit, applying all on-hit effects. Does not target allies.]]):format(self:getTalentRadius(t))
	end,
}

newTalent{
	-- AoE stun and pin. Pretty good in case you didn't know.
	name = "Downing Pulse",
	type = {"steamtech/other", 1},
	points = 5,
	range = 0,
	radius = 2,
	cooldown = 2,
	tactical = {ATTACKAREA = 6},
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire = false, friendlyfire = false, talent=t}
	end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		self:project(tg, self.x, self.y, function(px, py)
			local target = game.level.map(px, py, Map.ACTOR)
			if not target then return end
			
			-- T-Engine4 is weird with one-duration negative effects so this workaround'll have to do.
			if target:canBe("stun") then
				target:setEffect(target.EFF_STUNNED, 1, {})
				local eff = target:hasEffect(target.EFF_STUNNED)
				if eff then	-- Sanity check.
					eff.dur = 1
				end
			end
			if target:canBe("pin") then
				target:setEffect(target.EFF_PINNED, 1, {})
				local eff = target:hasEffect(target.EFF_PINNED)
				if eff then	-- Sanity check.
					eff.dur = 1
				end
			end
			
		end)
		
		if core.shader.active(4) then
			game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_spike", {radius=tg.radius * 2, allow=core.shader.allow("distort")})
		end
		game:playSoundNear(self, "talents/earth")
		
		return true
	end,
	info = function(self, t)
		return ([[Thump the ground with immense force, emitting a radius-2 shockwave which stuns and pins hit targets for 1 turn.]])
	end,
}

newTalent{
	name = "Levin Chainbolt",
	type = {"steamtech/other", 1},
	points = 5,
	random_ego = "attack",
	cooldown = 4,
	tactical = { ATTACK = {LIGHTNING = 2} },
	range = 10,
	direct_hit = true,
	reflectable = true,
	requires_target = true,
	target = function(self, t)
		return {type="beam", range=self:getTalentRange(t), talent=t}
	end,
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 20, 250) end,
	action = function(self, t)
		local tg = self:getTalentTarget(t)
		local x, y = self:getTarget(tg)
		if not x or not y then return nil end
		local dam = self:steamCrit(t.getDamage(self, t))
		self:project(tg, x, y, DamageType.LIGHTNING_DAZE, {dam=rng.avg(rng.avg(dam / 3, dam, 3), dam, 5), daze=self:attr("lightning_daze_tempest") or 0})
		local _ _, x, y = self:canProject(tg, x, y)
		
		local target = game.level.map(x, y, Map.ACTOR)
		if not target then return end
		
		local effs = {}
		for eff_id, p in pairs(target.tmp) do
			local e = target.tempeffect_def[eff_id]
			if e.type ~= "other" and e.status == "beneficial" then
				effs[#effs+1] = {"effect", eff_id}
			end
		end
			
		if #effs == 0 then --do nothing.
		else
			local eff = rng.tableRemove(effs)
			target:removeEffect(eff[2])
			game.logSeen(target, "#LIGHT_BLUE#%s has had a beneficial effect stripped!", target.name:capitalize())
		end
		
		if core.shader.active() then game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "lightning_beam", {tx=x-self.x, ty=y-self.y}, {type="lightning"})
		else game.level.map:particleEmitter(self.x, self.y, math.max(math.abs(x-self.x), math.abs(y-self.y)), "lightning_beam", {tx=x-self.x, ty=y-self.y})
		end
		game:playSoundNear(self, "talents/lightning")
		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		return ([[Fires a piercing beam of lightning.
		Levin Chainbolt does not chain but deals up to %0.2f damage and is guaranteed to remove a random beneficial effect from hit targets (when applicable).
		Damage increases with Steampower.]]):
		format(damage)
	end,
}