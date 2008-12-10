--
-- Broker_Currency
-- Copyright 2008+ Toadkiller of Proudmoore for the non-statistics code.
-- The statistics code is 100% ckknight
--
-- LDB display of currencies, totals and money rate for all characters on a server.
-- The statistics stuff (total money today, yesterday, last week) is 100% from FuBar_MoneyFu, credit to ckknight
-- http://www.wowace.com/projects/broker-currency/
--

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

-- The localization goal is to only use existing Blizzard strings and localized Title strings from the toc
local iconGold = GOLD_AMOUNT_TEXTURE
local iconSilver = SILVER_AMOUNT_TEXTURE
local iconCopper = COPPER_AMOUNT_TEXTURE

local settingGold = "\124TInterface\\MoneyFrame\\UI-GoldIcon:32:32:2:0\124t"
local settingSilver = "\124TInterface\\MoneyFrame\\UI-SilverIcon:32:32:2:0\124t"
local settingCopper = "\124TInterface\\MoneyFrame\\UI-CopperIcon:32:32:2:0\124t"

local SETTING_ICON_STRING = "\124T%s:32:32:2:0\124t"
local DISPLAY_ICON_STRING1 = "%d\124T"
local DISPLAY_ICON_STRING2 = ":%d:%d:2:0\124t"

local currencyInfo = {
	{},
	{},
	{},
	{itemId = 43307, countFunc = GetHonorCurrency},
	{itemId = 43308, countFunc = GetArenaCurrency},
	{itemId = 40753, countFunc = GetItemCount},
	{itemId = 40752, countFunc = GetItemCount},
	{itemId = 29434, countFunc = GetItemCount},

	{itemId = 20560, countFunc = GetItemCount},
	{itemId = 20559, countFunc = GetItemCount},
	{itemId = 29024, countFunc = GetItemCount},
	{itemId = 42425, countFunc = GetItemCount},
	{itemId = 20558, countFunc = GetItemCount},
	{itemId = 43589, countFunc = GetItemCount},

	{itemId = 43228, countFunc = GetItemCount},
	{itemId = 43016, countFunc = GetItemCount},
	{itemId = 41596, countFunc = GetItemCount},
	{itemId = 43228, countFunc = GetItemCount},
	{itemId = 37836, countFunc = GetItemCount},
}
do
	for index, tokenInfo in pairs(currencyInfo) do
		local itemId = tokenInfo.itemId
		if (itemId) then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(itemId)
			if (itemTexture) then
				tokenInfo.itemName = itemName
				tokenInfo.settingIcon = "\124T" .. itemTexture .. ":32:32:2:0\124t"
				tokenInfo.brokerIcon = DISPLAY_ICON_STRING1 .. itemTexture .. DISPLAY_ICON_STRING2
			end
		end
	end
end
local settingsSliderIcon = currencyInfo[4].brokerIcon

local playerName = UnitName("player")
local realmName = GetRealmName()

local sCurrency = CURRENCY
local sVersion = GetAddOnMetadata("Broker_Currency", "Version")

local sDisplay = DISPLAY
local sSummary = ACHIEVEMENT_SUMMARY_CATEGORY

local sStatistics = STATISTICS
local sSession = playerName
local sToday = HONOR_TODAY
local sYesterday = HONOR_YESTERDAY
local sThisWeek = ARENA_THIS_WEEK
local sLastWeek = HONOR_LASTWEEK

local sPlus = "+"
local sMinus = "-"
local sTotal = "="

local playerName = UnitName("player")
local realmName = GetRealmName()


Broker_Currency = CreateFrame("frame", "Broker_CurrencyFrame")


