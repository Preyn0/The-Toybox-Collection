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
    KNIFE_CHANCE = 5,
    LASER_CHANCE = 15,

    VELOCITY_MULTIPLIER = 9,
    DAMAGE_MULTIPLIER = 1.8,
    KNOCKBACK_MULTIPLIER = 5,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_ANGEL,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_ANGEL,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Ancestral assistance", DESC = "Sometimes shoot an arrow of piercing tears#Grants a one-use holy mantle" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "The player has a 4% chance to shoot an arrow of tears."},
            {str = "These tears will have piercing, Do 1.8x the players damage and high knockback."},
            {str = "Upon pickup this item will also grant a one-use holy mantle."},
            {str = "If the player has Mom's Knife then the item has a 5% chance of triggering for every frame of collision."},
            {str = "If the player has lasers instead of shots then the item has a 15% chance of triggering when the player fires."},
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
local function triggerEffect(player, source, flags, type)
    if player and player:HasCollectible(TTCG.ANCESTRAL_ASSISTANCE.ID) and player:GetCollectibleRNG(TTCG.ANCESTRAL_ASSISTANCE.ID):RandomInt(100)+1 <= TTCG.ANCESTRAL_ASSISTANCE[type] then
        local direction = player:GetAimDirection()
        --TODO: Replace with head direction DEG to vector
        if not direction or direction:Distance(Vector(0,0)) <= 0 then direction = Vector.FromAngle(translatedDirections[player:GetHeadDirection()]) end
        direction = direction:Rotated(math.random(-45, 45))

        for i=1, #translatedRotations do
            local curTear = TTCG.GAME:Spawn(
                EntityType.ENTITY_TEAR, 
                0, 
                translatedRotations[i].Mult and player.Position-(direction*translatedRotations[i].Mult) or player.Position, 
                (direction*TTCG.ANCESTRAL_ASSISTANCE.VELOCITY_MULTIPLIER):Rotated(translatedRotations[i].Deg),
                player,
                0,
                source.InitSeed
            ):ToTear()

            curTear:AddTearFlags((flags | TearFlags.TEAR_PIERCING))
            curTear.CollisionDamage = source.CollisionDamage*TTCG.ANCESTRAL_ASSISTANCE.DAMAGE_MULTIPLIER
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

function mod:OnBomb(source)
    if source.IsFetus then
        triggerEffect(TTCG.GetShooter(source), source, source.Flags, "TRIGGER_CHANCE")
    end
end

function mod:OnKnife(source, col)
    if col:IsVulnerableEnemy() then 
        triggerEffect(TTCG.GetShooter(source), source, source.TearFlags, "KNIFE_CHANCE")
    end
end

function mod:OnLaser(source)
    triggerEffect(TTCG.GetShooter(source), source, source.TearFlags, "LASER_CHANCE")
end

function mod:OnFire(source)
    if not source:GetData()['TOYCOL_ANC_SPAWN'] then
        triggerEffect(TTCG.GetShooter(source), source, source.TearFlags, "TRIGGER_CHANCE")
    end
end

function mod:OnGrab() TTCG.SharedOnGrab(TTCG.ANCESTRAL_ASSISTANCE.PICKUP_SFX) end
function mod:OnCollect(player) player:UseCard(Card.CARD_HOLY, 259) end


--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR,      mod.OnFire )
mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT,     mod.OnLaser)
mod:AddCallback(ModCallbacks.MC_PRE_KNIFE_COLLISION, mod.OnKnife)
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT,      mod.OnBomb )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab,    TTCG.ANCESTRAL_ASSISTANCE.ID)
TCC_API:AddTTCCallback("TCC_EXIT_QUEUE",  mod.OnCollect, TTCG.ANCESTRAL_ASSISTANCE.ID)

return TTCG.ANCESTRAL_ASSISTANCE