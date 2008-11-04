--
-- Broker_Currency
-- Copyright 2008+ Toadkiller of Proudmoore.
--
-- LDB display of currencies, totals and money rate for all characters on a server.
-- I plan on incorporating some FuBar_MoneyFu style gold tracking so credit to ckknight in advance
-- http://code.google.com/p/autobar/
--

local LDB = LibStub:GetLibrary("LibDataBroker-1.1")

local iconSize = 20

local iconGold = GOLD_AMOUNT_TEXTURE
local iconSilver = SILVER_AMOUNT_TEXTURE
local iconCopper = COPPER_AMOUNT_TEXTURE

local settingSilver = "\124TInterface\\MoneyFrame\\UI-SilverIcon:32:32:2:0\124t"
local settingCopper = "\124TInterface\\MoneyFrame\\UI-CopperIcon:32:32:2:0\124t"

local SETTING_ICON_STRING = "\124T%s:32:32:2:0\124t"
local DISPLAY_ICON_STRING1 = "%d\124T"
local DISPLAY_ICON_STRING2 = ":%d:%d:2:0\124t"
local currencyInfo = {
	{},
	{},
	{itemId = 43307,},
	{itemId = 43308,},
	{itemId = 40753,},
	{itemId = 40752,},
	{itemId = 29434,},

	{itemId = 20560,},
	{itemId = 20559,},
	{itemId = 29024,},
	{itemId = 42425,},
	{itemId = 20558,},
	{itemId = 43589,},

	{itemId = 43016,},
	{itemId = 41596,},
	{itemId = 43228,},
	{itemId = 37836,},
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

local sCurrency = CURRENCY
local sDisplay = DISPLAY
local sSummary = ACHIEVEMENT_SUMMARY_CATEGORY
local sToday = HONOR_TODAY
local sYesterday = HONOR_YESTERDAY
local sLastWeek = HONOR_LASTWEEK

local playerName = UnitName("player")
local realmName = GetRealmName()



local Broker_Currency = CreateFrame("frame", "Broker_CurrencyFrame")
--LibStub("AceEvent-3.0"):Embed(Broker_Currency)


local name, title, sNotes, enabled, loadable, reason, security = GetAddOnInfo("Broker_Currency")
local options = {
	type = "group",
	name = sCurrency,
	args = {
		header = {
			type = "description",
			order = 10,
			name = sNotes,
			cmdHidden = true
		},
		brokerDisplay = {
			type = "group",
			name = sDisplay,
			order = 20,
			inline = true,
			childGroups = "tree",
			args = {
				showSilver = {
					type = "toggle",
					name = settingSilver,
					order = 1,
					width = "half",
					get = function() return Broker_CurrencyCharDB.showSilver end,
					set = function(_, value)
						Broker_CurrencyCharDB.showSilver = value
						Broker_Currency:Update()
					end,
				},
				showCopper = {
					type = "toggle",
					name = settingCopper,
					order = 2,
					width = "half",
					get = function() return Broker_CurrencyCharDB.showCopper end,
					set = function(_, value)
						Broker_CurrencyCharDB.showCopper = value
						Broker_Currency:Update()
					end,
				},
			},
		},
		summaryDisplay = {
			type = "group",
			name = sSummary,
			order = 30,
			inline = true,
			childGroups = "tree",
			args = {
				summarySilver = {
					type = "toggle",
					name = settingSilver,
					order = 1,
					width = "half",
					get = function() return Broker_CurrencyCharDB.summarySilver end,
					set = function(_, value)
						Broker_CurrencyCharDB.summarySilver = value
						Broker_Currency:Update()
					end,
				},
				summaryCopper = {
					type = "toggle",
					name = settingCopper,
					order = 2,
					width = "half",
					get = function() return Broker_CurrencyCharDB.summaryCopper end,
					set = function(_, value)
						Broker_CurrencyCharDB.summaryCopper = value
						Broker_Currency:Update()
					end,
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
				local key = brokerName; Broker_CurrencyCharDB[key] = value
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
				local key = summaryName;
				Broker_CurrencyCharDB[key] = value
				Broker_Currency:Update()
			end,
		}
	end
end

-- Add settings for the various currencies
do
	local brokerDisplay = options.args.brokerDisplay.args
	local summaryDisplay = options.args.summaryDisplay.args
	for index = 1, # currencyInfo, 1 do
		SetOptions(brokerDisplay, summaryDisplay, currencyInfo[index], index)
	end
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("Broker Currency", options)
Broker_Currency.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Broker Currency", "Broker Currency")


local concatList = {}
function Broker_Currency:CreateMoneyString(money, broker, playerInfo)
	local copper = money % 100
	money = (money - copper) / 100
	local silver = money % 100
	local gold = floor(money / 100)

	for index in pairs(concatList) do
		concatList[index] = nil
	end

	if (playerInfo) then
		for index, tokenInfo in pairs(currencyInfo) do
			if (tokenInfo.brokerIcon) then
				local key = GetKey(tokenInfo.itemId, broker)
				local count = playerInfo[tokenInfo.itemId] or 0
				if ((count > 0) and (Broker_CurrencyCharDB[key])) then
					concatList[# concatList + 1] = string.format(tokenInfo.brokerIcon, count, iconSize, iconSize)
					concatList[# concatList + 1] = " "
				end
			end
		end
	end

	if (gold > 0) then
		concatList[# concatList + 1] = string.format(iconGold, gold, iconSize, iconSize)
		concatList[# concatList + 1] = " "
	end

	if ((gold + silver > 0) and (Broker_CurrencyCharDB.showSilver and broker or Broker_CurrencyCharDB.summarySilver and not broker)) then
		concatList[# concatList + 1] = string.format(iconSilver, silver, iconSize, iconSize)
		concatList[# concatList + 1] = " "
	end

	if ((gold + silver + copper > 0) and (Broker_CurrencyCharDB.showCopper and broker or Broker_CurrencyCharDB.summaryCopper and not broker)) then
		concatList[# concatList + 1] = string.format(iconCopper, copper, iconSize, iconSize)
		concatList[# concatList + 1] = " "
	end

	return table.concat(concatList)
end


function Broker_Currency:Update()
	local money = GetMoney()

	local playerInfo = Broker_CurrencyDB.realm[realmName][playerName]
	playerInfo.money = money

	for index, tokenInfo in pairs(currencyInfo) do
		if (tokenInfo.brokerIcon) then
			local count = GetItemCount(tokenInfo.itemName)
			playerInfo[tokenInfo.itemId] = count
		end
	end

	Broker_Currency.ldb.text = Broker_Currency:CreateMoneyString(money, true, playerInfo)
end



local function OnEnter(button)
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

	GameTooltip:AddLine(sCurrency)

	local totalMoney = 0
	for playerName, playerInfo in pairs(Broker_CurrencyDB.realm[realmName]) do
		local money = playerInfo.money
		local moneyString = Broker_Currency:CreateMoneyString(money, nil, playerInfo)
		GameTooltip:AddDoubleLine(string.format("%s: ", playerName), moneyString, nil, nil, nil, 1, 1, 1)
		totalMoney = totalMoney + money
	end

	GameTooltip:AddLine(" ")
	GameTooltip:AddDoubleLine(sSummary, Broker_Currency:CreateMoneyString(totalMoney), nil, nil, nil, 1, 1, 1)

	GameTooltip:Show()
end


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
	if (not Broker_CurrencyCharDB) then
		Broker_CurrencyCharDB = {
			showCopper = true,
			showSilver = true,
        }
  	end

	if (not Broker_CurrencyDB) then
		Broker_CurrencyDB = {}
	end
	if (not Broker_CurrencyDB.realm) then
		Broker_CurrencyDB.realm = {}
	end
	local realmInfo = Broker_CurrencyDB.realm[realmName]
	if (not realmInfo) then
		realmInfo = {}
		Broker_CurrencyDB.realm[realmName] = realmInfo
	end
	if (not realmInfo[playerName]) then
		realmInfo[playerName] = {}
	end

	Broker_Currency:Update()

	Broker_Currency:RegisterEvent("PLAYER_MONEY", "Update")
	Broker_Currency:RegisterEvent("PLAYER_TRADE_MONEY", "Update")
	Broker_Currency:RegisterEvent("TRADE_MONEY_CHANGED", "Update")
	Broker_Currency:RegisterEvent("SEND_MAIL_MONEY_CHANGED", "Update")
	Broker_Currency:RegisterEvent("SEND_MAIL_COD_CHANGED", "Update")

	Broker_Currency:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

Broker_Currency:RegisterEvent("PLAYER_ENTERING_WORLD", "InitializeSettings")
