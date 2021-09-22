local mod = RegisterMod("Witch wand", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.WITCH_WAND = {
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
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Witch wand", DESC = "Deez" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Deez"},
        }
    }
}

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnPlayerUpdate(player)
    if player:HasCollectible(TTCG.WITCH_WAND.ID) then
        player:ClearEntityFlags(EntityFlag.FLAG_FEAR) -- fear immunity
    end
end

function mod:OnDamage(entity, _, flags, _, _)
    local player = entity:ToPlayer()
    local RNG = player:GetCollectibleRNG(TTCG.WITCH_WAND.ID)

    if player:HasCollectible(TTCG.WITCH_WAND.ID) and RNG:RandomInt(100)+1 <= TTCG.WITCH_WAND.SPAWN_CHANCE then
        local selection = TTCG.WITCH_WAND.ENEMIES[RNG:RandomInt(#TTCG.WITCH_WAND.ENEMIES)+1]
        local fren = TTCG.GAME:Spawn(selection.Type, selection.Variant or 0, player.Position, Vector(0,0), player, 0, RNG:GetSeed())
        fren:AddCharmed(EntityRef(player), -1)
        TTCG.SFX:Play(TTCG.WITCH_WAND.TRIGGER_SFX, 0.75, 0, false, 1.6)
    end
end

function mod:OnSpawn(NPC)
    if TTCG.WITCH_WAND.BOSSES[NPC.Type] then
        local numPlayers = TTCG.GAME:GetNumPlayers()
        for i=1,numPlayers do
            local player = TTCG.GAME:GetPlayer(tostring((i-1)))
            
            if player:HasCollectible(TTCG.WITCH_WAND.ID) then
                NPC:TakeDamage(NPC.MaxHitPoints/2, (DamageFlag.DAMAGE_IGNORE_ARMOR | DamageFlag.DAMAGE_INVINCIBLE), EntityRef(player), 0)
                TTCG.SFX:Play(TTCG.WITCH_WAND.BOSS_SFX, 1.5, 0, false, 0.6)
                return
            end
        end
    end
end

function mod:OnGrab() TTCG.SFX:Play(TTCG.WITCH_WAND.PICKUP_SFX, 2, 10) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPlayerUpdate)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,    mod.OnDamage, EntityType.ENTITY_PLAYER)
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT,      mod.OnSpawn)

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.WITCH_WAND.ID)

return TTCG.WITCH_WAND