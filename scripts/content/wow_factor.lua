local mod = RegisterMod("Wow factor!", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.WOW_FACTOR = {
    ID = Isaac.GetItemIdByName("Wow factor!"),
    EFFECT = Isaac.GetEntityVariantByName("Wow pickup effect"),
    
    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_WOW_PICKUP"),
    SPAWN_SFX = SoundEffect.SOUND_BULB_FLASH, --Isaac.GetSoundIdByName("TOYCOL_WOW_SPAWN"),

    CHANCE = 3,
    AMOUNT = 35,
    RATE = 3,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Wow factor!", DESC = "Deez" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Deez"},
        }
    }
}

local cachedPlayers = nil

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnFire(tear)
    if cachedPlayers and tear.SpawnerType == EntityType.ENTITY_PLAYER and tear.SpawnerEntity then
        local player = tear.SpawnerEntity:ToPlayer()

        if player:HasCollectible(TTCG.WOW_FACTOR.ID) then
            local identifier = player.ControllerIndex..","..player:GetPlayerType()

            if not cachedPlayers[identifier] and player:GetCollectibleRNG(TTCG.WOW_FACTOR.ID):RandomInt(100)+1 <= TTCG.WOW_FACTOR.CHANCE then
                cachedPlayers[identifier] = {
                    ['amount'] = TTCG.WOW_FACTOR.AMOUNT, 
                    ['player'] = player 
                }
            end
        end
    end
end

function mod:OnUpdate()
    if cachedPlayers ~= nil and TTCG.GAME:GetFrameCount() % TTCG.WOW_FACTOR.RATE == 0 then
        for key, value in pairs(cachedPlayers) do
            local player = value.player

            if not (player.Velocity:Distance(Vector(0,0)) <= 0.5) then
                local newTear = player:FireTear(player.Position, Vector(0,0), false, false, false, player, 1)
                newTear:AddTearFlags(TearFlags.TEAR_MYSTERIOUS_LIQUID_CREEP)
                newTear.FallingAcceleration = -0.1 -- Makes 'em float ఠ_ఠ
                newTear.Scale = 0.6
                newTear:SetColor(Color(1, 1, 1, 1, 0.25, 0.75, 0.25), 0, 1, false, false)

                TTCG.SFX:Play(TTCG.WOW_FACTOR.SPAWN_SFX, 2, 3, false, 4)
            end

            if value.amount > 1 then
                cachedPlayers[key].amount = value.amount-1
            else
                cachedPlayers[key] = nil
            end
        end
    end
end

function mod:OnGrab(player)
    local Effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, TTCG.WOW_FACTOR.EFFECT, 1, player.Position - Vector(0, 4), Vector(0, -1.25), player)
    local Sprite = Effect:GetSprite()
    Sprite:Play('Idle')
    Sprite.Scale = Vector(1.4,1.4)
    Effect.DepthOffset = 10000
    Effect:Update()

    TTCG.SFX:Play(TTCG.WOW_FACTOR.PICKUP_SFX, 1, 10)
end

function mod:OnStart() cachedPlayers = {} end
function mod:OnExit() cachedPlayers = nil end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnFire)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnUpdate)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,  mod.OnStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,      mod.OnExit )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.WOW_FACTOR.ID)

return TTCG.WOW_FACTOR