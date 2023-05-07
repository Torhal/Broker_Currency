--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local _, private = ...

local CurrencyID = private.CurrencyID
local CurrencyItemID = private.CurrencyItemID

--------------------------------------------------------------------------------
---- Definitions
--------------------------------------------------------------------------------
local ExpansionCurrencyGroups = {
    --------------------------------------------------------------------------------
    ---- The Burning Crusade
    --------------------------------------------------------------------------------
    {
        CurrencyItemID.ApexisCrystal,
        CurrencyItemID.ApexisShard,
        CurrencyItemID.HalaaBattleToken,
        CurrencyItemID.HalaaResearchToken,
        CurrencyID.SpiritShard,
    },
    --------------------------------------------------------------------------------
    ---- Wrath of the Lich King
    --------------------------------------------------------------------------------
    {
        CurrencyID.ChampionsSeal,
        CurrencyID.DalaranJewelcraftersToken,
    },
    --------------------------------------------------------------------------------
    ---- Cataclysm
    --------------------------------------------------------------------------------
    {
        CurrencyID.EssenceOfCorruptedDeathwing,
        CurrencyID.IllustriousJewelcraftersToken,
        CurrencyID.MarkOfTheWorldTree,
        CurrencyID.MoteOfDarkness,
    },
    --------------------------------------------------------------------------------
    ---- Mists of Pandaria
    --------------------------------------------------------------------------------
    {
        CurrencyID.BloodyCoin,
        CurrencyItemID.DominationPointCommission,
        CurrencyID.ElderCharmOfGoodFortune,
        CurrencyID.EpicuriansAward,
        CurrencyID.IronpawToken,
        CurrencyID.LesserCharmOfGoodFortune,
        CurrencyItemID.LionsLandingCommission,
        CurrencyID.MoguRuneOfFate,
        CurrencyID.TimelessCoin,
        CurrencyID.WarforgedSeal,
    },
    --------------------------------------------------------------------------------
    ---- Warlords of Draenor
    --------------------------------------------------------------------------------
    {
        CurrencyID.ApexisCrystal,
        CurrencyID.ArtifactFragment,
        CurrencyItemID.BlackfangClaw,
        CurrencyID.DingyIronCoins,
        CurrencyItemID.DraenicSeeds,
        CurrencyID.GarrisonResources,
        CurrencyItemID.NatsLuckyCoin,
        CurrencyID.Oil,
        CurrencyItemID.PrimalSpirit,
        CurrencyID.SealOfInevitableFate,
        CurrencyID.SealOfTemperedFate,
        CurrencyID.SecretOfDraenorAlchemy,
        CurrencyID.SecretOfDraenorBlacksmithing,
        CurrencyID.SecretOfDraenorJewelcrafting,
        CurrencyID.SecretOfDraenorLeatherworking,
        CurrencyID.SecretOfDraenorTailoring,
        CurrencyID.TimewarpedBadge,
    },
    --------------------------------------------------------------------------------
    ---- Legion
    --------------------------------------------------------------------------------
    {
        CurrencyID.AncientMana,
        CurrencyItemID.BloodOfSargeras,
        CurrencyID.CoinsOfAir,
        CurrencyID.CuriousCoin,
        CurrencyID.EchoesOfBattle,
        CurrencyID.EchoesOfDomination,
        CurrencyID.Felessence,
        CurrencyID.LegionfallWarSupplies,
        CurrencyID.LingeringSoulFragment,
        CurrencyItemID.MarkOfHonor,
        CurrencyID.Nethershard,
        CurrencyID.OrderResources,
        CurrencyItemID.PrimalSargerite,
        CurrencyID.SealOfBrokenFate,
        CurrencyID.ShadowyCoins,
        CurrencyID.SightlessEye,
        CurrencyID.TimewornArtifact,
        CurrencyID.VeiledArgunite,
        CurrencyID.WakeningEssence,
        CurrencyID.WrithingEssence,
    },
    --------------------------------------------------------------------------------
    ---- Battle for Azeroth
    --------------------------------------------------------------------------------
    {
        CurrencyID.BrawlersGold,
        CurrencyID.CoalescingVisions,
        CurrencyID.CorruptedMemento,
        CurrencyID.EchoesOfNyalotha,
        CurrencyID.HonorboundServiceMedal,
        CurrencyID.PrismaticManapearl,
        CurrencyID.RichAzeriteFragment,
        CurrencyID.SeafarersDubloon,
        CurrencyID.SealOfWartornFate,
        CurrencyID.SeventhLegionServiceMedal,
        CurrencyID.WarResources,
        CurrencyID.TitanResiduum,
        CurrencyItemID.VesselOfHorrificVisions,
        CurrencyID.WarSupplies,
    },
    --------------------------------------------------------------------------------
    ---- Shadowlands
    --------------------------------------------------------------------------------
    {
        CurrencyID.ArgentCommendation,
        CurrencyID.GratefulOffering,
        CurrencyID.InfusedRuby,
        CurrencyID.MedallionOfService,
        CurrencyID.Phantasma,
        CurrencyID.RedeemedSoul,
        CurrencyID.ReservoirAnima,
        CurrencyID.SinstoneFragments,
        CurrencyID.SoulAsh,
        CurrencyID.Stygia,
    },
    --------------------------------------------------------------------------------
    ---- Dragonflight
    --------------------------------------------------------------------------------
    {
        CurrencyID.BloodyTokens,
        CurrencyID.CatalystCharges,
        CurrencyID.DragonIslesSupplies,
        CurrencyID.ElementalOverflow,
        CurrencyID.StormSigil,
        CurrencyID.Valor,
        CurrencyItemID.SparkOfIngenuity,
        -- 10.0.7
        CurrencyItemID.DormantPrimordialFragment,
        CurrencyItemID.ZskeraVaultKey,
        -- 10.1.0
        CurrencyItemID.BarterBrick,
        CurrencyID.Flightstones,
        CurrencyItemID.SparkOfShadowflame,
        CurrencyItemID.WhelplingsShadowflameCrestFragment,
        CurrencyItemID.DrakesShadowflameCrestFragment,
        CurrencyItemID.WyrmsShadowflameCrestFragment,
        CurrencyItemID.AspectsShadowflameCrestFragment,
        CurrencyItemID.WhelplingsShadowflameCrest,
        CurrencyItemID.DrakesShadowflameCrest,
        CurrencyItemID.WyrmsShadowflameCrest,
        CurrencyItemID.AspectsShadowflameCrest,
    },
}

private.ExpansionCurrencyGroups = ExpansionCurrencyGroups

local ExpansionCurrencyIDs = {}
private.ExpansionCurrencyIDs = ExpansionCurrencyIDs

for groupIndex = 1, #ExpansionCurrencyGroups do
    local group = ExpansionCurrencyGroups[groupIndex]

    for idIndex = 1, #group do
        ExpansionCurrencyIDs[#ExpansionCurrencyIDs + 1] = group[idIndex]
    end
end
