-- ----------------------------------------------------------------------------
-- AddOn namespace
-- ----------------------------------------------------------------------------
local _, private = ...

-- ----------------------------------------------------------------------------
-- Definition
-- ----------------------------------------------------------------------------
local ItemCurrencyIDByName = {
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
    VesselOfHorrificVisions = 173363
}

private.ItemCurrencyIDByName = ItemCurrencyIDByName

local ItemCurrencyNameByID = {}
private.ItemCurrencyNameByID = ItemCurrencyNameByID

for name, ID in pairs(ItemCurrencyIDByName) do
    ItemCurrencyNameByID[ID] = name
end
