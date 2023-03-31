--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local AddOnFolderName, private = ...

local LibStub = _G.LibStub

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibQTip = LibStub("LibQTip-1.0")

---@class Broker_Currency
local Broker_Currency = LibStub("AceAddon-3.0"):GetAddon(AddOnFolderName)

local CategoryCurrencyIDs = private.CategoryCurrencyIDs
local ExpansionCurrencyIDs = private.ExpansionCurrencyIDs

local GetKey = private.GetKey
local ShowOptionIcon = private.ShowOptionIcon
local UpdateCurrencyDescriptions = private.UpdateCurrencyDescriptions

local GoldIcon = private.GoldIcon
local SilverIcon = private.SilverIcon
local CopperIcon = private.CopperIcon

local TodayLabel = private.TodayLabel
local YesterdayLabel = private.YesterdayLabel
local ThisWeekLabel = private.ThisWeekLabel
local LastWeekLabel = private.LastWeekLabel

--------------------------------------------------------------------------------
---- Constants
--------------------------------------------------------------------------------
local PlayerName = _G.UnitName("player")
local RealmName = _G.GetRealmName()

local FontWhite = _G.CreateFont("Broker_CurrencyFontWhite")
local FontPlus = _G.CreateFont("Broker_CurrencyFontPlus")
local FontMinus = _G.CreateFont("Broker_CurrencyFontMinus")
local FontLabel = _G.CreateFont("Broker_CurrencyFontLabel")

local PlusToken = "+"
local MinusToken = "-"
local TotalToken = "="

local CurrencyGained = {}
local CurrencySpent = {}
local ProfitTable = {}
local SortMoneyList = {}
local TotalList = {}

local TooltipLines = {}
local TooltipLinesRecycle = {}
local TooltipAlignment = {}
local TooltipHeader = {}

local HeaderLabels = {
    [TodayLabel] = true,
    [YesterdayLabel] = true,
    [ThisWeekLabel] = true,
    [LastWeekLabel] = true
}

local DataObject =
    LibDataBroker:NewDataObject(
    AddOnFolderName,
    {
        icon = [[Interface\MoneyFrame\UI-GoldIcon]],
        label = _G.CURRENCY,
        text = _G.SEARCH_LOADING_TEXT, -- Loading...
        type = "data source"
    }
)

private.DataObject = DataObject

--------------------------------------------------------------------------------
---- Variables
--------------------------------------------------------------------------------
local playerLineIndex

