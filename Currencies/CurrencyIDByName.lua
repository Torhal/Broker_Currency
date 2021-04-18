--------------------------------------------------------------------------------
---- AddOn Namespace
--------------------------------------------------------------------------------
local _, private = ...

--------------------------------------------------------------------------------
---- Definitions
--------------------------------------------------------------------------------
local CurrencyIDByName = {
    DalaranJewelcraftersToken = 61,
    EpicuriansAward = 81,
    ChampionsSeal = 241,
    IllustriousJewelcraftersToken = 361,
    DwarfArchaeologyFragment = 384,
    TrollArchaeologyFragment = 385,
    TolBaradCommendation = 391,
    FossilArchaeologyFragment = 393,
    NightelfArchaeologyFragment = 394,
    OrcArchaeologyFragment = 397,
    DraeneiArchaeologyFragment = 398,
    VrykulArchaeologyFragment = 399,
    NerubianArchaeologyFragment = 400,
    TolvirArchaeologyFragment = 401,
    IronpawToken = 402,
    MarkOfTheWorldTree = 416,
    DarkmoonPrizeTicket = 515,
    MoteOfDarkness = 614,
    EssenceDeathwing = 615,
    PandarenArchaeologyFragment = 676,
    MoguArchaeologyFragment = 677,
    ElderCharmOfGoodFortune = 697,
    LesserCharmOfGoodFortune = 738,
    MoguRuneOfFate = 752,
    MantidArchaeologyFragment = 754,
    WarforgedSeal = 776,
    TimelessCoin = 777,
    BloodyCoin = 789,
    DraenorClansArchaeologyFragment = 821,
    ApexisCrystal = 823,
    GarrisonResources = 824,
    OgreArchaeoogyFragment = 828,
    ArakkoaArchaelogoyFragment = 829,
    SecretOfDraenorAlchemy = 910,
    ArtifactFragment = 944,
    DingyIronCoins = 980,
    SealOfTemperedFate = 994,
    SecretOfDraenorTailoring = 999,
    SecretOfDraenorJewelcrafting = 1008,
    SecretOfDraenorLeatherworking = 1017,
    SecretOfDraenorBlacksmithing = 1020,
    Oil = 1101,
    SealOfInevitableFate = 1129,
    SightlessEye = 1149,
    AncientMana = 1155,
    TimewarpedBadge = 1166,
    HighborneArchaeologyFragment = 1172,
    HighmountainTaurenArchaeologyFragment = 1173,
    DemonicArchaeologyFragment = 1174,
    Valor = 1191,
    OrderResources = 1220,
    Nethershard = 1226,
    TimewornArtifact = 1268,
    SealOfBrokenFate = 1273,
    CuriousCoin = 1275,
    LingeringSoulFragment = 1314,
    LegionfallWarSupplies = 1342,
    EchoesOfBattle = 1356,
    EchoesOfDomination = 1357,
    TrialOfStyleToken = 1379,
    CoinsOfAir = 1416,
    WrithingEssence = 1501,
    VeiledArgunite = 1508,
    WakeningEssence = 1533,
    ZandalariArchaeologyFragment = 1534,
    DrustArchaeologyFragment = 1535,
    WarResources = 1560,
    RichAzeriteFragment = 1565,
    SealOfWartornFate = 1580,
    WarSupplies = 1587,
    Conquest = 1602,
    SpiritShard = 1704,
    SeafarersDubloon = 1710,
    HonorboundServiceMedal = 1716,
    SeventhLegionServiceMedal = 1717,
    TitanResiduum = 1718,
    CorruptedMemento = 1719,
    PrismaticManapearl = 1721,
    ArgentCommendation = 1754,
    CoalescingVisions = 1755,
    Stygia = 1767,
    Honor = 1792,
    EchoesOfNyalotha = 1803,
    ReservoirAnima = 1813,
    SinstoneFragments = 1816,
    MedallionOfService = 1819,
    InfusedRuby = 1820,
    SoulAsh = 1828,
    GratefulOffering = 1885
}

private.CurrencyIDByName = CurrencyIDByName

local CurrencyNameByID = {}

for name, currencyID in pairs(CurrencyIDByName) do
    CurrencyNameByID[currencyID] = name
end

private.CurrencyNameByID = CurrencyNameByID
