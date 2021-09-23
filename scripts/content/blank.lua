local mod = RegisterMod("Blank", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.BLANK = {
    ID = Isaac.GetItemIdByName("Blank"),
    TRIGGER_GFX = Isaac.GetEntityVariantByName("TOYCOL_BLANK_TRIGGER"),

    PICKUP_SFX = SoundEffect.SOUND_1UP,
    TRIGGER_SFX = SoundEffect.SOUND_LIGHTBOLT,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Blank", DESC = "{{SoulHeart}} +1 Soul heart#Clears bullets and slows enemies upon damage" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Grants a soul heart."},
            {str = "Upon taking damage slows all enemies in the room and clears all bullets within the room."},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Enter the Gungeon".'},
            {str = 'The item is referencing the "Blank" pickups within the game.'},
        }
    }
}

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnDamage(entity, _, flags, _, _)
    -- print('damage triggered')
    local player = entity:ToPlayer()
    local RNG = player:GetCollectibleRNG(TTCG.BLANK.ID)

    if player:HasCollectible(TTCG.BLANK.ID) then
        local entities = Isaac.GetRoomEntities()

        for i=1, #entities do
            local entity = entities[i]

            if entity.Type == EntityType.ENTITY_PROJECTILE or entity.Type == EntityType.ENTITY_LASER or entity.Type == EntityType.ENTITY_KNIFE then
                if entity.SpawnerType ~= EntityType.ENTITY_PLAYER then
                    entity:Kill()
                end
            elseif entity:IsEnemy() then
                entity:AddSlowing(EntityRef(player), 40, 8, Color(0.75, 0.35, 0, 1, 0, 0, 0))
            end
        end

        local effect = TTCG.GAME:Spawn(EntityType.ENTITY_EFFECT, TTCG.BLANK.TRIGGER_GFX, player.Position + Vector(0, -20), Vector(0,0), nil, 1, 0):ToEffect()
        effect.DepthOffset = 1000
        effect:FollowParent(player)
        effect:Update()
    
        TTCG.GAME:ShakeScreen(10)
        TTCG.SFX:Play(TTCG.BLANK.TRIGGER_SFX, 1, 0, false, 1.25, 0.75)
    end
end

function mod:OnGrab() TTCG.SharedOnGrab(TTCG.BLANK.PICKUP_SFX) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnDamage, EntityType.ENTITY_PLAYER)

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.BLANK.ID)

return TTCG.BLANK