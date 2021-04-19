--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local AddOnFolderName, private = ...

local LibStub = _G.LibStub
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")
local AceConfig = LibStub("AceConfig-3.0")

local Broker_Currency = _G.CreateFrame("frame", "Broker_CurrencyFrame")
_G["Broker_Currency"] = Broker_Currency

local CategoryCurrencyGroups = private.CategoryCurrencyGroups
local ExpansionCurrencyGroups = private.ExpansionCurrencyGroups

local CategoryCurrencyIDs = private.CategoryCurrencyIDs
local ExpansionCurrencyIDs = private.ExpansionCurrencyIDs
local IgnoredCurrencyIDs = private.IgnoredCurrencyIDs

local CurrencyID = private.CurrencyID
local CurrencyItemName = private.CurrencyItemName
local CurrencyName = private.CurrencyName

--------------------------------------------------------------------------------
---- Constants
--------------------------------------------------------------------------------
local CategoryGroupLabels = {
    _G.PROFESSIONS_ARCHAEOLOGY, -- Archaeology
    _G.BONUS_ROLL_TOOLTIP_TITLE, -- Bonus Loot
    _G.COLLECTIONS, -- Collections
    _G.CALENDAR_FILTER_HOLIDAYS, -- Holidays
    _G.PVP -- PvP
}

local ExpansionGroupLabels = {
    _G.EXPANSION_NAME1, -- The Burning Crusade
    _G.EXPANSION_NAME2, -- Wrath of the Lich King
    _G.EXPANSION_NAME3, -- Cataclysm
    _G.EXPANSION_NAME4, -- Mists of Pandaria
    _G.EXPANSION_NAME5, -- Warlords of Draenor
    _G.EXPANSION_NAME6, -- Legion
    _G.EXPANSION_NAME7, -- Battle for Azeroth
    _G.EXPANSION_NAME8 -- Shadowlands
}

local GoldIcon = "\124TInterface\\MoneyFrame\\UI-GoldIcon:20:20\124t"
local SilverIcon = "\124TInterface\\MoneyFrame\\UI-SilverIcon:20:20\124t"
local CopperIcon = "\124TInterface\\MoneyFrame\\UI-CopperIcon:20:20\124t"

local DisplayIconStringLeft = "%s \124T"
local DisplayIconStringRight = ":%d:%d\124t"

local fontWhite = _G.CreateFont("Broker_CurrencyFontWhite")
local fontPlus = _G.CreateFont("Broker_CurrencyFontPlus")
local fontMinus = _G.CreateFont("Broker_CurrencyFontMinus")
local fontLabel = _G.CreateFont("Broker_CurrencyFontLabel")

local PlayerName = _G.UnitName("player")
local RealmName = _G.GetRealmName()

local sToday = _G.HONOR_TODAY
local sYesterday = _G.HONOR_YESTERDAY
local sThisWeek = _G.ARENA_THIS_WEEK
local sLastWeek = _G.HONOR_LASTWEEK

local sPlus = "+"
local sMinus = "-"
local sTotal = "="

-- Populated as needed.
local CurrencyNameCache
local OptionIcons = {}
local BrokerIcons = {}

local CurrencyDescriptions = {}

local DatamineTooltip =
    _G.CreateFrame("GameTooltip", "Broker_CurrencyDatamineTooltip", _G.UIParent, "GameTooltipTemplate")
DatamineTooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")

--------------------------------------------------------------------------------
---- Variables
--------------------------------------------------------------------------------
local initializationTimerHandle
local playerLineIndex

--------------------------------------------------------------------------------
---- Helper Functions
--------------------------------------------------------------------------------
--[[
    Data is saved per realm/character in Broker_CurrencyDB
    Options are saved per character in Broker_CurrencyCharDB
    There are separate settings for display of the broker, and the summary display on the tooltip
]]
local sName, title, sNotes, enabled, loadable, reason, security = GetAddOnInfo("Broker_Currency")
local sName = GetAddOnMetadata("Broker_Currency", "X-BrokerName")

local function GetKey(currencyID, broker)
    return (broker and "show" or "summary") .. currencyID
end

local function ShowOptionIcon(currencyID)
    local iconSize = Broker_CurrencyCharDB.iconSize

    return string.format("\124T%s%s", OptionIcons[currencyID] or "", DisplayIconStringRight):format(iconSize, iconSize)
end

