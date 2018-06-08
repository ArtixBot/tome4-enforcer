-- Thanks DarkGod and minqmay for serving as a reference guide for this dialog.

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local TreeList = require "engine.ui.TreeList"
local ListColumns = require "engine.ui.ListColumns"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"

module(..., package.seeall, class.inherit(Dialog))

-- generate talent status separately to enable quicker refresh of Dialog
local function TalentStatus(who,t) 
	local status = tstring{{"color", "LIGHT_GREEN"}, "Active"} 

	return tostring(status) 
end

function _M:init(actor)
	self.actor = actor
	actor.hotkey = actor.hotkey or {}
	Dialog.init(self, "Hair Trigger", game.w * 0.6, game.h * 0.8)

	local vsep = Separator.new{dir="horizontal", size=self.ih - 10}
	self.c_tut = Textzone.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=1, auto_height=true, no_color_bleed=true, text=[[
Select a grenade talent. Every time you fire your steamgun the selected talent has a chance to trigger at the same location.
]]}
	self.c_desc = TextzoneList.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=self.ih - self.c_tut.h - 20, scrollbar=true, no_color_bleed=true}
	self:generateList()

	local cols = {
		{name="", width={40,"fixed"}, display_prop="char"},
		{name="Talent", width=80, display_prop="name"},
	}
	self.c_list = TreeList.new{width=math.floor(self.iw / 2 - vsep.w / 2), height=self.ih - 10, all_clicks=true, scrollbar=true, columns=cols, tree=self.list, fct=function(item, sel, button) self:use(item, button) end, select=function(item, sel) self:select(item) end}
	self.c_list.cur_col = 2

	self:loadUI{
		{left=0, top=0, ui=self.c_list},
		{right=0, top=self.c_tut.h + 20, ui=self.c_desc},
		{right=0, top=0, ui=self.c_tut},
		{hcenter=0, top=5, ui=vsep},
	}
	self:setFocus(self.c_list)
	self:setupUI()

	self.key:addCommands{
		__TEXTINPUT = function(c)
			if c == '~' then
				self:use(self.cur_item)
			end
			if self.list and self.list.chars[c] then
				self:use(self.list.chars[c])
			end
		end,
	}
	engine.interface.PlayerHotkeys:bindAllHotkeys(self.key, function(i) self:defineHotkey(i) end)
	self.key:addBinds{
		EXIT = function() game:unregisterDialog(self) end,
	}
end

function _M:on_register()
	game:onTickEnd(function() self.key:unicodeInput(true) end)
end

function _M:select(item)
	if item then
		self.c_desc:switchItem(item, item.desc)
		self.cur_item = item
	end
end

function _M:use(item)
	if not item or not item.talent then return end
	self.actor:talentDialogReturn(item.talent)
	game:unregisterDialog(self)
end

-- Display the player tile
function _M:innerDisplay(x, y, nb_keyframes)
	if self.cur_item and self.cur_item.entity then
		self.cur_item.entity:toScreen(game.uiset.hotkeys_display_icons.tiles, x + self.iw - 64, y + self.iy + self.c_tut.h - 32 + 10, 64, 64)
	end
end

function _M:generateList()
	-- Makes up the list
	local list = {}
	local letter = 1

	local talents = {}
	local chars = {}

	-- Generate lists of all talents by category
	for j, t in pairs(self.actor.talents_def) do
		if self.actor:knowTalent(t.id) and t.mode == "activated" and (t.id == "T_GRENADE_FLASHBANG" or t.id == "T_GRENADE_CHEMICAL_GAS" or t.id == "T_GRENADE_SHRAPNEL") then
			local nodes = talents
			local status = tstring{{"color", "LIGHT_GREEN"}, "Talents"}
			
			-- Pregenerate icon with the Tiles instance that allows images
			if t.display_entity then t.display_entity:getMapObjects(game.uiset.hotkeys_display_icons.tiles, {}, 1) end

			nodes[#nodes+1] = {
				name=((t.display_entity and t.display_entity:getDisplayString() or "")..t.name):toTString(),
				cname=t.name,
				status=status,
				entity=t.display_entity,
				talent=t.id,
				desc=self.actor:getTalentFullDescription(t),
				color=function() return {0xFF, 0xFF, 0xFF} end
			}
		end
	end
	table.sort(talents, function(a,b) return a.cname < b.cname end)
	for i, node in ipairs(talents) do node.char = self:makeKeyChar(letter) chars[node.char] = node letter = letter + 1 end

	list = {
		{ char='', name=('#{bold}#Grenade Talents#{normal}#'):toTString(), status='', hotkey='', desc="All talents that can be used with Hair Trigger. #{bold}#Chemical Gas is not recommended.#{normal}#", color=function() return colors.simple(colors.LIGHT_GREEN) end, nodes=talents, shown=true },
		chars = chars,
	}
	self.list = list
end
