--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
local item = {
    ID = Isaac.GetItemIdByName("Blank"),
    TRIGGER_GFX = Isaac.GetEntityVariantByName("TOYCOL_BLANK_TRIGGER"),

    PICKUP_SFX = SoundEffect.SOUND_1UP,
    TRIGGER_SFX = SoundEffect.SOUND_LIGHTBOLT,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_CRANE_GAME,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
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
function item:OnDamage(entity, _, flags, _, _)
    -- print('damage triggered')
    local player = entity:ToPlayer()
    local RNG = player:GetCollectibleRNG(item.ID)

    if player:HasCollectible(item.ID) then
        local entities = Isaac.GetRoomEntities()

        for i=1, #entities do
            local entity = entities[i]

            if entity.Type == EntityType.ENTITY_PROJECTILE or entity.Type == EntityType.ENTITY_LASER or entity.Type == EntityType.ENTITY_KNIFE then
                if entity.SpawnerType ~= EntityType.ENTITY_PLAYER then
                    entity:Kill()
                end
            elseif entity:IsEnemy() then
                entity:AddSlowing(EntityRef(player), 70, 8, Color(0.75, 0.35, 0, 1, 0, 0, 0))
            end
        end

        local effect = TTCG.GAME:Spawn(EntityType.ENTITY_EFFECT, item.TRIGGER_GFX, player.Position + Vector(0, -20), Vector(0,0), nil, 1, 0):ToEffect()
        effect.DepthOffset = 1000
        effect:FollowParent(player)
        effect:Update()
    
        TTCG.GAME:ShakeScreen(10)
        TTCG.SFX:Play(item.TRIGGER_SFX, 1, 0, false, 1.25)
    end
end

function item:OnGrab() TTCG.SharedOnGrab(item.PICKUP_SFX) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
TTCG:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, item.OnDamage, EntityType.ENTITY_PLAYER)

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", item.OnGrab, item.ID)

return item