local function AddTooltipCurrencyLines(currencyIDList, currencyList, tooltipLine)
    for index = 1, #currencyIDList do
        local currencyID = currencyIDList[index]

        if BrokerIcons[currencyID] then
            local currencyCount = currencyList[currencyID] or 0

            if Broker_CurrencyCharDB[GetKey(currencyID, false)] then
                if currencyCount == 0 then
                    tooltipLine[#tooltipLine + 1] = " "
                else
                    tooltipLine[#tooltipLine + 1] = _G.BreakUpLargeNumbers(currencyCount)
                end
            end
        end
    end
end

local function AddTooltipHeaderColumns(currencyIDList, tooltipHeader)
    for currencyIndex = 1, #currencyIDList do
        local currencyID = currencyIDList[currencyIndex]

        if OptionIcons[currencyID] and Broker_CurrencyCharDB[GetKey(currencyID, false)] then
            tooltipHeader[#tooltipHeader + 1] = ShowOptionIcon(currencyID)
        end
    end
end

local tooltipBackdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = false,
    tileSize = 16,
    insets = {
        left = 0,
        right = 0,
        top = 2,
        bottom = 2
    }
}

local tooltipLines = {}
local tooltipLinesRecycle = {}
local tooltipAlignment = {}
local tooltipHeader = {}

local HeaderLabels = {
    [sToday] = true,
    [sYesterday] = true,
    [sThisWeek] = true,
    [sLastWeek] = true
}

function Broker_Currency:ShowTooltip(button)
    Broker_Currency:Update()

    local maxColumns = 0

    for _, rowList in pairs(tooltipLines) do
        local columns = 0

        for _ in pairs(rowList) do
            columns = columns + 1
        end

        maxColumns = math.max(maxColumns, columns)
    end

    if maxColumns <= 0 then
        return
    end

    local characterDB = Broker_CurrencyCharDB

    tooltipAlignment[1] = "LEFT"

    for index = 2, maxColumns + 1 do
        tooltipAlignment[index] = "RIGHT"
    end

    for index = #tooltipAlignment, maxColumns + 2, -1 do
        tooltipAlignment[index] = nil
    end

    table.wipe(tooltipHeader)
    tooltipHeader[1] = " "

    AddTooltipHeaderColumns(CategoryCurrencyIDs, tooltipHeader)
    AddTooltipHeaderColumns(ExpansionCurrencyIDs, tooltipHeader)

    if characterDB.summaryGold then
        tooltipHeader[#tooltipHeader + 1] = GoldIcon
    end

    if characterDB.summarySilver then
        tooltipHeader[#tooltipHeader + 1] = SilverIcon
    end

    if characterDB.summaryCopper then
        tooltipHeader[#tooltipHeader + 1] = CopperIcon
    end

    local tooltip = LibQTip:Acquire("Broker_CurrencyTooltip", maxColumns, unpack(tooltipAlignment))
    tooltip:SetCellMarginH(1)
    tooltip:SetCellMarginV(1)

    self.tooltip = tooltip

    local fontName, fontHeight, fontFlags = tooltip:GetFont():GetFont()

    fontPlus:SetFont(fontName, fontHeight, fontFlags)
    fontPlus:SetTextColor(0, 1, 0)
    fontPlus:SetJustifyH("RIGHT")
    fontPlus:SetJustifyV("MIDDLE")

    fontMinus:SetFont(fontName, fontHeight, fontFlags)
    fontMinus:SetTextColor(1, 0, 0)
    fontMinus:SetJustifyH("RIGHT")
    fontMinus:SetJustifyV("MIDDLE")

    fontWhite:SetFont(fontName, fontHeight, fontFlags)
    fontWhite:SetTextColor(1, 1, 1)
    fontWhite:SetJustifyH("RIGHT")
    fontWhite:SetJustifyV("MIDDLE")

    fontLabel:SetFont(fontName, fontHeight, fontFlags)
    fontLabel:SetTextColor(1, 1, 0.5)
    fontLabel:SetJustifyH("LEFT")
    fontLabel:SetJustifyV("MIDDLE")

    tooltip:AddHeader(unpack(tooltipHeader))
    tooltip:SetFont(fontWhite)

    for index, rowList in pairs(tooltipLines) do
        local label = rowList[1]
        local currentRow = index + 1

        if label == " " then
            tooltip:AddSeparator()
        elseif label == PlayerName or HeaderLabels[label] then
            tooltip:AddHeader(unpack(tooltipHeader))
            tooltip:SetCell(currentRow, 1, label, fontLabel)
        else
            tooltip:AddLine(unpack(rowList))

            if label == sPlus then
                for rowValueIndex, value in ipairs(rowList) do
                    tooltip:SetCell(currentRow, rowValueIndex, value, fontPlus)
                end
            elseif label == sMinus then
                for rowValueIndex, value in ipairs(rowList) do
                    tooltip:SetCell(currentRow, rowValueIndex, value, fontMinus)
                end
            elseif label == sTotal then
                for rowValueIndex, value in ipairs(rowList) do
                    if value and type(value) == "number" then
                        if value < 0 then
                            tooltip:SetCell(currentRow, rowValueIndex, -1 * _G.BreakUpLargeNumbers(value), fontMinus)
                        else
                            tooltip:SetCell(
                                currentRow,
                                rowValueIndex,
                                value == 0 and " " or _G.BreakUpLargeNumbers(value),
                                fontPlus
                            )
                        end
                    end
                end
            end

            if index == playerLineIndex then
                tooltip:SetLineColor(currentRow, 1, 1, 1, 0.25)
            end

            tooltip:SetCell(currentRow, 1, label, fontLabel)
        end
    end

    -- Color the even columns
    local summaryColorLight = characterDB.summaryColorLight

    if summaryColorLight.a > 0 then
        for index = 2, maxColumns, 2 do
            tooltip:SetColumnColor(
                index,
                summaryColorLight.r,
                summaryColorLight.g,
                summaryColorLight.b,
                summaryColorLight.a
            )
        end
    end

    local summaryColorDark = characterDB.summaryColorDark

    if _G.TipTac and _G.TipTac.AddModifiedTip then
        -- Pass true as second parameter because hooking OnHide causes C stack overflows
        _G.TipTac:AddModifiedTip(tooltip, true)
    elseif summaryColorDark.a > 0 then
        tooltip:SetBackdrop(tooltipBackdrop)
        tooltip:SetBackdropColor(summaryColorDark.r, summaryColorDark.g, summaryColorDark.b, summaryColorDark.a)
    end

    tooltip:SmartAnchorTo(button)
    tooltip:Show()
end

function Broker_Currency:AddLine(label, currencyList)
    local newIndex = #tooltipLines + 1

    if not tooltipLinesRecycle[newIndex] then
        tooltipLinesRecycle[newIndex] = {}
    end

    tooltipLines[newIndex] = tooltipLinesRecycle[newIndex]

    local tooltipLine = tooltipLines[newIndex]
    table.wipe(tooltipLine)

    tooltipLine[1] = label

    if not currencyList then
        return
    end

    AddTooltipCurrencyLines(CategoryCurrencyIDs, currencyList, tooltipLine)
    AddTooltipCurrencyLines(ExpansionCurrencyIDs, currencyList, tooltipLine)

    --------------------------------------------------------------------------------
    ---- Create Strings for gold, silver, copper
    --------------------------------------------------------------------------------
    local money = currencyList.money or 0
    local moneySign = (money < 0) and -1 or 1
    money = money * moneySign

    local copper = money % 100
    money = (money - copper) / 100

    local silver = money % 100
    local gold = math.floor(money / 100)

    gold = gold * moneySign
    silver = silver * moneySign
    copper = copper * moneySign

    local characterDB = Broker_CurrencyCharDB

    if gold + silver + copper ~= 0 then
        if characterDB.summaryGold then
            tooltipLine[#tooltipLine + 1] = _G.BreakUpLargeNumbers(gold)
        end

        if characterDB.summarySilver then
            tooltipLine[#tooltipLine + 1] = _G.BreakUpLargeNumbers(silver)
        end

        if characterDB.summaryCopper then
            tooltipLine[#tooltipLine + 1] = _G.BreakUpLargeNumbers(copper)
        end
    end
end

do
    local offset

    function Broker_Currency:GetServerOffset()
        if offset then
            return offset
        end

        local serverHour, serverMinute = _G.GetGameTime()
        local utcHour = tonumber(date("!%H"))
        local utcMinute = tonumber(date("!%M"))
        local ser = serverHour + serverMinute / 60
        local utc = utcHour + utcMinute / 60

        offset = math.floor((ser - utc) * 2 + 0.5) / 2

        if offset >= 12 then
            offset = offset - 24
        elseif offset < -12 then
            offset = offset + 24
        end

        return offset
    end
end

local function GetToday(self)
    return math.floor((time() / 60 / 60 + self:GetServerOffset()) / 24)
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
                        string.format(displayIcon, _G.BreakUpLargeNumbers(count), iconSize, iconSize)

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
            concatList[#concatList + 1] =
                string.format(
                GoldAmountTexture,
                _G.BreakUpLargeNumbers(gold),
                characterDB.iconSizeGold,
                characterDB.iconSizeGold
            )

            concatList[#concatList + 1] = " "
        end

        if characterDB.showSilver and gold + silver > 0 then
            concatList[#concatList + 1] =
                string.format(
                SilverAmountTexture,
                _G.BreakUpLargeNumbers(silver),
                characterDB.iconSizeGold,
                characterDB.iconSizeGold
            )

            concatList[#concatList + 1] = " "
        end

        if characterDB.showCopper and gold + silver + copper > 0 then
            concatList[#concatList + 1] =
                string.format(
                CopperAmountTexture,
                _G.BreakUpLargeNumbers(copper),
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

        return CurrencyItemName[currencyID] and _G.GetItemCount(currencyID, true) or
            _G.C_CurrencyInfo.GetCurrencyInfo(currencyID).quantity
    end
end

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

                    playerInfo.gained[today][currencyID] =
                        (playerInfo.gained[today][currencyID] or 0) + count - lastCount

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

function Broker_Currency:Update(event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:RegisterEvents()
    end

    if event == "PLAYER_LEAVING_WORLD" then
        self:UnregisterEvents()
        return
    end

    if self.InitializeSettings then
        self:InitializeSettings()
    end

    if event == "PLAYER_REGEN_ENABLED" then
        self:RegisterEvent("BAG_UPDATE", "Update")
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self:UnregisterEvent("BAG_UPDATE")
        return
    end

    if _G.GetMoney() == 0 then
        return
    end

    local realmInfo = Broker_CurrencyDB.realmInfo[RealmName]
    local playerInfo = Broker_CurrencyDB.realm[RealmName][PlayerName]
    local currentMoney = _G.GetMoney()

    -- Update the current player info
    playerInfo.money = currentMoney

    -- Update Statistics
    local today = GetToday(self)

    if not self.lastTime then
        self.lastTime = today
    end

    local cutoffDay = today - 14

    if today > self.lastTime then
        playerInfo.gained[cutoffDay] = nil
        playerInfo.spent[cutoffDay] = nil
        realmInfo.gained[cutoffDay] = nil
        realmInfo.spent[cutoffDay] = nil
        playerInfo.gained[today] = playerInfo.gained[today] or {money = 0}
        playerInfo.spent[today] = playerInfo.spent[today] or {money = 0}
        realmInfo.gained[today] = realmInfo.gained[today] or {money = 0}
        realmInfo.spent[today] = realmInfo.spent[today] or {money = 0}
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
    self.ldb.text = CreateMoneyString(playerInfo)

    self.savedTime = time()

    --------------------------------------------------------------------------------
    ---- If you want to send id numbers for currencies which are missing, /dump
    ---- these tables while in-game.
    --------------------------------------------------------------------------------
    _G.BROKER_CURRENCY_UNKNOWN = {}
    _G.BROKER_CURRENCY_UNKNOWN_FORMATTED = {}

    for currencyID = 1, 10000 do
        local currencyInfo = _G.C_CurrencyInfo.GetCurrencyInfo(currencyID)
        local formattedName = currencyInfo and currencyInfo.name:gsub(" ", ""):gsub("'", "") or nil

        if
            formattedName and formattedName ~= "" and not CurrencyName[currencyID] and
                not tContains(IgnoredCurrencyIDs, currencyID)
         then
            _G.BROKER_CURRENCY_UNKNOWN[currencyID] = formattedName
            _G.BROKER_CURRENCY_UNKNOWN_FORMATTED[formattedName] = currencyID
        end
    end
end

local Tooltip_AddTotals
do
    local function UpdateGainedAndSpent(currencyIDList, gained, gainedReference, spent, spentReference)
        for index = 1, #currencyIDList do
            local currencyID = currencyIDList[index]

            gainedReference[currencyID] =
                (gainedReference[currencyID] or 0) + (gained[index] and gained[index][currencyID] or 0)

            spentReference[currencyID] =
                (spentReference[currencyID] or 0) + (spent[index] and spent[index][currencyID] or 0)
        end
    end

    local function UpdateProfit(currencyIDList, profitTable, gainedReference, spentReference)
        for index = 1, #currencyIDList do
            local currencyID = currencyIDList[index]
            profitTable[currencyID] = (gainedReference[currencyID] or 0) - (spentReference[currencyID] or 0)
        end
    end

    local currencyGained = {}
    local currencySpent = {}
    local profitTable = {}

    function Tooltip_AddTotals(label, gained, spent, startTime, endTime)
        local gainedReference
        local spentReference

        table.wipe(profitTable)

        Broker_Currency:AddLine(" ")
        Broker_Currency:AddLine(label)
        Broker_Currency:AddLine(" ")

        if startTime and endTime then
            table.wipe(currencyGained)
            table.wipe(currencySpent)

            gainedReference = currencyGained
            spentReference = currencySpent

            for index = startTime, endTime do
                gainedReference.money = (gainedReference.money or 0) + (gained[index] and gained[index].money or 0)
                spentReference.money = (spentReference.money or 0) + (spent[index] and spent[index].money or 0)

                UpdateGainedAndSpent(CategoryCurrencyIDs, gained, gainedReference, spent, spentReference)
                UpdateGainedAndSpent(ExpansionCurrencyIDs, gained, gainedReference, spent, spentReference)
            end
        elseif startTime then
            gainedReference = gained[startTime]
            spentReference = spent[startTime]
        else
            gainedReference = gained
            spentReference = spent
        end

        UpdateProfit(CategoryCurrencyIDs, profitTable, gainedReference, spentReference)
        UpdateProfit(ExpansionCurrencyIDs, profitTable, gainedReference, spentReference)

        profitTable.money = (gainedReference.money or 0) - (spentReference.money or 0)

        Broker_Currency:AddLine(sPlus, gainedReference)
        Broker_Currency:AddLine(sMinus, spentReference)
        Broker_Currency:AddLine(sTotal, profitTable)
    end
end -- do-block

local OnEnter
do
    local totalList = {}
    local sortMoneyList = {}

    -- Sorting is in descending order of money
    local function SortByMoneyDescending(a, b)
        if a.player_info.money and b.player_info.money then
            return a.player_info.money > b.player_info.money
        elseif a.player_info.money then
            return true
        elseif b.player_info.money then
            return false
        else
            return true
        end
    end

    local function GetSortedPlayerInfo()
        local index = 1

        for playerName, playerInfo in pairs(Broker_CurrencyDB.realm[RealmName]) do
            if not sortMoneyList[index] then
                sortMoneyList[index] = {}
            end

            sortMoneyList[index].player_name = playerName
            sortMoneyList[index].player_info = playerInfo
            index = index + 1
        end

        for i = #sortMoneyList, index, -1 do
            sortMoneyList[i] = nil
        end

        table.sort(sortMoneyList, SortByMoneyDescending)

        return sortMoneyList
    end

    -- Handle mouse enter event in our button
    function OnEnter(button)
        if initializationTimerHandle then
            return
        end

        local self = Broker_Currency

        if Broker_Currency.InitializeSettings then
            Broker_Currency:InitializeSettings()
        end

        table.wipe(tooltipLines)

        -- Display the money string according to the summary settings
        table.wipe(totalList)

        local sortedPlayerInfo = GetSortedPlayerInfo()
        local charDB = Broker_CurrencyCharDB

        for i, data in ipairs(sortedPlayerInfo) do
            if data.player_name == PlayerName then
                playerLineIndex = i
            end

            Broker_Currency:AddLine(string.format("%s: ", data.player_name), data.player_info, fontWhite)

            -- Add counts from player_info to totalList according to the summary settings this character is interested in
            for summaryName in pairs(charDB) do
                local countKey = tonumber(string.match(summaryName, "summary(%d+)"))
                local count = data.player_info[countKey]

                if count then
                    totalList[countKey] = (totalList[countKey] or 0) + count
                end
            end

            totalList.money = (totalList.money or 0) + (data.player_info.money or 0)
        end

        Broker_Currency:AddLine(" ")

        -- Statistics
        -- Session totals
        local gained = self.gained
        local spent = self.spent

        if charDB.summaryPlayerSession then
            Tooltip_AddTotals(PlayerName, gained, spent, nil, nil)
        end

        -- Today totals
        local realmInfo = Broker_CurrencyDB.realmInfo[RealmName]
        gained = realmInfo.gained
        spent = realmInfo.spent

        if charDB.summaryRealmToday then
            Tooltip_AddTotals(sToday, gained, spent, self.lastTime, nil)
        end

        -- Yesterday totals
        if charDB.summaryRealmYesterday then
            Tooltip_AddTotals(sYesterday, gained, spent, self.lastTime - 1, nil)
        end

        -- This Week totals
        if charDB.summaryRealmThisWeek then
            Tooltip_AddTotals(sThisWeek, gained, spent, self.lastTime - 6, self.lastTime)
        end

        -- Last Week totals
        if charDB.summaryRealmLastWeek then
            Tooltip_AddTotals(sLastWeek, gained, spent, self.lastTime - 13, self.lastTime - 7)
        end

        -- Totals
        Broker_Currency:AddLine(" ")
        Broker_Currency:AddLine(_G.ACHIEVEMENT_SUMMARY_CATEGORY, totalList)

        Broker_Currency:ShowTooltip(button)
    end
end -- do-block

local function OnLeave()
    LibQTip:Release(Broker_Currency.tooltip)
    Broker_Currency.tooltip = nil
end

-- Set up as a LibBroker data source
Broker_Currency.ldb =
    LDB:NewDataObject(
    "Broker Currency",
    {
        type = "data source",
        label = _G.CURRENCY,
        icon = "Interface\\MoneyFrame\\UI-GoldIcon",
        text = "Initializing...",
        OnClick = function(_, button)
            if button == "RightButton" then
                _G.InterfaceOptionsFrame_OpenToCategory(Broker_Currency.menu)
            end
        end,
        OnEnter = OnEnter,
        OnLeave = OnLeave
    }
)

do
    --------------------------------------------------------------------------------
    ---- Constants
    --------------------------------------------------------------------------------
    local wtfDelay = 5 -- For stupid cases where Blizzard pretends a player has no loots, wait up to 15 seconds
    local iconToken =
        DisplayIconStringLeft ..
        _G.C_CurrencyInfo.GetCurrencyInfo(CurrencyID.CuriousCoin).iconFileID .. DisplayIconStringRight

    local metadataVersion = GetAddOnMetadata("Broker_Currency", "Version")
    local IsDevelopmentVersion = false
    local IsAlphaVersion = false

    --@debug@
    IsDevelopmentVersion = true
    --@end-debug@

    --@alpha@
    IsAlphaVersion = true
    --@end-alpha@

    local BuildVersion =
        IsDevelopmentVersion and "Development Version" or (IsAlphaVersion and metadataVersion .. "-Alpha") or
        metadataVersion

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
            desc = CurrencyDescriptions[currencyID],
            order = displayOrder,
            type = "toggle",
            width = "full",
            get = function()
                return Broker_CurrencyCharDB[sectionName]
            end,
            set = function(_, value)
                Broker_CurrencyCharDB[sectionName] = true and value or nil
                Broker_Currency:Update()
            end
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
                args = {}
            }

            summaryDisplay[optionGroupName] = {
                name = groupLabels[groupListIndex],
                order = groupListIndex + offset,
                type = "group",
                args = {}
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
        local deleteOptions = Broker_Currency.deleteCharacter.args

        deleteOptions[playerName] = nil
        deleteOptions[playerName .. "Name"] = nil
        deleteOptions[playerName .. "Spacer"] = nil
        Broker_CurrencyDB.realm[RealmName][playerName] = nil
    end

    local function AddDeleteOptions(playerName, playerInfoList, index)
        local deleteOptions = Broker_Currency.deleteCharacter.args

        if not deleteOptions[playerName] then
            deleteOptions[playerName .. "Name"] = {
                order = index * 3,
                type = "description",
                width = "half",
                name = playerName,
                fontSize = "medium"
            }

            deleteOptions[playerName] = {
                order = index * 3 + 1,
                type = "execute",
                width = "half",
                name = _G.DELETE,
                desc = playerName,
                func = DeletePlayer
            }

            deleteOptions[playerName .. "Spacer"] = {
                order = index * 3 + 2,
                type = "description",
                width = "full",
                name = ""
            }
        end
    end

    local function SetCacheValuesFromCurrency(currencyID)
        local currencyInfo = _G.C_CurrencyInfo.GetCurrencyInfo(currencyID)
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
        local _, _, _, _, iconFileDataID = _G.GetItemInfoInstant(currencyID)

        if iconFileDataID and iconFileDataID ~= "" then
            local itemName = _G.GetItemInfo(currencyID)

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
    function Broker_Currency:InitializeSettings()
        for _, currencyID in pairs(CurrencyID) do
            DatamineTooltip:SetCurrencyTokenByID(currencyID)

            CurrencyDescriptions[currencyID] = _G["Broker_CurrencyDatamineTooltipTextLeft2"]:GetText()
        end

        -- No money means trouble
        if initializationTimerHandle then
            self:CancelTimer(initializationTimerHandle)
            initializationTimerHandle = nil
        end

        if _G.GetMoney() == 0 then
            if wtfDelay > 0 then
                initializationTimerHandle = self:ScheduleTimer(self.InitializeSettings, wtfDelay, self)
                wtfDelay = wtfDelay - 1
                return
            end
        end

        --------------------------------------------------------------------------------
        ---- Set Defaults
        --------------------------------------------------------------------------------
        Broker_CurrencyCharDB =
            Broker_CurrencyCharDB or
            {
                showCopper = true,
                showSilver = true,
                showGold = true,
                showToday = true,
                showYesterday = true,
                showLastWeek = true,
                summaryGold = true,
                summaryColorDark = {r = 0, g = 0, b = 0, a = 0},
                summaryColorLight = {r = 1, g = 1, b = 1, a = .3}
            }

        --------------------------------------------------------------------------------
        ---- Configuration Options
        --------------------------------------------------------------------------------
        Broker_Currency.options = {
            name = ("%s - %s"):format(AddOnFolderName, BuildVersion),
            type = "group",
            childGroups = "tab",
            get = function(info)
                return Broker_CurrencyCharDB[info[#info]]
            end,
            set = function(info, value)
                Broker_CurrencyCharDB[info[#info]] = true and value or nil
                Broker_Currency:Update()
            end,
            args = {
                brokerDisplay = {
                    name = _G.DISPLAY,
                    order = 1,
                    type = "group",
                    args = {
                        money = {
                            name = _G.MONEY,
                            order = 1,
                            type = "group",
                            args = {
                                showGold = {
                                    name = ("%s %s"):format(GoldIcon, _G.GOLD_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 1,
                                    type = "toggle",
                                    width = "full"
                                },
                                showSilver = {
                                    name = ("%s %s"):format(SilverIcon, _G.SILVER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 2,
                                    type = "toggle",
                                    width = "full"
                                },
                                showCopper = {
                                    name = ("%s %s"):format(CopperIcon, _G.COPPER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 3,
                                    type = "toggle",
                                    width = "full"
                                }
                            }
                        }
                    }
                },
                summaryDisplay = {
                    type = "group",
                    name = _G.ACHIEVEMENT_SUMMARY_CATEGORY,
                    order = 2,
                    args = {
                        money = {
                            name = _G.MONEY,
                            order = 1,
                            type = "group",
                            args = {
                                summaryGold = {
                                    name = ("%s %s"):format(GoldIcon, _G.GOLD_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 1,
                                    type = "toggle",
                                    width = "full"
                                },
                                summarySilver = {
                                    name = ("%s %s"):format(SilverIcon, _G.SILVER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 2,
                                    type = "toggle",
                                    width = "full"
                                },
                                summaryCopper = {
                                    name = ("%s %s"):format(CopperIcon, _G.COPPER_AMOUNT:gsub("%%d", ""):gsub(" ", "")),
                                    order = 3,
                                    type = "toggle",
                                    width = "full"
                                }
                            }
                        }
                    }
                }
            }
        }

        AceConfig:RegisterOptionsTable(AddOnFolderName, Broker_Currency.options)
        Broker_Currency.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(AddOnFolderName)

        Broker_Currency.deleteCharacter = {
            name = _G.CHARACTER,
            type = "group",
            args = {}
        }

        AceConfig:RegisterOptionsTable("Broker_Currency_Character", Broker_Currency.deleteCharacter)

        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Broker_Currency_Character", _G.CHARACTER, AddOnFolderName)

        Broker_Currency.generalSettings = {
            name = _G.GENERAL,
            type = "group",
            get = function(info)
                return Broker_CurrencyCharDB[info[#info]]
            end,
            set = function(info, value)
                Broker_CurrencyCharDB[info[#info]] = true and value or nil
                Broker_Currency:Update()
            end,
            args = {
                iconSize = {
                    type = "range",
                    order = 10,
                    name = string.format(iconToken, 8, 16, 16),
                    desc = _G.TOKENS,
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
                        Broker_Currency.generalSettings.args.iconSize.name = iconToken:format(8, iconSize, iconSize)
                        Broker_Currency:Update()
                    end
                },
                iconSizeGold = {
                    type = "range",
                    order = 10,
                    name = string.format(_G.GOLD_AMOUNT_TEXTURE, 8, 16, 16),
                    desc = _G.MONEY,
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
                        Broker_Currency.generalSettings.args.iconSizeGold.name =
                            _G.GOLD_AMOUNT_TEXTURE:format(8, iconSize, iconSize)
                        Broker_Currency:Update()
                    end
                },
                color_header = {
                    order = 100,
                    type = "header",
                    name = _G.COLOR
                },
                summaryColorDark = {
                    type = "color",
                    name = _G.BACKGROUND,
                    order = 101,
                    get = getColorValue,
                    set = setColorValue,
                    hasAlpha = true
                },
                summaryColorLight = {
                    type = "color",
                    name = _G.HIGHLIGHTING,
                    order = 102,
                    get = getColorValue,
                    set = setColorValue,
                    hasAlpha = true
                },
                statistics_header = {
                    order = 200,
                    type = "header",
                    name = _G.STATISTICS
                },
                summaryPlayerSession = {
                    type = "toggle",
                    name = PlayerName,
                    order = 201
                },
                summaryRealmToday = {
                    type = "toggle",
                    name = sToday,
                    order = 202
                },
                summaryRealmYesterday = {
                    type = "toggle",
                    name = sYesterday,
                    order = 203
                },
                summaryRealmThisWeek = {
                    type = "toggle",
                    name = sThisWeek,
                    order = 204
                },
                summaryRealmLastWeek = {
                    type = "toggle",
                    name = sLastWeek,
                    order = 205
                }
            }
        }

        AceConfig:RegisterOptionsTable("Broker_Currency_General", Broker_Currency.generalSettings)

        LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Broker_Currency_General", _G.GENERAL, AddOnFolderName)

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
            characterDB.summaryColorDark = {r = 0, g = 0, b = 0, a = 0}
        end

        if not characterDB.summaryColorLight then
            characterDB.summaryColorLight = {r = 1, g = 1, b = 1, a = .3}
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

        if not self.last then
            self.last = {}
        end

        UpdatePlayerAndLastCounts(CategoryCurrencyIDs, playerInfo)
        UpdatePlayerAndLastCounts(ExpansionCurrencyIDs, playerInfo)

        -- Initialize statistics
        self.last.money = _G.GetMoney()
        self.lastTime = GetToday(self)

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
                    money = 0
                }
            end

            if not playerInfo.spent[i] or type(playerInfo.spent[i]) ~= "table" then
                playerInfo.spent[i] = {
                    money = 0
                }
            end

            if not realmInfo.gained[i] or type(realmInfo.gained[i]) ~= "table" then
                realmInfo.gained[i] = {
                    money = 0
                }
            end

            if not realmInfo.spent[i] or type(realmInfo.spent[i]) ~= "table" then
                realmInfo.spent[i] = {
                    money = 0
                }
            end
        end

        self.gained = {
            money = 0
        }

        self.spent = {
            money = 0
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

        self:UnregisterEvent("BAG_UPDATE")

        if initializationTimerHandle then
            self:CancelTimer(initializationTimerHandle)
            initializationTimerHandle = nil
        end

        -- Register for update events
        self:RegisterEvents()

        self:RegisterEvent("PLAYER_ENTERING_WORLD", "Update")
        self:RegisterEvent("PLAYER_LEAVING_WORLD", "Update")

        -- Done initializing
        self:SetScript("OnEvent", Broker_Currency.Update)
        self.InitializeSettings = nil

        self:Update()
    end
end -- do-block

local UpdateEventNames = {
    "CURRENCY_DISPLAY_UPDATE",
    "MERCHANT_CLOSED",
    "PLAYER_MONEY",
    "PLAYER_TRADE_MONEY",
    "TRADE_MONEY_CHANGED",
    "SEND_MAIL_MONEY_CHANGED",
    "SEND_MAIL_COD_CHANGED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED",
    "BAG_UPDATE"
}

function Broker_Currency:RegisterEvents()
    for index = 1, #UpdateEventNames do
        self:RegisterEvent(UpdateEventNames[index], "Update")
    end
end

function Broker_Currency:UnregisterEvents()
    for index = 1, #UpdateEventNames do
        self:UnregisterEvent(UpdateEventNames[index])
    end
end

function Broker_Currency:Startup(event, ...)
    if event == "BAG_UPDATE" then
        if initializationTimerHandle then
            self:CancelTimer(initializationTimerHandle)
        end

        initializationTimerHandle = self:ScheduleTimer(self.InitializeSettings, 4, self)
    end
end

-- Initialize after end of BAG_UPDATE events
Broker_Currency:RegisterEvent("BAG_UPDATE")
Broker_Currency:RegisterEvent("PLAYER_MONEY")
Broker_Currency:SetScript("OnEvent", Broker_Currency.Startup)

LibStub("AceTimer-3.0"):Embed(Broker_Currency)

-- This is only necessary if AddonLoader is present, using the Delayed load. -Torhal
if IsLoggedIn() then
    initializationTimerHandle = Broker_Currency:ScheduleTimer(Broker_Currency.InitializeSettings, 1, Broker_Currency)
end
