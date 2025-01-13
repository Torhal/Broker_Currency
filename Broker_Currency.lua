--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local AddOnFolderName, private = ...

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@class Broker_Currency: AceAddon, AceAddon-3.0, AceBucket-3.0, AceConsole-3.0, AceEvent-3.0, AceTimer-3.0
local Broker_Currency =
    LibStub("AceAddon-3.0"):NewAddon(AddOnFolderName, "AceBucket-3.0", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

_G["Broker_Currency"] = Broker_Currency

local CategoryCurrencyGroups = private.CategoryCurrencyGroups
local ExpansionCurrencyGroups = private.ExpansionCurrencyGroups

local CategoryCurrencyIDs = private.CategoryCurrencyIDs
local ExpansionCurrencyIDs = private.ExpansionCurrencyIDs
local IgnoredCurrencyIDs = private.IgnoredCurrencyIDs

local CurrencyID = private.CurrencyID
local CurrencyItemID = private.CurrencyItemID

local CurrencyItemName = private.CurrencyItemName
local CurrencyName = private.CurrencyName

local C_AddOns = _G.C_AddOns or _G
local C_CurrencyInfo = _G.C_CurrencyInfo or _G
local C_Item = _G.C_Item or _G

--------------------------------------------------------------------------------
---- Constants
--------------------------------------------------------------------------------
local CategoryGroupLabels = {
    PROFESSIONS_ARCHAEOLOGY or "Archaeology",
    BONUS_ROLL_TOOLTIP_TITLE or "Bonus Loot",
    COLLECTIONS or "Collections",
    DUNGEONS or "Dungeons",
    CALENDAR_FILTER_HOLIDAYS or "Holidays",
    PVP or "PvP",
}

local ExpansionGroupLabels = {
    EXPANSION_NAME1 or "The Burning Crusade",
    EXPANSION_NAME2 or "Wrath of the Lich King",
    EXPANSION_NAME3 or "Cataclysm",
    EXPANSION_NAME4 or "Mists of Pandaria",
    EXPANSION_NAME5 or "Warlords of Draenor",
    EXPANSION_NAME6 or "Legion",
    EXPANSION_NAME7 or "Battle for Azeroth",
    EXPANSION_NAME8 or "Shadowlands",
    EXPANSION_NAME9 or "Dragonflight",
    EXPANSION_NAME10 or "The War Within",
}

local GoldIcon = "\124TInterface\\MoneyFrame\\UI-GoldIcon:20:20\124t"
private.GoldIcon = GoldIcon

local SilverIcon = "\124TInterface\\MoneyFrame\\UI-SilverIcon:20:20\124t"
private.SilverIcon = SilverIcon

local CopperIcon = "\124TInterface\\MoneyFrame\\UI-CopperIcon:20:20\124t"
private.CopperIcon = CopperIcon

local TodayLabel = HONOR_TODAY
private.TodayLabel = TodayLabel

local YesterdayLabel = HONOR_YESTERDAY
private.YesterdayLabel = YesterdayLabel

local ThisWeekLabel = ARENA_THIS_WEEK
private.ThisWeekLabel = ThisWeekLabel

local LastWeekLabel = HONOR_LASTWEEK
private.LastWeekLabel = LastWeekLabel

local DisplayIconStringLeft = "%s \124T"
local DisplayIconStringRight = ":%d:%d\124t"

local PlayerName = UnitName("player")
local RealmName = GetRealmName()

-- Populated as needed.
local CurrencyNameCache

local OptionIcons = {}
private.OptionIcons = OptionIcons

local BrokerIcons = {}
private.BrokerIcons = BrokerIcons

local CurrencyDescriptions = {}

--------------------------------------------------------------------------------
---- Helper Functions
--------------------------------------------------------------------------------
--[[
    Data is saved per realm/character in Broker_CurrencyDB
    Options are saved per character in Broker_CurrencyCharDB
    There are separate settings for display of the broker, and the summary display on the tooltip
]]
local function GetKey(currencyID, isForBroker)
    return (isForBroker and "show" or "summary") .. currencyID
end
private.GetKey = GetKey

local function ShowOptionIcon(currencyID)
    local iconSize = Broker_CurrencyCharDB.iconSize

    return string.format("\124T%s%s", OptionIcons[currencyID] or "", DisplayIconStringRight):format(iconSize, iconSize)
end
private.ShowOptionIcon = ShowOptionIcon

local function GetServerOffset()
    local serverHour, serverMinute = GetGameTime()
    local utcHour = tonumber(date("!%H"))
    local utcMinute = tonumber(date("!%M"))
    local ser = serverHour + serverMinute / 60
    local utc = utcHour + utcMinute / 60

    local offset = math.floor((ser - utc) * 2 + 0.5) / 2

    if offset >= 12 then
        offset = offset - 24
    elseif offset < -12 then
        offset = offset + 24
    end

    return offset
end

local function GetToday()
    return math.floor((time() / 60 / 60 + GetServerOffset()) / 24)
end

local CreateMoneyString
do
    local GoldAmountTexture = [[%s|TInterface\MoneyFrame\UI-GoldIcon:%d:%d:2:0|t]]
    local SilverAmountTexture = [[%s|TInterface\MoneyFrame\UI-SilverIcon:%d:%d:2:0|t]]
    local CopperAmountTexture = [[%s|TInterface\MoneyFrame\UI-CopperIcon:%d:%d:2:0|t]]

    local concatList = {}

    local function ConcatenateMoneyString(currencyTotals, currencyIDList)
        local characterDB = Broker_CurrencyCharDB
        local iconSize = characterDB.iconSize

        for index = 1, #currencyIDList do
            local currencyID = currencyIDList[index]
            local displayIcon = BrokerIcons[currencyID]

            if displayIcon then
                local count = currencyTotals[currencyID] or 0

                if count > 0 and characterDB[GetKey(currencyID, true)] then
                    concatList[#concatList + 1] =
                        string.format(displayIcon, BreakUpLargeNumbers(count), iconSize, iconSize)

                    concatList[#concatList + 1] = "  "
                end
            end
        end
    end

    -- Create the display string for a single line
    -- money is the gold.silver.copper amount
    -- broker is true if it is the broker string, nil if it is the tooltip summary string
    -- currencyTotals contains totals for the set of currencies
    function CreateMoneyString(currencyTotals)
        local money = currencyTotals.money
        local characterDB = Broker_CurrencyCharDB

        -- Create Strings for the various currencies
        table.wipe(concatList)

        if currencyTotals then
            ConcatenateMoneyString(currencyTotals, CategoryCurrencyIDs)
            ConcatenateMoneyString(currencyTotals, ExpansionCurrencyIDs)
        end

        -- Create Strings for gold, silver, copper
        local copper = money % 100
        money = (money - copper) / 100

        local silver = money % 100
        local gold = math.floor(money / 100)

        if characterDB.showGold and gold > 0 then
            concatList[#concatList + 1] = string.format(
                GoldAmountTexture,
                BreakUpLargeNumbers(gold),
                characterDB.iconSizeGold,
                characterDB.iconSizeGold
            )

            concatList[#concatList + 1] = " "
        end

        if characterDB.showSilver and gold + silver > 0 then
            concatList[#concatList + 1] = string.format(
                SilverAmountTexture,
                BreakUpLargeNumbers(silver),
                characterDB.iconSizeGold,
                characterDB.iconSizeGold
            )

            concatList[#concatList + 1] = " "
        end

        if characterDB.showCopper and gold + silver + copper > 0 then
            concatList[#concatList + 1] = string.format(
                CopperAmountTexture,
                BreakUpLargeNumbers(copper),
                characterDB.iconSizeGold,
                characterDB.iconSizeGold
            )

            concatList[#concatList + 1] = " "
        end

        return table.concat(concatList)
    end
end

local GetCurrencyCount
do
    local validCurrencies = {}

    for index = 1, #CategoryCurrencyIDs do
        validCurrencies[CategoryCurrencyIDs[index]] = true
    end

    for index = 1, #ExpansionCurrencyIDs do
        validCurrencies[ExpansionCurrencyIDs[index]] = true
    end

    function GetCurrencyCount(currencyID)
        if not validCurrencies[currencyID] then
            return 0
        end

        return CurrencyItemName[currencyID] and C_Item.GetItemCount(currencyID, true)
            or C_CurrencyInfo.GetCurrencyInfo(currencyID).quantity
    end
end

local DatamineTooltip = CreateFrame("GameTooltip", "Broker_CurrencyDatamineTooltip", UIParent, "GameTooltipTemplate")
DatamineTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function UpdateCurrencyDescriptions()
    for _, currencyID in pairs(CurrencyID) do
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)

        CurrencyDescriptions[currencyID] = currencyInfo and currencyInfo.description or ""
    end

    for _, currencyID in pairs(CurrencyItemID) do
        local _, _, _, _, iconFileDataID = C_Item.GetItemInfoInstant(currencyID)

        if iconFileDataID and iconFileDataID ~= "" then
            local _, itemHyperlink = C_Item.GetItemInfo(currencyID)

            if itemHyperlink then
                DatamineTooltip:SetHyperlink(itemHyperlink)

                local left3 = _G["Broker_CurrencyDatamineTooltipTextLeft3"]
                local left3Text = left3 and left3:GetText() or nil

                local left4 = _G["Broker_CurrencyDatamineTooltipTextLeft4"]
                local left4Text = left4 and left4:GetText() or nil

                local description = SEARCH_LOADING_TEXT

                if left3Text and left3Text ~= "" then
                    if left4Text and left4Text ~= "" then
                        description = ("%s\n\n%s"):format(left3Text, left4Text)
                    else
                        description = left3Text
                    end
                end

                CurrencyDescriptions[currencyID] = ("%s\n\n%s"):format(PARENS_TEMPLATE:format(ITEMS), description)
            end
        end
    end
end
private.UpdateCurrencyDescriptions = UpdateCurrencyDescriptions

local function UpdateTokens(currencyIDList, playerInfo, realmInfo, today)
    for index = 1, #currencyIDList do
        local currencyID = currencyIDList[index]

        if BrokerIcons[currencyID] then
            local count = GetCurrencyCount(currencyID)

            playerInfo[currencyID] = count

            local lastCount = Broker_Currency.last[currencyID]

            if lastCount then
                if lastCount < count then
                    Broker_Currency.gained[currencyID] = (Broker_Currency.gained[currencyID] or 0) + count - lastCount

                    playerInfo.gained[today][currencyID] = (playerInfo.gained[today][currencyID] or 0)
                        + count
                        - lastCount

                    realmInfo.gained[today][currencyID] = (realmInfo.gained[today][currencyID] or 0) + count - lastCount
                elseif lastCount > count then
                    Broker_Currency.spent[currencyID] = (Broker_Currency.spent[currencyID] or 0) + lastCount - count

                    playerInfo.spent[today][currencyID] = (playerInfo.spent[today][currencyID] or 0) + lastCount - count

                    realmInfo.spent[today][currencyID] = (realmInfo.spent[today][currencyID] or 0) + lastCount - count
                end
            end

            Broker_Currency.last[currencyID] = count
        end
    end
end

local UpdateEventNames = {
    "BANKFRAME_OPENED",
    "CHAT_MSG_CURRENCY",
    "CHAT_MSG_LOOT",
    "CURRENCY_DISPLAY_UPDATE",
    "MERCHANT_CLOSED",
    "PLAYER_MONEY",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEAVING_WORLD",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_TRADE_MONEY",
    "SEND_MAIL_COD_CHANGED",
    "SEND_MAIL_MONEY_CHANGED",
    "TRADE_MONEY_CHANGED",
}

function Broker_Currency:OnEnable()
    self:RegisterBucketEvent("BAG_UPDATE", 0.5, "Update")

    for index = 1, #UpdateEventNames do
        self:RegisterEvent(UpdateEventNames[index], "Update")
    end

    UpdateCurrencyDescriptions()
end

function Broker_Currency:Update()
    local realmInfo = Broker_CurrencyDB.realmInfo[RealmName]

    if not realmInfo then
        realmInfo = {}

        Broker_CurrencyDB.realmInfo[RealmName] = realmInfo
    end

    local playerInfo = Broker_CurrencyDB.realm[RealmName][PlayerName]

    if not playerInfo then
        playerInfo = {}

        Broker_CurrencyDB.realm[RealmName][PlayerName] = playerInfo
    end

    local currentMoney = GetMoney()

    UpdateCurrencyDescriptions()

    -- Update the current player info
    playerInfo.money = currentMoney

    -- Update Statistics
    local today = GetToday()

    if not self.lastTime then
        self.lastTime = today
    end

    local cutoffDay = today - 14

    if today > self.lastTime then
        playerInfo.gained[cutoffDay] = nil
        playerInfo.spent[cutoffDay] = nil
        realmInfo.gained[cutoffDay] = nil
        realmInfo.spent[cutoffDay] = nil
        playerInfo.gained[today] = playerInfo.gained[today] or { money = 0 }
        playerInfo.spent[today] = playerInfo.spent[today] or { money = 0 }
        realmInfo.gained[today] = realmInfo.gained[today] or { money = 0 }
        realmInfo.spent[today] = realmInfo.spent[today] or { money = 0 }
        self.lastTime = today
    end

    -- Update Money
    if self.last.money < currentMoney then
        self.gained.money = (self.gained.money or 0) + currentMoney - self.last.money
        playerInfo.gained[today].money = (playerInfo.gained[today].money or 0) + currentMoney - self.last.money
        realmInfo.gained[today].money = (realmInfo.gained[today].money or 0) + currentMoney - self.last.money
    elseif self.last.money > currentMoney then
        self.spent.money = (self.spent.money or 0) + self.last.money - currentMoney
        playerInfo.spent[today].money = (playerInfo.spent[today].money or 0) + self.last.money - currentMoney
        realmInfo.spent[today].money = (realmInfo.spent[today].money or 0) + self.last.money - currentMoney
    end

    self.last.money = currentMoney

    UpdateTokens(CategoryCurrencyIDs, playerInfo, realmInfo, today)
    UpdateTokens(ExpansionCurrencyIDs, playerInfo, realmInfo, today)

    -- Display the money string according to the broker settings
    if private.DataObject then
        private.DataObject.text = CreateMoneyString(playerInfo)
    end

    self.savedTime = time()

    --------------------------------------------------------------------------------
    ---- If you want to send id numbers for currencies which are missing, /dump
    ---- these tables while in-game.
    --------------------------------------------------------------------------------
    BROKER_CURRENCY_UNKNOWN = {}
    BROKER_CURRENCY_UNKNOWN_FORMATTED = {}

    for currencyID = 1, 10000 do
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        local formattedName = currencyInfo and currencyInfo.name:gsub(" ", ""):gsub("'", "") or nil

        if
            formattedName
            and formattedName ~= ""
            and not CurrencyName[currencyID]
            and not tContains(IgnoredCurrencyIDs, currencyID)
        then
            BROKER_CURRENCY_UNKNOWN[currencyID] = formattedName
            BROKER_CURRENCY_UNKNOWN_FORMATTED[formattedName] = currencyID
        end
    end
end

do
    --------------------------------------------------------------------------------
    ---- Constants
    --------------------------------------------------------------------------------
    local iconSource = C_CurrencyInfo.GetCurrencyInfo(CurrencyID.CuriousCoin)
        or C_CurrencyInfo.GetCurrencyInfo(CurrencyID.DalaranJewelcraftersToken)
    local iconToken = DisplayIconStringLeft .. (
        iconSource and iconSource.iconFileID or Constants.CurrencyConsts.QUESTIONMARK_INV_ICON
    ) .. DisplayIconStringRight

    local metadataVersion = C_AddOns.GetAddOnMetadata("Broker_Currency", "Version")
    local IsDevelopmentVersion = false
    local IsAlphaVersion = false

    --@debug@
    IsDevelopmentVersion = true
    --@end-debug@

    --@alpha@
    IsAlphaVersion = true
    --@end-alpha@

    local BuildVersion = IsDevelopmentVersion and "Development Version"
        or (IsAlphaVersion and metadataVersion .. "-Alpha")
        or metadataVersion

    --------------------------------------------------------------------------------
    ---- Helper Functions
    --------------------------------------------------------------------------------
    local function getColorValue(info)
        local color = Broker_CurrencyCharDB[info[#info]]

        return color.r, color.g, color.b, color.a
    end

    local function setColorValue(info, r, g, b, a)
        local color = Broker_CurrencyCharDB[info[#info]]

        color.r, color.g, color.b, color.a = r, g, b, a
        Broker_Currency:Update()
    end

    local function BuildOptionSection(sectionName, currencyID, currencyName, displayOrder)
        return {
            name = ("%s %s"):format(ShowOptionIcon(currencyID), currencyName),
            desc = function()
                return CurrencyDescriptions[currencyID]
            end,
            order = displayOrder,
            type = "toggle",
            width = "full",
            get = function()
                return Broker_CurrencyCharDB[sectionName]
            end,
            set = function(_, value)
                Broker_CurrencyCharDB[sectionName] = true and value or nil
                Broker_Currency:Update()
            end,
        }
    end

    local function SetOptions(brokerArgs, summaryArgs, currencyID, displayOrder)
        local currencyName = CurrencyNameCache[currencyID] or CurrencyItemName[currencyID] or CurrencyName[currencyID]

        if not currencyName or currencyName == "" then
            return
        end

        local brokerName = GetKey(currencyID, true)
        local summaryName = GetKey(currencyID, nil)

        brokerArgs[brokerName] = BuildOptionSection(brokerName, currencyID, currencyName, displayOrder)
        summaryArgs[summaryName] = BuildOptionSection(summaryName, currencyID, currencyName, displayOrder)
    end

    local function AddGroupOptions(groupName, groupList, groupLabels, offset)
        local brokerDisplay = Broker_Currency.options.args.brokerDisplay.args
        local summaryDisplay = Broker_Currency.options.args.summaryDisplay.args

        for groupListIndex = 1, #groupList do
            local group = groupList[groupListIndex]
            local optionGroupName = groupName .. groupListIndex

            brokerDisplay[optionGroupName] = {
                name = groupLabels[groupListIndex],
                order = groupListIndex + offset,
                type = "group",
                args = {},
            }

            summaryDisplay[optionGroupName] = {
                name = groupLabels[groupListIndex],
                order = groupListIndex + offset,
                type = "group",
                args = {},
            }

            for groupIndex = 1, #group do
                SetOptions(
                    brokerDisplay[optionGroupName].args,
                    summaryDisplay[optionGroupName].args,
                    group[groupIndex],
                    groupIndex
                )
            end
        end
    end

    -- Add delete settings so deleted characters can be removed
    local function DeletePlayer(info)
        local playerName = info[#info]
        local deleteOptions = Broker_Currency.options.args.deleteCharacter.args

        deleteOptions[playerName] = nil
        deleteOptions[playerName .. "Name"] = nil
        deleteOptions[playerName .. "Spacer"] = nil
        Broker_CurrencyDB.realm[RealmName][playerName] = nil
    end

    local function AddDeleteOptions(playerName, playerInfoList, index)
        local deleteOptions = Broker_Currency.options.args.deleteCharacter.args

        if not deleteOptions[playerName] then
            deleteOptions[playerName .. "Name"] = {
                order = index * 3,
                type = "description",
                width = "half",
                name = playerName,
                fontSize = "medium",
            }

            deleteOptions[playerName] = {
                order = index * 3 + 1,
                type = "execute",
                width = "half",
                name = DELETE,
                desc = playerName,
                func = DeletePlayer,
            }

            deleteOptions[playerName .. "Spacer"] = {
                order = index * 3 + 2,
                type = "description",
                width = "full",
                name = "",
            }
        end
    end

    local function SetCacheValuesFromCurrency(currencyID)
        local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID)
        if not currencyInfo then return end
        local currencyName = currencyInfo.name

        if currencyName and currencyName ~= "" then
            CurrencyNameCache[currencyID] = currencyName
        end

        local iconFileID = currencyInfo.iconFileID

        if iconFileID and iconFileID ~= "" then
            OptionIcons[currencyID] = iconFileID
            BrokerIcons[currencyID] = DisplayIconStringLeft .. iconFileID .. DisplayIconStringRight
        end
    end

    local function SetCacheValuesFromItem(currencyID)
        local _, _, _, _, iconFileDataID = C_Item.GetItemInfoInstant(currencyID)

        if iconFileDataID and iconFileDataID ~= "" then
            local itemName = C_Item.GetItemInfo(currencyID)

            if itemName then
                CurrencyNameCache[currencyID] = itemName
            end

            OptionIcons[currencyID] = iconFileDataID
            BrokerIcons[currencyID] = DisplayIconStringLeft .. iconFileDataID .. DisplayIconStringRight
        end
    end

    local function SetCacheValues(currencyIDList)
        for index = 1, #currencyIDList do
            local currencyID = currencyIDList[index]

            if CurrencyItemName[currencyID] then
                SetCacheValuesFromItem(currencyID)
            else
                SetCacheValuesFromCurrency(currencyID)
            end
        end
    end

    local function UpdatePlayerAndLastCounts(currencyIDList, playerInfo)
        local last = Broker_Currency.last

        for index = 1, #currencyIDList do
            local currencyID = currencyIDList[index]

            if BrokerIcons[currencyID] then
                local count = GetCurrencyCount(currencyID)

                playerInfo[currencyID] = count
                last[currencyID] = count
            end
        end
    end

    --------------------------------------------------------------------------------
    ---- Preferences
    --------------------------------------------------------------------------------
    function Broker_Currency:OnInitialize()
        self.last = {}

        UpdateCurrencyDescriptions()

        --------------------------------------------------------------------------------
        ---- Set Defaults
        --------------------------------------------------------------------------------
        Broker_CurrencyCharDB = Broker_CurrencyCharDB
            or {
                showCopper = true,
                showSilver = true,
                showGold = true,
                showToday = true,
                showYesterday = true,
                showLastWeek = true,
                summaryGold = true,
                summaryColorDark = { r = 0, g = 0, b = 0, a = 0 },
                summaryColorLight = { r = 1, g = 1, b = 1, a = 0.3 },
            }

        --------------------------------------------------------------------------------
        ---- Configuration Options
        --------------------------------------------------------------------------------
        Broker_Currency.options = {
            args = {
                deleteCharacter = {
                    args = {},
                    order = 4,
                    name = CHARACTER,
                    type = "group",
                },
                generalSettings = {
                    args = {
                        iconSize = {
                            type = "range",
                            order = 10,
                            name = string.format(iconToken, 8, 16, 16),
                            desc = TOKENS,
                            min = 1,
                            max = 32,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Broker_CurrencyCharDB.iconSize
                            end,
                            set = function(info, value)
                                local iconSize = Broker_CurrencyCharDB.iconSize

                                Broker_CurrencyCharDB[info[#info]] = true and value or nil
                                Broker_Currency.options.args.generalSettings.args.iconSize.name =
                                    iconToken:format(8, iconSize, iconSize)
                                Broker_Currency:Update()
                            end,
                        },
                        iconSizeGold = {
                            type = "range",
                            order = 10,
                            name = string.format(GOLD_AMOUNT_TEXTURE, 8, 16, 16),
                            desc = MONEY,
                            min = 1,
                            max = 32,
                            step = 1,
                            bigStep = 1,
                            get = function()
                                return Broker_CurrencyCharDB.iconSizeGold
                            end,
                            set = function(info, value)
                                local iconSize = Broker_CurrencyCharDB.iconSizeGold

                                Broker_CurrencyCharDB[info[#info]] = true and value or nil
                                Broker_Currency.options.args.generalSettings.args.iconSizeGold.name =
                                    GOLD_AMOUNT_TEXTURE:format(8, iconSize, iconSize)
                                Broker_Currency:Update()
                            end,
                        },
                        color_header = {
                            order = 100,
                            type = "header",
                            name = COLOR,
                        },
                        summaryColorDark = {
                            type = "color",
                            name = BACKGROUND,
                            order = 101,
                            get = getColorValue,
                            set = setColorValue,
                            hasAlpha = true,
                        },
                        summaryColorLight = {
                            type = "color",
                            name = HIGHLIGHTING,
                            order = 102,
                            get = getColorValue,
                            set = setColorValue,
                            hasAlpha = true,
                        },
                        statistics_header = {
                            order = 200,
                            type = "header",
                            name = STATISTICS,
                        },
                        summaryPlayerSession = {
                            type = "toggle",
                            name = PlayerName,
                            order = 201,
                        },
                        summaryRealmToday = {
                            type = "toggle",
                            name = TodayLabel,
                            order = 202,
                        },
                        summaryRealmYesterday = {
                            type = "toggle",
                            name = YesterdayLabel,
                            order = 203,
                        },
                        summaryRealmThisWeek = {
                            type = "toggle",
                            name = ThisWeekLabel,
                            order = 204,
                        },
                        summaryRealmLastWeek = {
                            type = "toggle",
                            name = LastWeekLabel,
                            order = 205,
                        },
                    },
                    get = function(info)
                        return Broker_CurrencyCharDB[info[#info]]
                    end,
                    name = GENERAL,
                    order = 1,
                    set = function(info, value)
                        Broker_CurrencyCharDB[info[#info]] = true and value or nil
                        Broker_Currency:Update()
                    end,
                    type = "group",
                },
                brokerDisplay = {
                    args = {
                        money = {
                            name = MONEY,
                            order = 1,
                            type = "group",
                            args = {
                                showGold = {
                                    name = ("%s %s"):format(GoldIcon, GOLD_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                },
                                showSilver = {
                                    name = ("%s %s"):format(SilverIcon, SILVER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                },
                                showCopper = {
                                    name = ("%s %s"):format(CopperIcon, COPPER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 3,
                                    type = "toggle",
                                    width = "full",
                                },
                            },
                        },
                    },
                    name = DISPLAY,
                    order = 2,
                    type = "group",
                },
                summaryDisplay = {
                    args = {
                        money = {
                            name = MONEY,
                            order = 1,
                            type = "group",
                            args = {
                                summaryGold = {
                                    name = ("%s %s"):format(GoldIcon, GOLD_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 1,
                                    type = "toggle",
                                    width = "full",
                                },
                                summarySilver = {
                                    name = ("%s %s"):format(SilverIcon, SILVER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 2,
                                    type = "toggle",
                                    width = "full",
                                },
                                summaryCopper = {
                                    name = ("%s %s"):format(CopperIcon, COPPER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 3,
                                    type = "toggle",
                                    width = "full",
                                },
                            },
                        },
                    },
                    name = ACHIEVEMENT_SUMMARY_CATEGORY,
                    order = 2,
                    type = "group",
                },
            },
            childGroups = "tab",
            get = function(info)
                return Broker_CurrencyCharDB[info[#info]]
            end,
            name = ("%s - %s"):format(AddOnFolderName, BuildVersion),
            set = function(info, value)
                Broker_CurrencyCharDB[info[#info]] = true and value or nil
                Broker_Currency:Update()
            end,
            type = "group",
        }

        AceConfig:RegisterOptionsTable(AddOnFolderName, Broker_Currency.options)
        Broker_Currency.menu = AceConfigDialog:AddToBlizOptions(AddOnFolderName)

        --------------------------------------------------------------------------------
        ---- Check or Initialize Character Database
        --------------------------------------------------------------------------------
        local characterDB = Broker_CurrencyCharDB

        if not characterDB.iconSize then
            characterDB.iconSize = 16
        end

        if not characterDB.iconSizeGold then
            characterDB.iconSizeGold = 16
        end

        if not characterDB.summaryColorDark then
            characterDB.summaryColorDark = { r = 0, g = 0, b = 0, a = 0 }
        end

        if not characterDB.summaryColorLight then
            characterDB.summaryColorLight = { r = 1, g = 1, b = 1, a = 0.3 }
        end

        Broker_CurrencyCharDB = characterDB

        --------------------------------------------------------------------------------
        ---- Check or Initialize Database
        --------------------------------------------------------------------------------
        if not Broker_CurrencyDB then
            Broker_CurrencyDB = {}
        end

        local db = Broker_CurrencyDB

        -- Icons, names and textures for the currencies
        if not db.currencyNames then
            db.currencyNames = {}
        end

        CurrencyNameCache = db.currencyNames

        SetCacheValues(CategoryCurrencyIDs)
        SetCacheValues(ExpansionCurrencyIDs)

        if not db.realm then
            db.realm = {}
        end

        if not db.realmInfo then
            db.realmInfo = {}
        end

        if not db.realmInfo[RealmName] then
            db.realmInfo[RealmName] = {}
        end

        if not db.realm[RealmName] then
            db.realm[RealmName] = {}
        end

        if not db.realm[RealmName][PlayerName] then
            db.realm[RealmName][PlayerName] = {}
        end

        local realmInfo = db.realmInfo[RealmName]

        if not realmInfo.gained or type(realmInfo.gained) ~= "table" then
            realmInfo.gained = {}
        end

        if not realmInfo.spent or type(realmInfo.spent) ~= "table" then
            realmInfo.spent = {}
        end

        local playerInfo = db.realm[RealmName][PlayerName]

        if not playerInfo.gained or type(playerInfo.gained) ~= "table" then
            playerInfo.gained = {}
        end

        if not playerInfo.spent or type(playerInfo.spent) ~= "table" then
            playerInfo.spent = {}
        end

        UpdatePlayerAndLastCounts(CategoryCurrencyIDs, playerInfo)
        UpdatePlayerAndLastCounts(ExpansionCurrencyIDs, playerInfo)

        -- Initialize statistics
        self.last.money = GetMoney()
        self.lastTime = GetToday()

        local lastWeek = self.lastTime - 13

        for day in pairs(playerInfo.gained) do
            if day < lastWeek then
                playerInfo.gained[day] = nil
            end
        end

        for day in pairs(playerInfo.spent) do
            if day < lastWeek then
                playerInfo.spent[day] = nil
            end
        end

        for day in pairs(realmInfo.gained) do
            if day < lastWeek then
                realmInfo.gained[day] = nil
            end
        end

        for day in pairs(realmInfo.spent) do
            if day < lastWeek then
                realmInfo.spent[day] = nil
            end
        end

        for i = self.lastTime - 13, self.lastTime do
            if not playerInfo.gained[i] or type(playerInfo.gained[i]) ~= "table" then
                playerInfo.gained[i] = {
                    money = 0,
                }
            end

            if not playerInfo.spent[i] or type(playerInfo.spent[i]) ~= "table" then
                playerInfo.spent[i] = {
                    money = 0,
                }
            end

            if not realmInfo.gained[i] or type(realmInfo.gained[i]) ~= "table" then
                realmInfo.gained[i] = {
                    money = 0,
                }
            end

            if not realmInfo.spent[i] or type(realmInfo.spent[i]) ~= "table" then
                realmInfo.spent[i] = {
                    money = 0,
                }
            end
        end

        self.gained = {
            money = 0,
        }

        self.spent = {
            money = 0,
        }

        self.sessionTime = time()
        self.savedTime = time()

        -- Add settings for the various currencies
        AddGroupOptions("group", CategoryCurrencyGroups, CategoryGroupLabels, 1)
        AddGroupOptions("expansionGroup", ExpansionCurrencyGroups, ExpansionGroupLabels, 50)

        -- Provide settings options for tokenInfo
        local index = 1

        for playerName in pairs(db.realm[RealmName]) do
            AddDeleteOptions(playerName, db.realm[RealmName], index)

            index = index + 1
        end

        Broker_CurrencyDB = db
    end
end -- do-block
