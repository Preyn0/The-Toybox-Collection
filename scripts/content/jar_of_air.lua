--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
local item = {
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

function item:OnSpawn(NPC)
    if NPC:IsActiveEnemy(false) and TTCG.SharedHas(item.ID) then
        local RNG = RNG()
        RNG:SetSeed(NPC.InitSeed, 1)

        if RNG:RandomInt(100)+1 <= item.TRIGGER_CHANCE then
            TTCG.GAME:Fart(NPC.Position, 85, player)
            NPC:AddPoison(EntityRef(Isaac.GetPlayer(0)), RNG:RandomInt(item.ADDED_POISON)+item.MIN_POISON, 1)
            if not TTCG.SFX:IsPlaying(item.TRIGGER_SFX) then TTCG.SFX:Play(item.TRIGGER_SFX, 1, 0, false, 2.5) end
        end
    end
end

function item:OnDamage(entity, _, flags, source, _)
    if entity:ToPlayer():HasCollectible(item.ID) and ((flags & DamageFlag.DAMAGE_POISON_BURN) ~= 0 or (source.Type == 1000 and source.Variant == 141)) then
        TTCG.SFX:Play(item.BLOCK_SFX, 1, 0, false, 2)
        return false
    end
end

function item:OnCollect(player)
    player:AddMaxHearts(2)
    player:AddRottenHearts(2)
    
    for i=1, item.LOCUST_AMOUNT do
        Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.ABYSS_LOCUST, 305, player.Position, Vector(0,0), player)
    end
end

function item:OnGrab() TTCG.SharedOnGrab(item.PICKUP_SFX) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
TTCG:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, item.OnDamage, EntityType.ENTITY_PLAYER)
TTCG:AddCallback(ModCallbacks.MC_POST_NPC_INIT,   item.OnSpawn                           )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", item.OnGrab,    item.ID)
TCC_API:AddTTCCallback("TCC_EXIT_QUEUE",  item.OnCollect, item.ID)

return item