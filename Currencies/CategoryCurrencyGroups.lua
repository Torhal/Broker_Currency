--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local _, private = ...

local CurrencyID = private.CurrencyID
local CurrencyItemID = private.CurrencyItemID

--------------------------------------------------------------------------------
---- Definitions
--------------------------------------------------------------------------------
local CategoryCurrencyGroups = {
    --------------------------------------------------------------------------------
    ---- Archaeology
    --------------------------------------------------------------------------------
    {
        CurrencyID.ArakkoaArchaelogoyFragment,
        CurrencyID.DemonicArchaeologyFragment,
        CurrencyID.DraeneiArchaeologyFragment,
        CurrencyID.DraenorClansArchaeologyFragment,
        CurrencyID.DrustArchaeologyFragment,
        CurrencyID.DwarfArchaeologyFragment,
        CurrencyID.FossilArchaeologyFragment,
        CurrencyID.HighborneArchaeologyFragment,
        CurrencyID.HighmountainTaurenArchaeologyFragment,
        CurrencyID.MantidArchaeologyFragment,
        CurrencyID.MoguArchaeologyFragment,
        CurrencyID.NerubianArchaeologyFragment,
        CurrencyID.NightelfArchaeologyFragment,
        CurrencyID.OgreArchaeoogyFragment,
        CurrencyID.OrcArchaeologyFragment,
        CurrencyID.PandarenArchaeologyFragment,
        CurrencyID.TolvirArchaeologyFragment,
        CurrencyID.TrollArchaeologyFragment,
        CurrencyID.VrykulArchaeologyFragment,
        CurrencyID.ZandalariArchaeologyFragment,
    },
    -------------------------------------------------------------------------------
    ---- Bonus Loot
    -------------------------------------------------------------------------------
    {
        CurrencyID.ElderCharmOfGoodFortune,
        CurrencyID.LesserCharmOfGoodFortune,
        CurrencyID.MoguRuneOfFate,
        CurrencyID.SealOfBrokenFate,
        CurrencyID.SealOfInevitableFate,
        CurrencyID.SealOfTemperedFate,
        CurrencyID.SealOfWartornFate,
        CurrencyID.WarforgedSeal,
    },
    -------------------------------------------------------------------------------
    ---- Collections
    -------------------------------------------------------------------------------
    {
        CurrencyItemID.PolishedPetCharm,
        CurrencyItemID.ShinyPetCharm,
    },
    -------------------------------------------------------------------------------
    ---- Dungeons
    -------------------------------------------------------------------------------
    {
        CurrencyID.JusticePoints,
        CurrencyID.ValorPoints,
    },
    -------------------------------------------------------------------------------
    ---- Holidays
    -------------------------------------------------------------------------------
    {
        CurrencyItemID.BrewfestPrizeToken,
        CurrencyItemID.CoinOfAncestry,
        CurrencyID.DarkmoonPrizeTicket,
        CurrencyItemID.LoveToken,
        CurrencyID.TrialOfStyleToken,
    },
    --------------------------------------------------------------------------------
    ----  PvP
    --------------------------------------------------------------------------------
    {
        CurrencyID.ArtifactFragment,
        CurrencyID.BloodyCoin,
        CurrencyID.Conquest,
        CurrencyID.ConquestPoints,
        CurrencyID.EchoesOfBattle,
        CurrencyID.EchoesOfDomination,
        CurrencyItemID.HalaaBattleToken,
        CurrencyItemID.HalaaResearchToken,
        CurrencyID.Honor,
        CurrencyID.HonorPoints,
        CurrencyID.SightlessEye,
        CurrencyID.SpiritShard,
        CurrencyID.TolBaradCommendation,
        CurrencyID.BloodyTokens,
    },
}

private.CategoryCurrencyGroups = CategoryCurrencyGroups

local CategoryCurrencyIDs = {}
private.CategoryCurrencyIDs = CategoryCurrencyIDs

for groupIndex = 1, #CategoryCurrencyGroups do
    local group = CategoryCurrencyGroups[groupIndex]

    for idIndex = 1, #group do
        CategoryCurrencyIDs[#CategoryCurrencyIDs + 1] = group[idIndex]
    end
end
