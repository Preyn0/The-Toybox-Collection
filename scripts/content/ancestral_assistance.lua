local mod = RegisterMod("Ancestral assistance", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.ANCESTRAL_ASSISTANCE = {
    ID = Isaac.GetItemIdByName("Ancestral assistance"),
    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_ANCESTRAL_ASSISTANCE_PICKUP"),
    SHOT_SFX = SoundEffect.SOUND_ANGEL_BEAM, --Isaac.GetSoundIdByName("TOYCOL_ANCESTRAL_ASSISTANCE_SHOT"),

    TRIGGER_CHANCE = 4,
    VELOCITY_MULTIPLIER = 9,
    DAMAGE_MULTIPLIER = 1.8,
    KNOCKBACK_MULTIPLIER = 5,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Ancestral assistance", DESC = "Sometimes shoot an arrow of piercing tears" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Deez"},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Ori and the blind forest".'},
            {str = 'The item is referencing the "Double Jump" skill within the game.'},
        }
    }
}

local translatedDirections = {
    [Direction.NO_DIRECTION] = 90,
    [Direction.LEFT] = 180,
    [Direction.UP] = 270,
    [Direction.RIGHT] = 0,
    [Direction.DOWN] = 90,
}

local translatedRotations = {
    [1] = { ["Deg"] = 0, ["Mult"] = 1 },
    [2] = { ["Deg"] = -2, ["Mult"] = 15 },
    [3] = { ["Deg"] = 2 , ["Mult"] = 15 },
    [4] = { ["Deg"] = -4, ["Mult"] = 25 },
    [5] = { ["Deg"] = 4, ["Mult"] = 25 },
    [6] = { ["Deg"] = -6, ["Mult"] = 35 },
    [7] = { ["Deg"] = 6, ["Mult"] = 35 },
    [8] = { ["Deg"] = -3, ["Mult"] = 30 },
    [9] = { ["Deg"] = 3 , ["Mult"] = 30 },
    [10] = { ["Deg"] = 0, ["Mult"] = 20 },
}

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnFire(tear)
    if not tear:GetData()['TOYCOL_ANC_SPAWN'] and tear.SpawnerType == EntityType.ENTITY_PLAYER and tear.SpawnerEntity then
        local player = tear.SpawnerEntity:ToPlayer()
        if player:HasCollectible(TTCG.ANCESTRAL_ASSISTANCE.ID) then
            if player:GetCollectibleRNG(TTCG.ANCESTRAL_ASSISTANCE.ID):RandomInt(100)+1 <= TTCG.ANCESTRAL_ASSISTANCE.TRIGGER_CHANCE then
                local direction = player:GetAimDirection()
                --TODO: Replace with head direction DEG to vector
                if not direction or direction:Distance(Vector(0,0)) <= 0 then direction = Vector.FromAngle(translatedDirections[player:GetHeadDirection()]) end
                direction = direction:Rotated(math.random(-45, 45))

                for i=1, #translatedRotations do
                    local curTear = TTCG.GAME:Spawn(
                        EntityType.ENTITY_TEAR, 
                        tear.Variant, 
                        translatedRotations[i].Mult and player.Position-(direction*translatedRotations[i].Mult) or player.Position, 
                        (direction*TTCG.ANCESTRAL_ASSISTANCE.VELOCITY_MULTIPLIER):Rotated(translatedRotations[i].Deg),
                        player,
                        tear.SubType,
                        tear.InitSeed
                    ):ToTear()

                    curTear:AddTearFlags((tear.TearFlags | TearFlags.TEAR_PIERCING))
                    curTear.CollisionDamage = tear.CollisionDamage*TTCG.ANCESTRAL_ASSISTANCE.DAMAGE_MULTIPLIER
                    curTear:SetKnockbackMultiplier(TTCG.ANCESTRAL_ASSISTANCE.KNOCKBACK_MULTIPLIER)
                    curTear.CanTriggerStreakEnd = false
                    curTear:SetColor(Color(1, 1, 1, 1, 0.75, 0.75, 0.75), 0, 1, false, false)
                    curTear:GetData()['TOYCOL_ANC_SPAWN'] = true
                end

                TTCG.SFX:Play(TTCG.ANCESTRAL_ASSISTANCE.SHOT_SFX, 0.5, 0, false, 2.5)

                Isaac.Spawn(EntityType.ENTITY_EFFECT, 40, 0, Vector(320, 300), Vector(0,0), player)
                --TODO: Add spawn effect
            end
        end
    end
end

function mod:OnGrab() TTCG.SFX:Play(TTCG.ANCESTRAL_ASSISTANCE.PICKUP_SFX, 1, 10) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnFire)

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.ANCESTRAL_ASSISTANCE.ID)

return TTCG.ANCESTRAL_ASSISTANCE