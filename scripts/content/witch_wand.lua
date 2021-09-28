--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
local item = {
    ID = Isaac.GetItemIdByName("Witch wand"),

    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_WAND_PICKUP"),
    BOSS_SFX = SoundEffect.SOUND_BERSERK_END, --Isaac.GetSoundIdByName("TOYCOL_WAND_BOSS"),
    TRIGGER_SFX = SoundEffect.SOUND_MIRROR_ENTER, --Isaac.GetSoundIdByName("TOYCOL_WAND_SPAWN"),

    SPAWN_CHANCE = 7,
    ENEMIES = {
        { Type=883 }, -- Baby Begotten
        { Type=891 }, -- Goat
        { Type=891, Variant=1 }, -- Black Goat
        { Type=885 }, -- Cultist
        { Type=885, Variant=1 }, -- Blood Cultist
        { Type=841 }, -- Revenant
        { Type=841, Variant=1 }, -- Quad Revenant
        { Type=890 }, -- Maze Roamer
        { Type=886 }, -- Vis Fatty
        { Type=886, Variant=1 }, -- Fetal Demon
        { Type=834 }, -- Whipper
        { Type=834, Variant=1 }, -- Snapper
        { Type=834, Variant=2 }, -- Flagellant
        { Type=24, Variant=3 }, -- Cursed Goblin (XQC)
        { Type=41, Variant=2 }, -- Loose Knight
        { Type=41, Variant=3 }, -- Brainless Knight
        { Type=41, Variant=4 }, -- Black Knight
        { Type=840 }, -- Pon
        { Type=92 }, -- Mask + Heart
        { Type=92, Variant=1 }, -- Mask 2 + 1/2 Heart
        { Type=892 }, -- Poofer
        { Type=836 }, -- Vis Versa
        { Type=863 }, -- Morning Star
        { Type=248 }, -- Psychic Horf
        { Type=26, Variant=2 }, -- Psychic Maw
        { Type=246, Variant=1 }, -- Rag Man Ragling
        { Type=260, Variant=10 }, -- Lil' Haunt
        { Type=833 }, -- Candler
        { Type=816, Variant=1 }, -- Kineti
        { Type=805 }, -- Bishop
        { Type=227 }, -- Bony
    },
    BOSSES = {
        [EntityType.ENTITY_VISAGE] = true,
        [EntityType.ENTITY_HORNY_BOYS] = true,
        [EntityType.ENTITY_RAGLICH] = true, --unused
        [EntityType.ENTITY_SIREN] = true,
        [EntityType.ENTITY_HERETIC] = true
    },

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_CURSE,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_CURSE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Witch wand", DESC = "{{BlackHeart}} +1 Black heart#Can spawn a friendly enemy upon damage#Weaken gehenna and mausoleum bosses#Fear resistance" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Grants one black heart."},
            {str = "Has a 7% chance to spawn a gehenna or mausoleum themed enemy upon taking damage."},
            {str = "Weakens the following bosses to 50% health: The Visage, Horny Boys, Siren and The Heretic."},
            {str = "Grants the player fear immunity"},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Noita".'},
            {str = 'The item is one of the wands granted to the player upon starting a run.'},
        }
    }
}

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function item:OnPlayerUpdate(player)
    if player:HasCollectible(item.ID) then
        player:ClearEntityFlags(EntityFlag.FLAG_FEAR) -- fear immunity
    end
end

function item:OnDamage(entity, _, flags, _, _)
    local player = entity:ToPlayer()
    local RNG = player:GetCollectibleRNG(item.ID)

    if player:HasCollectible(item.ID) and RNG:RandomInt(100)+1 <= item.SPAWN_CHANCE then
        local selection = item.ENEMIES[RNG:RandomInt(#item.ENEMIES)+1]
        local fren = TTCG.GAME:Spawn(selection.Type, selection.Variant or 0, player.Position, Vector(0,0), player, 0, RNG:GetSeed())
        fren:AddCharmed(EntityRef(player), -1)
        TTCG.SFX:Play(item.TRIGGER_SFX, 0.75, 0, false, 1.6)
    end
end

function item:OnSpawn(NPC)
    if item.BOSSES[NPC.Type] then
        local player = TTCG.SharedHas(item.ID)
        if player then
            NPC:AddHealth(-(NPC.MaxHitPoints/2))
            TTCG.SFX:Play(item.BOSS_SFX, 1.5, 0, false, 0.6)
            return
        end
    end
end

function item:OnGrab() TTCG.SharedOnGrab(item.PICKUP_SFX) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
TTCG:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, item.OnPlayerUpdate                    )
TTCG:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,    item.OnDamage, EntityType.ENTITY_PLAYER)

TCC_API:AddTTCCallback("TCC_NPC_INIT", item.OnSpawn)
TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", item.OnGrab, item.ID)

return item