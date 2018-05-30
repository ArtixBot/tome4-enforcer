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
	getPwr = function(self, t) return self:combatTalentSteamDamage(t, 8, 300) + 10 end,
	getHP = function(self, t) return self:combatTalentSteamDamage(t, 10, 1000) end,
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
			name = "Riot Turret", faction = self.faction, image = "object/mechanical_core.png",
			autolevel = "none",
			ai = "summoned", ai_real = "dumb_talented", ai_state = { talent_in=1, },
			level_range = {1, 1}, exp_worth = 0,
			body = { INVEN = 10, MAINHAND = 1, QUIVER = 1},
			power_source = {steam=true},

			max_life = self:steamCrit(t.getHP(self, t)),
			life_rating = 0,
			never_move = 1,

			combat_atk = 300,	-- Diminishing returns means 300 raw accuracy is needed for 100 effective accuracy.
			combat_steampower = t.getPwr(self, t),

			combat_armor_hardiness = 100,
			combat_armor = t.getArmor(self, t),
			resists = {all = 25},
			inc_damage = {all = -500},

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
			},
			
			
			resolvers.equip{
				{type="weapon", subtype="steamgun", name="iron steamgun", base_list="mod.class.Object:/data-orcs/general/objects/steamgun.lua", autoreq=true, ego_chance=-1000},
				{type="ammo", subtype="shot", autoreq=true, forbid_power_source={arcane=true}, not_properties = {"unique"}, ego_chance=-1000 },
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
		return ([[Deploy a riot turret adjacent to you, lasting 10 turns.
		The turret has %d health, %d armor, %d raw Steampower, and 100 effective Accuracy.
		#{italic}#If you have invested points into the Suppression tree then the Riot Turret gains those talents as well.#{normal}#
		
		Every turn it fires pain-maximizing rubber rounds. #YELLOW#Beware of friendly fire!#WHITE#
		These deal no damage, but targets which fail a physical save are inflicted with a 2-turn random detrimental physical effect: stun, pin, confuse, or cripple.
		The turret's health, armor, Steampower, and debuff chance increases with your Steampower.]]):format(t.getHP(self, t), t.getArmor(self, t), t.getPwr(self, t))
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
			ai = "summoned", ai_real = "dumb_talented", ai_state = { talent_in=1, },
			level_range = {1, 1}, exp_worth = 0,
			body = { INVEN = 10, MAINHAND = 1, QUIVER = 1},
			power_source = {steam=true},

			max_life = self:steamCrit(t.getHP(self, t)),
			life_rating = 0,
			never_move = 1,

			combat_armor_hardiness = 100,
			combat_armor = t.getArmor(self, t),
			resists = {all = 35},
			inc_damage = {all = -500},

			negative_status_effect_immune = 1,
			cant_be_moved = 1,
			
			resolvers.talents{
				[self.T_STEAM_POOL]=1,
				[Talents.T_SHOCKWAVE_PULSE] = self:getTalentLevelRaw(self.T_SONIC_PULSER),
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
		
		Every other turn, the pulser emits sonic shockwaves affecting units in a 2-tile radius around itself. #YELLOW#Beware of friendly fire!#WHITE#
		This shockwave disrupts hit targets, placing all activatable (non-sustained, non-passive) talents on a 1-turn cooldown.
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
			name = "Tesla Sentinel", faction = self.faction, image = "object/tinkers_voltaic_sentry_t5.png",
			autolevel = "none",
			ai = "summoned", ai_real = "dumb_talented", ai_state = { talent_in=1, },
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
				[Talents.T_VOLTAIC_BOLT] = self:getTalentLevelRaw(self.T_TESLA_SENTINEL),
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
		return ([[Deploy a tesla sentinel next to you, lasting 10 turns.
		The sentinel has XX life, XX armor, and XX steampower.
		
		Every turn, the sentinel fires piercing chain lightning, hitting up to 3 targets for XX lightning damage each.
		#YELLOW#The bolt will never target you, but you can be struck by the bolt's travel path. Watch where you stand!#WHITE#
		There is a 25%% chance that a hit target will have XX beneficial effect(s) stripped from it.
		Health, armor, and damage scale with steampower.]])
	end,
}

newTalent{
	-- Enhances all turrets.
	name = "Masterful Craftsmanship",
	type = {"steamtech/reinforcement", 4},
	points = 5,
	require = steamreq4,
	mode = "passive",
	info = function(self, t)
		return ([[Your turrets are crafted by a true master, granting them additional talents.

		#YELLOW#Area Denial#WHITE# (Riot Turret): Fires weapon in a 6-radius cone, applying on-hit effects.
		
		#YELLOW#Downing Shockwave#WHITE# (Sonic Pulser): Emits a shockwave that affects all units in a 2-tile radius: pins and stuns targets for 1 turn.
		
		#YELLOW#Charged Bolt#WHITE# (Tesla Sentinel): Fires a single-target lightning round which deals XX lightning damage and strips XX beneficial effect(s) from the target.
		
		#YELLOW#Reactive Armor#WHITE# (All): Grants melee retaliation damage and prevents turrets from losing more than a certain percent of life in one attack.]])
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
		dam = 0
		
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
		return ([[This unit fires non-damaging rubber rounds, applying one of stun, pin, confuse (25% power), or cripple (25% power) for 2 turns if the target fails a physical save.
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
	target = function(self, t)
		return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false, talent=t}
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
			game.logSeen(target, "#LIGHT_BLUE#%s is disrupted by the pulse!", target.name:capitalize())
		end)
		
		if core.shader.active(4) then
			game.level.map:particleEmitter(self.x, self.y, tg.radius, "gravity_spike", {radius=tg.radius * 2, allow=core.shader.allow("distort")})
		end
		game:playSoundNear(self, "talents/earth")
	end,
	info = function(self, t)
		return ([[Thump the ground with immense force, emitting a radius-2 shockwave which places all activatable talents of hit targets on cooldown for 1 turn.]])
	end,
}

-- It's just chain lightning, but nerfed and now has a chance to apply negative status effects.
newTalent{
	name = "Voltaic Bolt",
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
	getDamage = function(self, t) return self:combatTalentSteamDamage(t, 10, 125) end,
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
		end

		game:playSoundNear(self, "talents/lightning")

		return true
	end,
	info = function(self, t)
		local damage = t.getDamage(self, t)
		local targets = t.getTargetCount(self, t)
		return ([[Invokes a forking beam of lightning doing %0.2f to %0.2f damage and forking to another target.
		It can hit up to %d targets up to 10 grids apart, and will never hit the same one twice; nor will it hit the caster.
		The damage will increase with your Steampower.]]):
		format(damDesc(self, DamageType.LIGHTNING, damage / 3),
			damDesc(self, DamageType.LIGHTNING, damage),
			targets)
	end,
}

-- MASTERFUL CRAFTSMANSHIP TALENTS--
newTalent{
	-- Enhances all turrets.
	name = "Reactive Armor",
	type = {"steamtech/other", 1},
	points = 5,
	require = steamreq4,
	mode = "passive",
	info = function(self, t)
		return ([[This unit is outfitted in reactive kinetic plating. It can no longer take a blow that deals more than XX of its maximum life.
		Also, melee attackers take XX physical retaliation damage.]])
	end,
}