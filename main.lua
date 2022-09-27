--LIBS
local LootTracker = LibStub("AceAddon-3.0"):NewAddon("Loot Tracker", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local ScrollingTable = LibStub("ScrollingTable")

local LT_Lootframe

--FUNCTIONS
local function removeUTF8(str)
	--REPLACE UTF8 BULLSHIT
	str = str:gsub("á","a")
	str = str:gsub("à","a")
	str = str:gsub("â","a")
	str = str:gsub("ä","a")
	str = str:gsub("å","a")
	str = str:gsub("ã","a")
	str = str:gsub("æ","a")
	str = str:gsub("ç","c")
	str = str:gsub("é","e")
	str = str:gsub("è","e")
	str = str:gsub("ê","e")
	str = str:gsub("ë","e")
	str = str:gsub("í","i")
	str = str:gsub("ì","i")
	str = str:gsub("î","i")
	str = str:gsub("ï","i")
	str = str:gsub("ñ","n")
	str = str:gsub("ó","o")
	str = str:gsub("ò","o")
	str = str:gsub("ô","o")
	str = str:gsub("ö","o")
	str = str:gsub("õ","o")
	str = str:gsub("ø","o")
	str = str:gsub("œ","oe")
	str = str:gsub("š","s")
	str = str:gsub("ú","u")
	str = str:gsub("ù","u")
	str = str:gsub("û","u")
	str = str:gsub("ü","u")
	str = str:gsub("ý","y")
	str = str:gsub("ÿ","y")
	str = str:gsub("ž","z")
	str = str:gsub("'"," ")
	--END REPLACE UTF8 BULLSHIT
	
	return str
end

local function in_array(arr, str)
	for k in pairs(arr) do
		if k == str then return true end
	end
	return false
end

local function split(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

local function searchArrInStr(str, arr)
	if str == nil then return false end
	str = string.lower(str)
	
	for k in ipairs(arr) do
		arr[k] = string.lower(removeUTF8(arr[k]))
		
		if string.match(string.lower(str), string.lower(arr[k])) then
			return arr[k]
		end
	end
	return false
end

local function getInfoFromStrLoot(str)
	local arg2 = str

	local patternPlayerName = "^%a*"
	local playerName = string.match(arg2, patternPlayerName) -- foo

	local itemLink, itemName = string.match(arg2, "|H(.*)|h%[(.*)%]|h")
	
	local patternNumberLoot = "x(%d*)%." -- digit
	local numberLoot = string.match(arg2, patternNumberLoot)
	if numberLoot == nil then numberLoot = 1 end

	return playerName, itemName, itemLink, numberLoot
end

local function stringify(arr)
	local str = ""
	for k in pairs(arr) do
		for kk in pairs(arr[k]) do
			if str == "" then 
				str = k.." -> "..kk.." = "..arr[k][kk]
			else 
				str = str.."\r\n"..k.." -> "..kk.." = "..arr[k][kk] 
			end
		end
	end
	return str
end
--FUNCTIONS

--INIT VAR
local defaults = {
    profile = {
		active = false,
		terms = "",
		result = {},
        qDebug = false,
		alertScreen = false,
		alertChat = false,
    },
	char = {
		result = {}
	}
}

local options = {
    name = "Loot Tracker",
    handler = LootTracker,
    type = 'group',
    args = {
		active = {
			order = 1,
			type = "toggle",
			name = "Active",
			get = "IsActive",
			set = "ToggleActive",
		},
		labelTermsList = {
			order = 2,
			type = "description",
			name = "Search terms list separated by comma ',' without blank (if no terms are saved, all loot will be matched and saved) :",
		},
		termsList = {
			order = 3,
			type = "input",
			multiline = true,
			width = "full",
			name = "",
			desc = "",
			--usage = "<Your message here>",
			get = "GetTerms",
			set = "SetTerms",
		},
		labelResult = {
			order = 4,
			type = "description",
			name = "Search result list :",
		},
		searchResultList = {
			order = 5,
			type = "input",
			multiline = true,
			width = "full",
			name = "",
			get = "GetResult",
		},
		buttonResultReset = {
			order = 6,
			type = "execute",
			name = "Result reset",
			func = "resetResultList"
		},
		alertScreen = {
			order = 7,
			type = "toggle",
			name = "Alert on screen",
			get = "IsAlertScreen",
			set = "ToggleAlertScreen",
		},
		alertChat = {
			order = 8,
			type = "toggle",
			name = "Alert in chat",
			get = "IsAlertChat",
			set = "ToggleAlertChat",
		},
		qDebug = {
			order = 9,
			type = "toggle",
			name = "Debug",
			get = "IsDebug",
			set = "ToggleDebug",
		},
		showLootFrame = {
			order = 10,
			type = "execute",
			name = "Show loot log",
			func = "ToggleLootFrame"
		},
    },
}
--INIT VAR

function LootTracker:Debug(strName, tData) 
    if ViragDevTool_AddData and self.db.profile.qDebug then 
        ViragDevTool_AddData(tData, strName) 
	end
end

function LootTracker:OnInitialize()
    -- Called when the addon is loaded
	self.db = LibStub("AceDB-3.0"):New("LootTrackerDB", defaults, true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("LootTracker", options, {"loottracker", "lt"})
	self.optionsFrame = LibStub ("AceConfigDialog-3.0"): AddToBlizOptions ("LootTracker", "LootTracker") 

	self:RegisterChatCommand("lt", "ChatCommand") 
    self:RegisterChatCommand("loottracker", "ChatCommand") 

	self:Print("LootTracker initialized")
end

function LootTracker:OnEnable()
	self:Debug("OnEnable", "LootTracker")

    -- Called when the addon is enabled
	self:RegisterEvent("CHAT_MSG_LOOT")

	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Loot Frame")
	frame:SetStatusText("AceGUI-3.0 Example Container Frame")
	--frame:SetCallback("OnClose", function(widget) 
	--	self:Debug("Releasing widget")
	--	AceGUI:Release(widget) 
	--end)
	frame:SetLayout("Flow")
	frame:Hide()

	local t_data = self:convertTable()
	local t_options = {
		{["name"] = "Name", ["width"] = 50, ["align"] = "LEFT",},
		{["name"] = "Item", ["width"] = 200, ["align"] = "LEFT"},
		{["name"] = "Quantity", ["width"] = 50, ["align"] = "MIDDLE"}
	}

	local table = ScrollingTable:CreateST(t_options, 30, 10, nil, frame.content.obj.frame)
	table:SetData(t_data, true)
	--table:SortData()
	--table:Hide()

	self.lootFrame = frame
	self.lootTable = table
end

function LootTracker:OnDisable()
    -- Called when the addon is disabled
end

--[[ 
{
	PlayerName
		itemLink, itemName, itemQuantity
		itemLink
}
--]]
function LootTracker:CHAT_MSG_LOOT(arg1,arg2,_,_,_,arg6)
	if self.db.profile.active == false then return end
	self:Debug(arg2, "LootTracker: CHAT_MSG_LOOT event")

	local playerName, lootName, lootLink, numberLoot = getInfoFromStrLoot(arg2)
    self:Debug(arg2 .. " => " .. playerName .. "/" .. lootName .. "/" .. lootLink .. "/" .. numberLoot, "LootTracker: GetInfoFromStrLoot")

	local arrTerms = split(self.db.profile.terms, ",")

	-- Creating item object and async feedback
	self:Debug(lootLink, "LootTracker: Calling CreateFromItemLink")
	local item = Item:CreateFromItemLink(lootLink)

	item:ContinueOnItemLoad(function()
		self:Debug(item, "LootTracker: Async ContinueOnItemLoad called")

		local db = self.db.profile.result

		local name = item:GetItemName()
		local icon = item:GetItemIcon()
		local quality = item:GetItemQuality()


		if quality and quality < 1 then
			self:Debug("Skipping loot by rarity", "LootTracker: Rarity check")
		else
			-- Change data structure for ID
			-- how to get user ID safely ?
			-- Check if loot is in whitelist
			if searchArrInStr(lootName, arrTerms) or #arrTerms == 0 then
				if in_array(self.db.profile.result, playerName) then
					if in_array(self.db.profile.result[playerName], lootName) then
						self:Debug("update playerName : "..playerName, "LootTracker: Update player")
						local total = numberLoot + self.db.profile.result[playerName][lootName]
						self:Debug("update lootName : " .. self.db.profile.result[playerName][lootName] .. " + " .. numberLoot .. " = " .. total, "LootTracker: Update player")
						self.db.profile.result[playerName][lootName] = total
					else
						self:Debug("update numberLoot : " .. numberLoot, "LootTracker: Update player")
						self.db.profile.result[playerName][lootName] = numberLoot
					end
				else
					self:Debug("insert playerName : " .. playerName, "LootTracker: New player")
					self.db.profile.result[playerName] = {}
					self:Debug("insert lootName : " .. lootName, "LootTracker: New player")
					self:Debug("insert numberLoot : " .. numberLoot, "LootTracker: New player")
					self.db.profile.result[playerName][lootName] = numberLoot
				end
				
				if self.db.profile.alertChat then
					self:Debug(playerName.." -> "..lootName.." + "..numberLoot)
				end
		
				if self.db.profile.alertScreen then
					UIErrorsFrame:AddMessage(playerName.." -> "..lootName.." + "..numberLoot, 1.0, 1.0, 1.0, 5.0)
				end
			else
				self:Debug("LOOT DON'T MATCH WITH TERMS SAVED", "LootTracker")
			end
		end
	end)

end

function LootTracker:convertTable()
	local t = {}
	local arr = self.db.profile.result

	for k in pairs(arr) do
		for kk in pairs(arr[k]) do
			table.insert(t, {k, kk, arr[k][kk]})
		end
	end

	return t
end

function LootTracker:refreshLootFrame()
	self:Debug("refreshLootFrame")
	local f = self.lootFrame
	f:ReleaseChildren()
	local arr = self.db.profile.result

	for k in pairs(arr) do
		for kk in pairs(arr[k]) do
			self:Debug("Creating label for "..k.." and "..kk)
			local _line = AceGUI:Create("Label")
			_line:SetText(k.." -> "..kk.." = "..arr[k][kk] )
			_line:SetFullWidth(true)
			f:AddChild(_line)
		end
	end
	f:SetStatusText("Refreshed done")
	f:DoLayout()

end

function LootTracker:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("lt", "LootTracker", input)
    end
end

function LootTracker:IsActive(info)
    return self.db.profile.active
end

function LootTracker:ToggleActive(info, value)
    self.db.profile.active = value
end

function LootTracker:IsDebug(info)
    return self.db.profile.qDebug
end

function LootTracker:ToggleDebug(info, value)
    self.db.profile.qDebug = value
end

function LootTracker:IsAlertScreen(info)
    return self.db.profile.alertScreen
end

function LootTracker:ToggleAlertScreen(info, value)
    self.db.profile.alertScreen = value
end

function LootTracker:IsAlertChat(info)
    return self.db.profile.alertChat
end

function LootTracker:ToggleAlertChat(info, value)
    self.db.profile.alertChat = value
end

function LootTracker:GetTerms(info)
	self:Debug("Returns "..self.db.profile.terms, "GetTerms called")
	return self.db.profile.terms
end

function LootTracker:SetTerms(info, newValue)
	self:Debug(newValue, "SetTerms called")
	self.db.profile.terms = newValue
end

function LootTracker:resetResultList(info)
	self.db.profile.result = {}
end

function LootTracker:GetResult(info)
	self:Debug(info, "GetResult called")
	return stringify(self.db.profile.result)
end

function LootTracker:ToggleLootFrame()
	local frame = self.lootFrame

    if (not frame:IsShown()) then
		self:refreshLootFrame()
    	frame:Show()
    else
    	frame:Hide()
    end
end