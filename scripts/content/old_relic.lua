local mod = RegisterMod("Old relic", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.OLD_RELIC = {
    ID = Isaac.GetItemIdByName("Old relic"),
    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_OLD_RELIC_PICKUP"),
    STEP_SFX = SoundEffect.SOUND_HELLBOSS_GROUNDPOUND, --Isaac.GetSoundIdByName("TOYCOL_OLD_RELIC_STEP"),

    RADIUS = 120,
    DAMAGE_MULTIPLIER = 3,
    VELOCITY_MULTIPLIER = 15,
    TRIGGER_FRAMES = 80,
    
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Old relic", DESC = "While walking create shockwaves#Shockwaves fill gaps#Shockwaves damage enemies" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "While walking the player creates a shockwave periodically."},
            {str = "These shockwaves will fill gaps around the player."},
            {str = "They will also damage (3x the players damage) and push enemies."},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Undermine".'},
            {str = "The item is referencing the " .. '"' .. "Wayland's" .. '"' ..  " Boots relic that can be found in the game."},
        }
    }
}

local cachedTriggers = {}

--TODO: add stomp sound

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnPlayerUpdate(player)
    if player:HasCollectible(TTCG.OLD_RELIC.ID) and TTCG.GAME:GetFrameCount() % TTCG.OLD_RELIC.TRIGGER_FRAMES == 0 and not (player.Velocity:Distance(Vector(0,0)) <= 0.5) then
        if not cachedTriggers[player.InitSeed] then
            cachedTriggers[player.InitSeed] = true

            -- Fill gaps
            local room = TTCG.GAME:GetRoom()
            for i = 1, room:GetGridSize() do
                local entity = room:GetGridEntity(i)
                
                if entity then
                    if entity.Desc.Type == GridEntityType.GRID_PIT and room:GetGridPosition(i):Distance(player.Position) < (TTCG.OLD_RELIC.RADIUS+20) then
                        --TODO: Add particle effect for bridge appearing
                        entity:ToPit():MakeBridge(nil)
                    end
                end
            end

            -- Push enemies
            local entities = Isaac.FindInRadius(player.Position, TTCG.OLD_RELIC.RADIUS, 8)

            for i=1, #entities do
                local entity = entities[i]

                entity:TakeDamage(player.Damage*TTCG.OLD_RELIC.DAMAGE_MULTIPLIER, DamageFlag.DAMAGE_CRUSH, EntityRef(player), 5)
                entity:AddVelocity((entity.Position - player.Position):Normalized()*TTCG.OLD_RELIC.VELOCITY_MULTIPLIER)
            end

            TTCG.GAME:ShakeScreen(3)

            -- BG
            local effect = TTCG.GAME:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, player.Position, Vector(0,0), nil, 1, 0):GetSprite()
            effect.Scale = Vector(0.75, 0.75)
            effect:Update()

            -- FG
            effect = TTCG.GAME:Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, player.Position, Vector(0,0), nil, 2, 0):GetSprite()
            effect.Scale = Vector(0.75, 0.75)
            effect:Update()

            TTCG.SFX:Play(TTCG.OLD_RELIC.STEP_SFX, 0.65, 0, false, 1.25, 0.5)
        else
            cachedTriggers[player.InitSeed] = nil
        end
    end
end

function mod:OnGrab() TTCG.SFX:Play(TTCG.OLD_RELIC.PICKUP_SFX, 2, 10) end


--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPlayerUpdate)

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.OLD_RELIC.ID)

return TTCG.OLD_RELIC