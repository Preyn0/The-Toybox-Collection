local mod = RegisterMod("Jar of air", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.JAR_OF_AIR = {
    ID = Isaac.GetItemIdByName("Jar of air"),
    
    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_JAR_OF_AIR_PICKUP"),
    TRIGGER_SFX = SoundEffect.SOUND_POOP_LASER, -- Isaac.GetSoundIdByName("TOYCOL_JAR_OF_AIR_TRIGGER"),
    BLOCK_SFX = SoundEffect.SOUND_BISHOP_HIT, -- Isaac.GetSoundIdByName("TOYCOL_JAR_OF_AIR_BLOCK"),

    LOCUST_AMOUNT = 3,
    TRIGGER_CHANCE = 10,
    MIN_POISON = 41,
    ADDED_POISON = 260,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Jar of air", DESC = "{{ArrowUp}} +1 Health up#{{RottenHeart}} +1 Rotten heart#{{Collectible706}} +3 Poison locusts#Poison resistance#Some enemies are poisoned when appearing" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Grants a health up and one rotten heart upon pickup."},
            {str = "If the player can't carry health 5 normal poison flies will be spawned instead."},
            {str = "Also adds 3 abyss poison locusts to the player when picked up."},
            {str = "Grants poison cloud and poison damage resistance."},
            {str = "Spawns farts and poisons random enemies when they spawn in."},
            {str = "The poisoning lasts a random amount of time."},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Terraria".'},
            {str = 'The item is referencing the "Fart in a Jar" accessory that can be found in the game.'},
        }
    }
}

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--

function mod:OnSpawn(NPC)
    if NPC:IsActiveEnemy(false) and TTCG.SharedHas(TTCG.JAR_OF_AIR.ID) then
        local RNG = RNG()
        RNG:SetSeed(NPC.InitSeed, 1)

        if RNG:RandomInt(100)+1 <= TTCG.JAR_OF_AIR.TRIGGER_CHANCE then
            TTCG.GAME:Fart(NPC.Position, 85, player)
            NPC:AddPoison(EntityRef(Isaac.GetPlayer(0)), RNG:RandomInt(TTCG.JAR_OF_AIR.ADDED_POISON)+TTCG.JAR_OF_AIR.MIN_POISON, 1)
            if not TTCG.SFX:IsPlaying(TTCG.JAR_OF_AIR.TRIGGER_SFX) then TTCG.SFX:Play(TTCG.JAR_OF_AIR.TRIGGER_SFX, 1, 0, false, 2.5) end
        end
    end
end

function mod:OnDamage(entity, _, flags, source, _)
    if entity:ToPlayer():HasCollectible(TTCG.JAR_OF_AIR.ID) and ((flags & DamageFlag.DAMAGE_POISON_BURN) ~= 0 or (source.Type == 1000 and source.Variant == 141)) then
        TTCG.SFX:Play(TTCG.JAR_OF_AIR.BLOCK_SFX, 1, 0, false, 2)
        return false
    end
end

function mod:OnCollect(player)
    player:AddMaxHearts(2)
    player:AddRottenHearts(2)
    
    for i=1, TTCG.JAR_OF_AIR.LOCUST_AMOUNT do
        Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.ABYSS_LOCUST, 305, player.Position, Vector(0,0), player)
    end
end

function mod:OnGrab() TTCG.SharedOnGrab(TTCG.JAR_OF_AIR.PICKUP_SFX) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnDamage, EntityType.ENTITY_PLAYER)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT,   mod.OnSpawn                           )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab,    TTCG.JAR_OF_AIR.ID)
TCC_API:AddTTCCallback("TCC_EXIT_QUEUE",  mod.OnCollect, TTCG.JAR_OF_AIR.ID)

return TTCG.JAR_OF_AIR