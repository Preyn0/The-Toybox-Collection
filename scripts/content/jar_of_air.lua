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

    TRIGGER_CHANCE = 10,
    MIN_POISON = 41,
    ADDED_POISON = 260,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Jar of air", DESC = "Deez" }
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
function mod:OnEnter()
    if not TTCG.GAME:GetRoom():IsClear() then
        local numPlayers = TTCG.GAME:GetNumPlayers()
        for i=1,numPlayers do
            local player = TTCG.GAME:GetPlayer(tostring((i-1)))
            
            if player:HasCollectible(TTCG.JAR_OF_AIR.ID) then
                local entities = Isaac.GetRoomEntities()
                local triggered = false

                for i=1, #entities do
                    local RNG = player:GetCollectibleRNG(TTCG.JAR_OF_AIR.ID)
                    if entities[i]:IsEnemy() and RNG:RandomInt(100)+1 <= TTCG.JAR_OF_AIR.TRIGGER_CHANCE then
                        triggered = true
                        TTCG.GAME:Fart(entities[i].Position, 85, player)
                        entities[i]:AddPoison(EntityRef(player), RNG:RandomInt(TTCG.JAR_OF_AIR.ADDED_POISON)+TTCG.JAR_OF_AIR.MIN_POISON, 1)
                    end
                end

                if triggered then TTCG.SFX:Play(TTCG.JAR_OF_AIR.TRIGGER_SFX, 1, 0, false, 2.5) end
                return
            end
        end
    end
end

function mod:OnDamage(entity, _, flags, source, _)
    if (flags & DamageFlag.DAMAGE_POISON_BURN) ~= 0 or (source.Type == 1000 and source.Variant == 141) then
        TTCG.SFX:Play(TTCG.JAR_OF_AIR.BLOCK_SFX, 1, 0, false, 2)
        return false
    end
end

function mod:OnGrab(player) TTCG.SFX:Play(TTCG.JAR_OF_AIR.PICKUP_SFX, 1, 0) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnEnter)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnDamage, EntityType.ENTITY_PLAYER)

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.JAR_OF_AIR.ID)

return TTCG.JAR_OF_AIR