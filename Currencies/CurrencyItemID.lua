--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local _, private = ...

--------------------------------------------------------------------------------
---- Definition
--------------------------------------------------------------------------------
local CurrencyItemID = {
    ApexisCrystal = 32572,
    ApexisShard = 32569,
    BlackfangClaw = 124099,
    BloodOfSargeras = 124124,
    BrewfestPrizeToken = 37829,
    CoinOfAncestry = 21100,
    DominationPointCommission = 91877,
    DraenicSeeds = 116053,
    HalaaBattleToken = 26045,
    HalaaResearchToken = 26044,
    LionsLandingCommission = 91838,
    LoveToken = 49927,
    MarkOfHonor = 137642,
    NatsLuckyCoin = 117397,
    ShinyPetCharm = 116415,
    PrimalSargerite = 151568,
    PrimalSpirit = 120945,
    PolishedPetCharm = 163036,
    VesselOfHorrificVisions = 173363,
    SparkOfIngenuity = 190453,
    ZskeraVaultKey = 202196,
    DormantPrimordialFragment = 204215,
    SparkOfShadowflame = 204440,
    WhelplingsShadowflameCrestFragment = 204075,
    DrakesShadowflameCrestFragment = 204076,
    WyrmsShadowflameCrestFragment = 204077,
    AspectsShadowflameCrestFragment = 204078,
    WhelplingsShadowflameCrest = 204193,
    AspectsShadowflameCrest = 204194,
    DrakesShadowflameCrest = 204195,
    WyrmsShadowflameCrest = 204196,
    BarterBrick = 204985,
}

private.CurrencyItemID = CurrencyItemID

local CurrencyItemName = {}
private.CurrencyItemName = CurrencyItemName

for name, ID in pairs(CurrencyItemID) do
    CurrencyItemName[ID] = name
end