--------------------------------------------------------------------------------
---- Helper Functions
--------------------------------------------------------------------------------
local function AddTooltipCurrencyLines(currencyIDList, currencyList, tooltipLine)
    for index = 1, #currencyIDList do
        local currencyID = currencyIDList[index]

        if private.BrokerIcons[currencyID] then
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

        if private.OptionIcons[currencyID] and Broker_CurrencyCharDB[GetKey(currencyID, false)] then
            tooltipHeader[#tooltipHeader + 1] = ShowOptionIcon(currencyID)
        end
    end
end

local function SortByMoneyDescending(a, b)
    if a.player_info.money and b.player_info.money then
        return a.player_info.money > b.player_info.money
    end

    if a.player_info.money then
        return true
    end

    if b.player_info.money then
        return false
    end

    return true
end

local function GetSortedPlayerInfo()
    local index = 1

    for playerName, playerInfo in pairs(Broker_CurrencyDB.realm[RealmName]) do
        if not SortMoneyList[index] then
            SortMoneyList[index] = {}
        end

        SortMoneyList[index].player_name = playerName
        SortMoneyList[index].player_info = playerInfo
        index = index + 1
    end

    for i = #SortMoneyList, index, -1 do
        SortMoneyList[i] = nil
    end

    table.sort(SortMoneyList, SortByMoneyDescending)

    return SortMoneyList
end

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

local function AddTooltipTotalsLines(label, gained, spent, startTime, endTime)
    local gainedReference
    local spentReference

    table.wipe(ProfitTable)

    Broker_Currency:AddLine(" ")
    Broker_Currency:AddLine(label)
    Broker_Currency:AddLine(" ")

    if startTime and endTime then
        table.wipe(CurrencyGained)
        table.wipe(CurrencySpent)

        gainedReference = CurrencyGained
        spentReference = CurrencySpent

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

    UpdateProfit(CategoryCurrencyIDs, ProfitTable, gainedReference, spentReference)
    UpdateProfit(ExpansionCurrencyIDs, ProfitTable, gainedReference, spentReference)

    ProfitTable.money = (gainedReference.money or 0) - (spentReference.money or 0)

    Broker_Currency:AddLine(PlusToken, gainedReference)
    Broker_Currency:AddLine(MinusToken, spentReference)
    Broker_Currency:AddLine(TotalToken, ProfitTable)
end

--------------------------------------------------------------------------------
---- DataObject Methods
--------------------------------------------------------------------------------
function DataObject:OnClick(button)
    if button == "RightButton" then
        UpdateCurrencyDescriptions()

        AceConfigDialog:Open(AddOnFolderName)
    end
end

function DataObject:OnEnter()
    table.wipe(TooltipLines)
    table.wipe(TotalList)

    local sortedPlayerInfo = GetSortedPlayerInfo()
    local charDB = Broker_CurrencyCharDB

    for i, data in ipairs(sortedPlayerInfo) do
        if data.player_name == PlayerName then
            playerLineIndex = i
        end

        Broker_Currency:AddLine(string.format("%s: ", data.player_name), data.player_info)

        -- Add counts from player_info to totalList according to the summary settings this character is interested in
        for summaryName in pairs(charDB) do
            local countKey = tonumber(string.match(summaryName, "summary(%d+)"))
            local count = data.player_info[countKey]

            if count then
                TotalList[countKey] = (TotalList[countKey] or 0) + count
            end
        end

        TotalList.money = (TotalList.money or 0) + (data.player_info.money or 0)
    end

    Broker_Currency:AddLine(" ")

    --------------------------------------------------------------------------------
    ---- Statistics
    --------------------------------------------------------------------------------
    -- Session totals
    local gained = Broker_Currency.gained
    local spent = Broker_Currency.spent

    if charDB.summaryPlayerSession then
        AddTooltipTotalsLines(PlayerName, gained, spent, nil, nil)
    end

    -- Today totals
    local realmInfo = Broker_CurrencyDB.realmInfo[RealmName]
    gained = realmInfo.gained
    spent = realmInfo.spent

    if charDB.summaryRealmToday then
        AddTooltipTotalsLines(TodayLabel, gained, spent, Broker_Currency.lastTime, nil)
    end

    -- Yesterday totals
    if charDB.summaryRealmYesterday then
        AddTooltipTotalsLines(YesterdayLabel, gained, spent, Broker_Currency.lastTime - 1, nil)
    end

    -- This Week totals
    if charDB.summaryRealmThisWeek then
        AddTooltipTotalsLines(ThisWeekLabel, gained, spent, Broker_Currency.lastTime - 6, Broker_Currency.lastTime)
    end

    -- Last Week totals
    if charDB.summaryRealmLastWeek then
        AddTooltipTotalsLines(LastWeekLabel, gained, spent, Broker_Currency.lastTime - 13, Broker_Currency.lastTime - 7)
    end

    -- Totals
    Broker_Currency:AddLine(" ")
    Broker_Currency:AddLine(_G.ACHIEVEMENT_SUMMARY_CATEGORY, TotalList)

    Broker_Currency:ShowTooltip(self)
end

function DataObject:OnLeave()
    LibQTip:Release(Broker_Currency.tooltip)

    Broker_Currency.tooltip = nil
end

--------------------------------------------------------------------------------
---- Broker_Currency Tooltip Methods
--------------------------------------------------------------------------------
function Broker_Currency:ShowTooltip(button)
    Broker_Currency:Update()

    local maxColumns = 0

    for _, rowList in pairs(TooltipLines) do
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

    TooltipAlignment[1] = "LEFT"

    for index = 2, maxColumns + 1 do
        TooltipAlignment[index] = "RIGHT"
    end

    for index = #TooltipAlignment, maxColumns + 2, -1 do
        TooltipAlignment[index] = nil
    end

    table.wipe(TooltipHeader)
    TooltipHeader[1] = " "

    AddTooltipHeaderColumns(CategoryCurrencyIDs, TooltipHeader)
    AddTooltipHeaderColumns(ExpansionCurrencyIDs, TooltipHeader)

    if characterDB.summaryGold then
        TooltipHeader[#TooltipHeader + 1] = GoldIcon
    end

    if characterDB.summarySilver then
        TooltipHeader[#TooltipHeader + 1] = SilverIcon
    end

    if characterDB.summaryCopper then
        TooltipHeader[#TooltipHeader + 1] = CopperIcon
    end

    local tooltip = LibQTip:Acquire("Broker_CurrencyTooltip", maxColumns, unpack(TooltipAlignment))
    tooltip:SetCellMarginH(1)
    tooltip:SetCellMarginV(1)

    self.tooltip = tooltip

    local fontName, fontHeight, fontFlags = tooltip:GetFont():GetFont()

    FontPlus:SetFont(fontName, fontHeight, fontFlags)
    FontPlus:SetTextColor(0, 1, 0)
    FontPlus:SetJustifyH("RIGHT")
    FontPlus:SetJustifyV("MIDDLE")

    FontMinus:SetFont(fontName, fontHeight, fontFlags)
    FontMinus:SetTextColor(1, 0, 0)
    FontMinus:SetJustifyH("RIGHT")
    FontMinus:SetJustifyV("MIDDLE")

    FontWhite:SetFont(fontName, fontHeight, fontFlags)
    FontWhite:SetTextColor(1, 1, 1)
    FontWhite:SetJustifyH("RIGHT")
    FontWhite:SetJustifyV("MIDDLE")

    FontLabel:SetFont(fontName, fontHeight, fontFlags)
    FontLabel:SetTextColor(1, 1, 0.5)
    FontLabel:SetJustifyH("LEFT")
    FontLabel:SetJustifyV("MIDDLE")

    tooltip:AddHeader(unpack(TooltipHeader))
    tooltip:SetFont(FontWhite)

    for index, rowList in pairs(TooltipLines) do
        local label = rowList[1]
        local currentRow = index + 1

        if label == " " then
            tooltip:AddSeparator()
        elseif label == PlayerName or HeaderLabels[label] then
            tooltip:AddHeader(unpack(TooltipHeader))
            tooltip:SetCell(currentRow, 1, label, FontLabel)
        else
            tooltip:AddLine(unpack(rowList))

            if label == PlusToken then
                for rowValueIndex, value in ipairs(rowList) do
                    tooltip:SetCell(currentRow, rowValueIndex, value, FontPlus)
                end
            elseif label == MinusToken then
                for rowValueIndex, value in ipairs(rowList) do
                    tooltip:SetCell(currentRow, rowValueIndex, value, FontMinus)
                end
            elseif label == TotalToken then
                for rowValueIndex, value in ipairs(rowList) do
                    if value and type(value) == "number" then
                        if value < 0 then
                            tooltip:SetCell(currentRow, rowValueIndex, -1 * _G.BreakUpLargeNumbers(value), FontMinus)
                        else
                            tooltip:SetCell(
                                currentRow,
                                rowValueIndex,
                                value == 0 and " " or _G.BreakUpLargeNumbers(value),
                                FontPlus
                            )
                        end
                    end
                end
            end

            if index == playerLineIndex then
                tooltip:SetLineColor(currentRow, 1, 1, 1, 0.25)
            end

            tooltip:SetCell(currentRow, 1, label, FontLabel)
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

    if summaryColorDark.a > 0 then
        tooltip.NineSlice:SetCenterColor(summaryColorDark.r, summaryColorDark.g, summaryColorDark.b, summaryColorDark.a)
    end

    tooltip:SmartAnchorTo(button)
    tooltip:Show()
end

function Broker_Currency:AddLine(label, currencyList)
    local newIndex = #TooltipLines + 1

    if not TooltipLinesRecycle[newIndex] then
        TooltipLinesRecycle[newIndex] = {}
    end

    TooltipLines[newIndex] = TooltipLinesRecycle[newIndex]

    local tooltipLine = TooltipLines[newIndex]
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
