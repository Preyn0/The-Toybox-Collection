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
    KNIFE_CHANCE = 4,
    LASER_CHANCE = 9,
    AMOUNT = 35,
    RATE = 3,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_GREED_TREASUREL,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Wow factor!", DESC = "Sometimes shoot a stream of floating poison tears" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "While shooting grants a 3% chance to start spawning a stream of floating poisonous tears."},
            {str = "After spawning 35 tears the effect stops."},
            {str = "If the player is not moving then the stream of tears pauses."},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Celeste".'},
            {str = 'The item is based on a collectible called the "Moon berry" that can be found in the game.'},
        }
    }
}

local cachedPlayers = nil

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
local function triggerEffect(player, type)
    if player and player:HasCollectible(TTCG.WOW_FACTOR.ID) then
        local identifier = player.ControllerIndex..","..player:GetPlayerType()

        if not cachedPlayers[identifier] and player:GetCollectibleRNG(TTCG.WOW_FACTOR.ID):RandomInt(100)+1 <= TTCG.WOW_FACTOR[type] then
            cachedPlayers[identifier] = {
                ['amount'] = TTCG.WOW_FACTOR.AMOUNT, 
                ['player'] = player 
            }
        end
    end
end

function mod:OnBomb(source)
    if cachedPlayers and source.IsFetus then 
        triggerEffect(TTCG.GetShooter(source), "CHANCE")
    end
end

function mod:OnKnife(source, col)
    if cachedPlayers and col:IsActiveEnemy(false) then 
        triggerEffect(TTCG.GetShooter(source), "KNIFE_CHANCE")
    end
end

function mod:OnLaser(source)
    if cachedPlayers then 
        triggerEffect(TTCG.GetShooter(source), "LASER_CHANCE")
    end
end

function mod:OnFire(source)
    if cachedPlayers then 
        triggerEffect(TTCG.GetShooter(source), "CHANCE")
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

    TTCG.SharedOnGrab(TTCG.WOW_FACTOR.PICKUP_SFX)
end

function mod:OnStart() cachedPlayers = {} end
function mod:OnExit() cachedPlayers = nil end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR,      mod.OnFire  )
mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT,     mod.OnLaser )
mod:AddCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION, mod.OnKnife )
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT,      mod.OnBomb  )
mod:AddCallback(ModCallbacks.MC_POST_UPDATE,         mod.OnUpdate)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,   mod.OnStart )
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,       mod.OnExit  )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.WOW_FACTOR.ID)

return TTCG.WOW_FACTOR