local function getValue(info)
	return Broker_CurrencyCharDB[info[# info]]
end

local function setValue(info, value)
	Broker_CurrencyCharDB[info[# info]] = true and value or nil
	Broker_Currency:Update()
end

local function setIconSize(info, value)
	Broker_CurrencyCharDB[info[# info]] = true and value or nil
	local iconSize = Broker_CurrencyCharDB.iconSize
	Broker_Currency.options.args.iconSize.name = string.format(settingsSliderIcon, 8, iconSize, iconSize)
	Broker_Currency:Update()
end

local function setIconSizeGold(info, value)
	Broker_CurrencyCharDB[info[# info]] = true and value or nil
	local iconSize = Broker_CurrencyCharDB.iconSizeGold
	Broker_Currency.options.args.iconSizeGold.name = string.format(iconGold, 8, iconSize, iconSize)
	Broker_Currency:Update()
end

-- Data is saved per realm/character in Broker_CurrencyDB
-- Options are saved per character in Broker_CurrencyCharDB
-- There is separate settings for display of the broker, and the summary display on the tooltip
local name, title, sNotes, enabled, loadable, reason, security = GetAddOnInfo("Broker_Currency")
Broker_Currency.options = {
	type = "group",
	get = getValue,
	set = setValue,
	args = {
		header1 = {
			type = "description",
			order = 5,
			name = sVersion,
			cmdHidden = true
		},
		header2 = {
			type = "description",
			order = 10,
			name = sNotes,
			cmdHidden = true
		},
		iconSize = {
			type = "range",
			order = 10,
			name = string.format(settingsSliderIcon, 8, 16, 16),
			min = 1, max = 32, step = 1, bigStep = 1,
			set = setIconSize,
		},
		iconSizeGold = {
			type = "range",
			order = 10,
			name = string.format(iconGold, 8, 16, 16),
			min = 1, max = 32, step = 1, bigStep = 1,
			set = setIconSizeGold,
		},
		brokerDisplay = {
			type = "group",
			name = sDisplay,
			order = 20,
			inline = true,
			childGroups = "tree",
			args = {
				showGold = {
					type = "toggle",
					name = settingGold,
					order = 1,
					width = "half",
				},
				showSilver = {
					type = "toggle",
					name = settingSilver,
					order = 1,
					width = "half",
				},
				showCopper = {
					type = "toggle",
					name = settingCopper,
					order = 2,
					width = "half",
				},
			},
		},
		statisticsDisplay = {
			type = "group",
			name = sStatistics,
			order = 30,
			inline = true,
			childGroups = "tree",
			args = {
				summaryPlayerSession = {
					type = "toggle",
					name = sSession,
					order = 1,
					width = "full",
				},
				summaryRealmToday = {
					type = "toggle",
					name = sToday,
					order = 2,
					width = "full",
				},
				summaryRealmYesterday = {
					type = "toggle",
					name = sYesterday,
					order = 3,
					width = "full",
				},
				summaryRealmThisWeek = {
					type = "toggle",
					name = sThisWeek,
					order = 4,
					width = "full",
				},
				summaryRealmLastWeek = {
					type = "toggle",
					name = sLastWeek,
					order = 5,
					width = "full",
				},
			},
		},
		summaryDisplay = {
			type = "group",
			name = sSummary,
			order = 40,
			inline = true,
			childGroups = "tree",
			args = {
				summarySilver = {
					type = "toggle",
					name = settingSilver,
					order = 1,
					width = "half",
				},
				summaryCopper = {
					type = "toggle",
					name = settingCopper,
					order = 2,
					width = "half",
				},
			},
		},
	}
}

local function GetKey(itemId, broker)
	if (broker) then
		return "show" .. itemId
	else
		return "summary" .. itemId
	end
end

-- Provide settings options for tokenInfo
local function SetOptions(brokerArgs, summaryArgs, tokenInfo, index)
	if (tokenInfo.settingIcon) then
		local brokerName = GetKey(tokenInfo.itemId, true)
		local summaryName = GetKey(tokenInfo.itemId, nil)
		brokerArgs[brokerName] = {
			type = "toggle",
			name = tokenInfo.settingIcon,
			desc = tokenInfo.itemName,
			order = index,
			width = "half",
			get = function()
				local key = brokerName
				return Broker_CurrencyCharDB[key]
			end,
			set = function(_, value)
				local key = brokerName
				Broker_CurrencyCharDB[key] = true and value or nil
				Broker_Currency:Update()
			end,
		}
		summaryArgs[summaryName] = {
			type = "toggle",
			name = tokenInfo.settingIcon,
			desc = tokenInfo.itemName,
			order = index,
			width = "half",
			get = function()
				local key = summaryName
				return Broker_CurrencyCharDB[key]
			end,
			set = function(_, value)
				local key = summaryName
				Broker_CurrencyCharDB[key] = true and value or nil
				Broker_Currency:Update()
			end,
		}
	end
end


LibStub("AceConfig-3.0"):RegisterOptionsTable("Broker Currency", Broker_Currency.options)
Broker_Currency.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Broker Currency", "Broker Currency")


local concatList = {}
-- Create the display string for a single line
-- money is the gold.silver.copper amount
-- broker is true if it is the broker string, nil if it is the tooltip summary string
-- playerInfo contains the relevant information
function Broker_Currency:CreateMoneyString(money, broker, playerInfo)
	-- Create Strings for the various currencies
	wipe(concatList)

	if (playerInfo) then
		for index, tokenInfo in pairs(currencyInfo) do
			if (tokenInfo.brokerIcon) then
				local key = GetKey(tokenInfo.itemId, broker)
				local count = playerInfo[tokenInfo.itemId] or 0
				if ((count > 0) and (Broker_CurrencyCharDB[key])) then
					concatList[# concatList + 1] = string.format(tokenInfo.brokerIcon, count, Broker_CurrencyCharDB.iconSize, Broker_CurrencyCharDB.iconSize)
					concatList[# concatList + 1] = "  "
				end
			end
		end
	end

	-- Create Strings for gold, silver, copper
	local copper = money % 100
	money = (money - copper) / 100
	local silver = money % 100
	local gold = floor(money / 100)

	if ((gold > 0) and (Broker_CurrencyCharDB.showGold and broker or not broker)) then
		concatList[# concatList + 1] = string.format(iconGold, gold, Broker_CurrencyCharDB.iconSizeGold, Broker_CurrencyCharDB.iconSizeGold)
		concatList[# concatList + 1] = " "
	end

	if ((gold + silver > 0) and (Broker_CurrencyCharDB.showSilver and broker or Broker_CurrencyCharDB.summarySilver and not broker)) then
		concatList[# concatList + 1] = string.format(iconSilver, silver, Broker_CurrencyCharDB.iconSizeGold, Broker_CurrencyCharDB.iconSizeGold)
		concatList[# concatList + 1] = " "
	end

	if ((gold + silver + copper > 0) and (Broker_CurrencyCharDB.showCopper and broker or Broker_CurrencyCharDB.summaryCopper and not broker)) then
		concatList[# concatList + 1] = string.format(iconCopper, copper, Broker_CurrencyCharDB.iconSizeGold, Broker_CurrencyCharDB.iconSizeGold)
		concatList[# concatList + 1] = " "
	end

	return table.concat(concatList)
end


local offset
function Broker_Currency:GetServerOffset()
	if offset then
		return offset
	end
	local serverHour, serverMinute = GetGameTime()
	local utcHour = tonumber(date("!%H"))
	local utcMinute = tonumber(date("!%M"))
	local ser = serverHour + serverMinute / 60
	local utc = utcHour + utcMinute / 60
	offset = floor((ser - utc) * 2 + 0.5) / 2
	if offset >= 12 then
		offset = offset - 24
	elseif offset < -12 then
		offset = offset + 24
	end
	return offset
end

local function GetToday(self)
	return floor((time() / 60 / 60 + self:GetServerOffset()) / 24)
end

function Broker_Currency:Update(event)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:InitializeSettings()
	end
	local realmInfo = Broker_CurrencyDB.realmInfo[realmName]
	local playerInfo = Broker_CurrencyDB.realm[realmName][playerName]
	local money = GetMoney()

	-- Update the current player info
	playerInfo.money = money

	-- Update Tokens
	for index, tokenInfo in pairs(currencyInfo) do
		if (tokenInfo.brokerIcon) then
			local count = tokenInfo.countFunc(tokenInfo.itemId)
--				count = GetItemCount(tokenInfo.itemName)
			playerInfo[tokenInfo.itemId] = count
		end
	end

	-- Display the money string according to the broker settings
	Broker_Currency.ldb.text = Broker_Currency:CreateMoneyString(money, true, playerInfo)

	-- Update Statistics
	local today = GetToday(self)
	if not self.lastTime then
		self.lastTime = today
	end
	local cutoffDay = today - 14
	if (today > self.lastTime) then
		playerInfo.gained[cutoffDay] = nil
		playerInfo.spent[cutoffDay] = nil
		playerInfo.time[cutoffDay] = nil
		realmInfo.gained[cutoffDay] = nil
		realmInfo.spent[cutoffDay] = nil
		realmInfo.time[cutoffDay] = nil
		playerInfo.gained[today] = playerInfo.gained[today] or {money = 0}
		playerInfo.spent[today] = playerInfo.spent[today] or {money = 0}
		playerInfo.time[today] = playerInfo.time[today] or 0
		realmInfo.gained[today] = realmInfo.gained[today] or {money = 0}
		realmInfo.spent[today] = realmInfo.spent[today] or {money = 0}
		realmInfo.time[today] = realmInfo.time[today] or 0
		self.lastTime = today
	end
	if (self.lastMoney < money) then
		self.gained.money = (self.gained.money or 0) + money - self.lastMoney
		playerInfo.gained[today].money = (playerInfo.gained[today].money or 0) + money - self.lastMoney
		realmInfo.gained[today].money = (realmInfo.gained[today].money or 0) + money - self.lastMoney
	elseif (self.lastMoney > money) then
		self.spent.money = (self.spent.money or 0) + self.lastMoney - money
		playerInfo.spent[today].money = (playerInfo.spent[today].money or 0) + self.lastMoney - money
		realmInfo.spent[today].money = (realmInfo.spent[today].money or 0) + self.lastMoney - money
	end
	self.lastMoney = money
	local now = time()
	if (not self.savedTime) then
		self.savedTime = now
	end
	playerInfo.time[today] = playerInfo.time[today] + now - self.savedTime
	realmInfo.time[today] = realmInfo.time[today] + now - self.savedTime
	self.savedTime = now
end


-- Add counts from playerInfo to totalList according to the summary settings this character is interested in
local function TotalCurrencies(totalList, playerInfo)
	for summaryName in pairs(Broker_CurrencyCharDB) do
		local countKey = tonumber(string.match(summaryName, "summary(%d+)"))
		local count = playerInfo[countKey]
		if (count) then
			totalList[countKey] = (totalList[countKey] or 0) + count
		end
	end
end
-- /dump Broker_CurrencyDB.realm["Proudmoore"]["Bliksem"]

local totalList = {}

-- Handle mouse enter event in our button
local function OnEnter(button)
	-- Display tooltip towards the center of the screen from the current quadrant we are in
 	GameTooltip:SetOwner(button, "ANCHOR_NONE")
	local x, y = button:GetCenter()
	if (x >= (GetScreenWidth() / 2)) then
		if (y >= (GetScreenHeight() / 2)) then
			GameTooltip:SetPoint("TOPRIGHT", button, "BOTTOMRIGHT")
		else
			GameTooltip:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT")
		end
	else
		if (y >= (GetScreenHeight() / 2)) then
			GameTooltip:SetPoint("TOPLEFT", button, "BOTTOMLEFT")
		else
			GameTooltip:SetPoint("BOTTOMLEFT", button, "TOPLEFT")
		end
	end

	-- Display the money string according to the summary settings
	GameTooltip:AddLine(sCurrency)

	local totalMoney = 0
	wipe(totalList)
	for playerName, playerInfo in pairs(Broker_CurrencyDB.realm[realmName]) do
		local money = playerInfo.money or 0
		local moneyString = Broker_Currency:CreateMoneyString(money, nil, playerInfo)
		GameTooltip:AddDoubleLine(string.format("%s: ", playerName), moneyString, nil, nil, nil, 1, 1, 1)
		totalMoney = totalMoney + money
		TotalCurrencies(totalList, playerInfo)
	end

	-- Statistics
	local charDB = Broker_CurrencyCharDB
	if (charDB.summaryPlayerSession or charDB.summaryRealmToday or charDB.summaryRealmYesterday or charDB.summaryRealmLastWeek) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(sStatistics)
	end

	-- Session totals
	local self = Broker_Currency
	if (charDB.summaryPlayerSession) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(playerName)

		GameTooltip:AddDoubleLine(sPlus, Broker_Currency:CreateMoneyString(self.gained.money, nil, nil), nil, nil, nil, 1, 1, 1)
		GameTooltip:AddDoubleLine(sMinus, Broker_Currency:CreateMoneyString(self.spent.money, nil, nil), nil, nil, nil, 1, 0, 0)
		local profit = self.gained.money - self.spent.money
		if (profit >= 0) then
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(profit, nil, nil), nil, nil, nil, 0, 1, 0)
		else
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(-profit, nil, nil), nil, nil, nil, 1, 0, 0)
		end
	end

	-- Today totals
	local realmInfo = Broker_CurrencyDB.realmInfo[realmName]
	local gained = realmInfo.gained
	local spent = realmInfo.spent
	local time = realmInfo.time
	if (charDB.summaryRealmToday) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(sToday)

		GameTooltip:AddDoubleLine(sPlus, Broker_Currency:CreateMoneyString(gained[self.lastTime].money, nil, nil), nil, nil, nil, 1, 1, 1)
		GameTooltip:AddDoubleLine(sMinus, Broker_Currency:CreateMoneyString(spent[self.lastTime].money, nil, nil), nil, nil, nil, 1, 0, 0)
		local profit = gained[self.lastTime].money - spent[self.lastTime].money
		if (profit >= 0) then
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(profit, nil, nil), nil, nil, nil, 0, 1, 0)
		else
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(-profit, nil, nil), nil, nil, nil, 1, 0, 0)
		end
	end

	-- Yesterday totals
	if (charDB.summaryRealmYesterday) then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(sYesterday)

		local yesterday = self.lastTime - 1
		GameTooltip:AddDoubleLine(sPlus, Broker_Currency:CreateMoneyString(gained[yesterday].money, nil, nil), nil, nil, nil, 1, 1, 1)
		GameTooltip:AddDoubleLine(sMinus, Broker_Currency:CreateMoneyString(spent[yesterday].money, nil, nil), nil, nil, nil, 1, 0, 0)
		local profit = gained[yesterday].money - spent[yesterday].money
		if (profit >= 0) then
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(profit, nil, nil), nil, nil, nil, 0, 1, 0)
		else
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(-profit, nil, nil), nil, nil, nil, 1, 0, 0)
		end
	end

	-- This Week totals
	local weekGained = 0
	local weekSpent = 0
	local weekTime = 0
	if (charDB.summaryRealmThisWeek) then
		for i = self.lastTime - 6, self.lastTime do
			weekGained = weekGained + gained[i].money or 0
			weekSpent = weekSpent + spent[i].money or 0
			weekTime = weekTime + time[i]
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(sThisWeek)

		GameTooltip:AddDoubleLine(sPlus, Broker_Currency:CreateMoneyString(weekGained, nil, nil), nil, nil, nil, 1, 1, 1)
		GameTooltip:AddDoubleLine(sMinus, Broker_Currency:CreateMoneyString(weekSpent, nil, nil), nil, nil, nil, 1, 0, 0)
		local profit = weekGained - weekSpent
		if (profit >= 0) then
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(profit, nil, nil), nil, nil, nil, 0, 1, 0)
		else
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(-profit, nil, nil), nil, nil, nil, 1, 0, 0)
		end
	end

	-- Last Week totals
	if (charDB.summaryRealmLastWeek) then
		weekGained = 0
		weekSpent = 0
		weekTime = 0
		for i = self.lastTime - 13, self.lastTime - 7 do
			weekGained = weekGained + gained[i].money or 0
			weekSpent = weekSpent + spent[i].money or 0
			weekTime = weekTime + time[i]
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(sLastWeek)

		GameTooltip:AddDoubleLine(sPlus, Broker_Currency:CreateMoneyString(weekGained, nil, nil), nil, nil, nil, 1, 1, 1)
		GameTooltip:AddDoubleLine(sMinus, Broker_Currency:CreateMoneyString(weekSpent, nil, nil), nil, nil, nil, 1, 0, 0)
		local profit = weekGained - weekSpent
		if (profit >= 0) then
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(profit, nil, nil), nil, nil, nil, 0, 1, 0)
		else
			GameTooltip:AddDoubleLine(sTotal, Broker_Currency:CreateMoneyString(-profit, nil, nil), nil, nil, nil, 1, 0, 0)
		end
	end

	-- Totals
	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(sSummary, Broker_Currency:CreateMoneyString(totalMoney, nil, totalList), nil, nil, nil, 1, 1, 1)

	GameTooltip:Show()
end
--/dump Broker_CurrencyDB.realm.Proudmoore.Bigudder

-- Set up as a LibBroker data source
Broker_Currency.ldb = LDB:NewDataObject("Broker Currency", {
	type = "data source",
	label = sCurrency,
	icon = "Interface\\MoneyFrame\\UI-GoldIcon",
	text = "5",
	OnClick = function(clickedframe, button)
		if (button == "RightButton") then
			InterfaceOptionsFrame_OpenToCategory(Broker_Currency.menu)
		end
	end,
	OnEnter = OnEnter,
	OnLeave = function()
		GameTooltip:Hide()
	end,
})


function Broker_Currency:InitializeSettings()
	-- Set defaults
	if (not Broker_CurrencyCharDB) then
		Broker_CurrencyCharDB = {
			showCopper = true,
			showSilver = true,
			showGold = true,
			showToday = true,
			showYesterday = true,
			showLastWeek = true,
        }
  	end

	if (not Broker_CurrencyCharDB.iconSize) then
		Broker_CurrencyCharDB.iconSize = 16
	end
	if (not Broker_CurrencyCharDB.iconSizeGold) then
		Broker_CurrencyCharDB.iconSizeGold = 16
	end

	if (not Broker_CurrencyDB) then
		Broker_CurrencyDB = {}
	end
	if (not Broker_CurrencyDB.realm) then
		Broker_CurrencyDB.realm = {}
	end
	if (not Broker_CurrencyDB.realmInfo) then
		Broker_CurrencyDB.realmInfo = {}
	end
	if (not Broker_CurrencyDB.realmInfo[realmName]) then
		Broker_CurrencyDB.realmInfo[realmName] = {}
	end

	if (not Broker_CurrencyDB.realm[realmName]) then
		Broker_CurrencyDB.realm[realmName] = {}
	end
	if (not Broker_CurrencyDB.realm[realmName][playerName]) then
		Broker_CurrencyDB.realm[realmName][playerName] = {}
	end

	local realmInfo = Broker_CurrencyDB.realmInfo[realmName]
	if (not realmInfo.gained or type(realmInfo.gained) ~= "table") then
		realmInfo.gained = {}
	end
	if (not realmInfo.spent or type(realmInfo.spent) ~= "table") then
		realmInfo.spent = {}
	end
	if (not realmInfo.time) then
		realmInfo.time = {}
	end

	local playerInfo = Broker_CurrencyDB.realm[realmName][playerName]
	if (not playerInfo.gained or type(playerInfo.gained) ~= "table") then
		playerInfo.gained = {}
	end
	if (not playerInfo.spent or type(playerInfo.spent) ~= "table") then
		playerInfo.spent = {}
	end
	if (not playerInfo.time) then
		playerInfo.time = {}
	end

	-- Initialize statistics
	self.initialMoney = GetMoney()
	self.lastMoney = self.initialMoney
	self.lastTime = GetToday(self)
	local lastWeek = self.lastTime - 13
	for day in pairs(playerInfo.gained) do
		if (day < lastWeek) then
			playerInfo.gained[day] = nil
		end
	end
	for day in pairs(playerInfo.spent) do
		if (day < lastWeek) then
			playerInfo.spent[day] = nil
		end
	end
	for day in pairs(playerInfo.time) do
		if (day < lastWeek) then
			playerInfo.time[day] = nil
		end
	end
	for day in pairs(realmInfo.gained) do
		if (day < lastWeek) then
			realmInfo.gained[day] = nil
		end
	end
	for day in pairs(realmInfo.spent) do
		if (day < lastWeek) then
			realmInfo.spent[day] = nil
		end
	end
	for day in pairs(realmInfo.time) do
		if (day < lastWeek) then
			realmInfo.time[day] = nil
		end
	end
	for i = self.lastTime - 13, self.lastTime do
		if (not playerInfo.gained[i] or type(playerInfo.gained[i]) ~= "table") then
			playerInfo.gained[i] = {money = 0}
		end
		if (not playerInfo.spent[i] or type(playerInfo.spent[i]) ~= "table") then
			playerInfo.spent[i] = {money = 0}
		end
		if (not playerInfo.time[i]) then
			playerInfo.time[i] = 0
		end
		if (not realmInfo.gained[i] or type(realmInfo.gained[i]) ~= "table") then
			realmInfo.gained[i] = {money = 0}
		end
		if (not realmInfo.spent[i] or type(realmInfo.spent[i]) ~= "table") then
			realmInfo.spent[i] = {money = 0}
		end
		if (not realmInfo.time[i]) then
			realmInfo.time[i] = 0
		end
	end
	self.gained = {money = 0}
	self.spent = {money = 0}
	self.sessionTime = time()
	self.savedTime = time()

	-- Add faction honor and arena icons
	local faction = UnitFactionGroup("player")
	local honorTexture
	if faction == "Horde" then
		honorTexture = "Interface\\Icons\\INV_BannerPVP_01"
	else
		honorTexture = "Interface\\Icons\\INV_BannerPVP_02"
	end
	local tokenInfo = currencyInfo[4]
	tokenInfo.settingIcon = "\124T" .. honorTexture .. ":32:32:2:0\124t"
	tokenInfo.brokerIcon = DISPLAY_ICON_STRING1 .. honorTexture .. DISPLAY_ICON_STRING2
	local arenaTexture = [[Interface\PVPFrame\PVP-ArenaPoints-Icon]]
	tokenInfo = currencyInfo[5]
	tokenInfo.settingIcon = "\124T" .. arenaTexture .. ":32:32:2:0\124t"
	tokenInfo.brokerIcon = DISPLAY_ICON_STRING1 .. arenaTexture .. DISPLAY_ICON_STRING2

	-- Add settings for the various currencies
	local brokerDisplay = Broker_Currency.options.args.brokerDisplay.args
	local summaryDisplay = Broker_Currency.options.args.summaryDisplay.args
	for index = 1, # currencyInfo, 1 do
		SetOptions(brokerDisplay, summaryDisplay, currencyInfo[index], index)
	end

	-- Force first update
	Broker_Currency:Update()

	-- Register for update events
	Broker_Currency:RegisterEvent("HONOR_CURRENCY_UPDATE", "Update")
	Broker_Currency:RegisterEvent("MERCHANT_CLOSED", "Update")
	Broker_Currency:RegisterEvent("PLAYER_MONEY", "Update")
	Broker_Currency:RegisterEvent("PLAYER_TRADE_MONEY", "Update")
	Broker_Currency:RegisterEvent("TRADE_MONEY_CHANGED", "Update")
	Broker_Currency:RegisterEvent("SEND_MAIL_MONEY_CHANGED", "Update")
	Broker_Currency:RegisterEvent("SEND_MAIL_COD_CHANGED", "Update")

	-- Done initializing
	Broker_Currency:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

-- Initialize on the PLAYER_ENTERING_WORLD event
Broker_Currency:RegisterEvent("PLAYER_ENTERING_WORLD")
Broker_Currency:SetScript("OnEvent", Broker_Currency.Update)
