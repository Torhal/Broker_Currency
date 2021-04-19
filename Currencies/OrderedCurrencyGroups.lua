--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local _, private = ...

local CurrencyIDByName = private.CurrencyIDByName
local ItemCurrencyIDByName = private.ItemCurrencyIDByName

--------------------------------------------------------------------------------
---- Definitions
--------------------------------------------------------------------------------
local OrderedCurrencyGroups = {
    --------------------------------------------------------------------------------
    ---- Archaeology
    --------------------------------------------------------------------------------
    {
        CurrencyIDByName.ArakkoaArchaelogoyFragment,
        CurrencyIDByName.DemonicArchaeologyFragment,
        CurrencyIDByName.DraeneiArchaeologyFragment,
        CurrencyIDByName.DraenorClansArchaeologyFragment,
        CurrencyIDByName.DrustArchaeologyFragment,
        CurrencyIDByName.DwarfArchaeologyFragment,
        CurrencyIDByName.FossilArchaeologyFragment,
        CurrencyIDByName.HighborneArchaeologyFragment,
        CurrencyIDByName.HighmountainTaurenArchaeologyFragment,
        CurrencyIDByName.MantidArchaeologyFragment,
        CurrencyIDByName.MoguArchaeologyFragment,
        CurrencyIDByName.NerubianArchaeologyFragment,
        CurrencyIDByName.NightelfArchaeologyFragment,
        CurrencyIDByName.OgreArchaeoogyFragment,
        CurrencyIDByName.OrcArchaeologyFragment,
        CurrencyIDByName.PandarenArchaeologyFragment,
        CurrencyIDByName.TolvirArchaeologyFragment,
        CurrencyIDByName.TrollArchaeologyFragment,
        CurrencyIDByName.VrykulArchaeologyFragment,
        CurrencyIDByName.ZandalariArchaeologyFragment
    },
    -------------------------------------------------------------------------------
    ---- Bonus Rolls
    -------------------------------------------------------------------------------
    {
        CurrencyIDByName.ElderCharmOfGoodFortune,
        CurrencyIDByName.LesserCharmOfGoodFortune,
        CurrencyIDByName.MoguRuneOfFate,
        CurrencyIDByName.SealOfBrokenFate,
        CurrencyIDByName.SealOfInevitableFate,
        CurrencyIDByName.SealOfTemperedFate,
        CurrencyIDByName.SealOfWartornFate,
        CurrencyIDByName.WarforgedSeal
    },
    -------------------------------------------------------------------------------
    ---- Collections
    -------------------------------------------------------------------------------
    {
        CurrencyIDByName.GratefulOffering,
        CurrencyIDByName.InfusedRuby,
        CurrencyIDByName.ReservoirAnima
    },
    -------------------------------------------------------------------------------
    ---- Dungeons
    -------------------------------------------------------------------------------
    {
        CurrencyIDByName.EssenceOfCorruptedDeathwing,
        CurrencyIDByName.MoteOfDarkness,
        CurrencyIDByName.SoulAsh,
        CurrencyIDByName.TimewarpedBadge,
        CurrencyIDByName.Valor
    },
    -------------------------------------------------------------------------------
    ---- Items
    -------------------------------------------------------------------------------
    {
        ItemCurrencyIDByName.ApexisCrystal,
        ItemCurrencyIDByName.ApexisShard,
        ItemCurrencyIDByName.BlackfangClaw,
        ItemCurrencyIDByName.BloodOfSargeras,
        ItemCurrencyIDByName.BrewfestPrizeToken,
        ItemCurrencyIDByName.CoinOfAncestry,
        ItemCurrencyIDByName.DominationPointCommission,
        ItemCurrencyIDByName.DraenicSeeds,
        ItemCurrencyIDByName.HalaaBattleToken,
        ItemCurrencyIDByName.HalaaResearchToken,
        ItemCurrencyIDByName.LionsLandingCommission,
        ItemCurrencyIDByName.LoveToken,
        ItemCurrencyIDByName.MarkOfHonor,
        ItemCurrencyIDByName.NatsLuckyCoin,
        ItemCurrencyIDByName.PetCharm,
        ItemCurrencyIDByName.PrimalSargerite,
        ItemCurrencyIDByName.PrimalSpirit,
        ItemCurrencyIDByName.VesselOfHorrificVisions
    },
    --------------------------------------------------------------------------------
    ---- Miscellaneous
    --------------------------------------------------------------------------------
    {
        CurrencyIDByName.AncientMana,
        CurrencyIDByName.ArgentCommendation,
        CurrencyIDByName.CoalescingVisions,
        CurrencyIDByName.CorruptedMemento,
        CurrencyIDByName.DingyIronCoins,
        CurrencyIDByName.EchoesOfNyalotha,
        CurrencyIDByName.GarrisonResources,
        CurrencyIDByName.HonorboundServiceMedal,
        CurrencyIDByName.MedallionOfService,
        CurrencyIDByName.Nethershard,
        CurrencyIDByName.Oil,
        CurrencyIDByName.OrderResources,
        CurrencyIDByName.PrismaticManapearl,
        CurrencyIDByName.Phantasma,
        CurrencyIDByName.RichAzeriteFragment,
        CurrencyIDByName.SeafarersDubloon,
        CurrencyIDByName.SeventhLegionServiceMedal,
        CurrencyIDByName.Stygia,
        CurrencyIDByName.TimelessCoin,
        CurrencyIDByName.TitanResiduum,
        CurrencyIDByName.TrialOfStyleToken,
        CurrencyIDByName.VeiledArgunite,
        CurrencyIDByName.WakeningEssence,
        CurrencyIDByName.WarResources,
        CurrencyIDByName.WarSupplies
    },
    --------------------------------------------------------------------------------
    ---- Professions
    --------------------------------------------------------------------------------
    {
        CurrencyIDByName.DalaranJewelcraftersToken,
        CurrencyIDByName.EpicuriansAward,
        CurrencyIDByName.IllustriousJewelcraftersToken,
        CurrencyIDByName.IronpawToken,
        CurrencyIDByName.SecretOfDraenorAlchemy,
        CurrencyIDByName.SecretOfDraenorBlacksmithing,
        CurrencyIDByName.SecretOfDraenorJewelcrafting,
        CurrencyIDByName.SecretOfDraenorLeatherworking,
        CurrencyIDByName.SecretOfDraenorTailoring
    },
    --------------------------------------------------------------------------------
    ----  PVP
    --------------------------------------------------------------------------------
    {
        CurrencyIDByName.ArtifactFragment,
        CurrencyIDByName.BloodyCoin,
        CurrencyIDByName.Conquest,
        CurrencyIDByName.EchoesOfBattle,
        CurrencyIDByName.EchoesOfDomination,
        CurrencyIDByName.Honor,
        CurrencyIDByName.SightlessEye,
        CurrencyIDByName.SpiritShard,
        CurrencyIDByName.TolBaradCommendation
    },
    -------------------------------------------------------------------------------
    ---- Quest Objectives
    -------------------------------------------------------------------------------
    {
        CurrencyIDByName.ApexisCrystal,
        CurrencyIDByName.ChampionsSeal,
        CurrencyIDByName.CoinsOfAir,
        CurrencyIDByName.CuriousCoin,
        CurrencyIDByName.DarkmoonPrizeTicket,
        CurrencyIDByName.LegionfallWarSupplies,
        CurrencyIDByName.LingeringSoulFragment,
        CurrencyIDByName.MarkOfTheWorldTree,
        CurrencyIDByName.SinstoneFragments,
        CurrencyIDByName.TimewornArtifact,
        CurrencyIDByName.WrithingEssence
    }
}

private.OrderedCurrencyGroups = OrderedCurrencyGroups

local OrderedCurrencyIDs = {}
private.OrderedCurrencyIDs = OrderedCurrencyIDs

for groupIndex = 1, #OrderedCurrencyGroups do
    local group = OrderedCurrencyGroups[groupIndex]

    for idIndex = 1, #group do
        OrderedCurrencyIDs[#OrderedCurrencyIDs + 1] = group[idIndex]
    end
end
