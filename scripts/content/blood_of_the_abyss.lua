local mod = RegisterMod("Blood of the abyss", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.BLOOD_OF_THE_ABYSS = {
    ID = Isaac.GetItemIdByName("Blood of the abyss"),

    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_BLOOD_OF_THE_ABYSS_PICKUP"),
    DAMAGE_SFX = SoundEffect.SOUND_MOTHER_LAND_SMASH, -- Isaac.GetSoundIdByName("TOYCOL_BLOOD_OF_THE_ABYSS_DAMAGE"),

    DAMAGE_FG_GFX = Isaac.GetEntityVariantByName("TOYCOL_BLOOD_OF_THE_ABYSS_FG"),
    DAMAGE_BG_GFX = Isaac.GetEntityVariantByName("TOYCOL_BLOOD_OF_THE_ABYSS_BG"),

    COSTUME_3 = Isaac.GetCostumeIdByPath("gfx/characters/TOYCOL_blood_abyss_3.anm2"),
    COSTUME_2 = Isaac.GetCostumeIdByPath("gfx/characters/TOYCOL_blood_abyss_2.anm2"),
    COSTUME_1 = Isaac.GetCostumeIdByPath("gfx/characters/TOYCOL_blood_abyss_1.anm2"),

    TEARS = 7,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Blood of the abyss", DESC = "Ignore 3 hits every floor" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Grants the player 3 free hits every floor."},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Hollow knight".'},
            {str = 'The item is referencing the "Lifeblood" mechanic within the game.'},
        }
    }
}

local currentHealth = nil

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnPlayerUpdate(player)
    -- Set health and costume if undefined
    if currentHealth ~= nil and player:HasCollectible(TTCG.BLOOD_OF_THE_ABYSS.ID) and currentHealth[player.ControllerIndex..","..player:GetPlayerType()] == nil then
        player:AddNullCostume(TTCG.BLOOD_OF_THE_ABYSS.COSTUME_3)
        currentHealth[player.ControllerIndex..","..player:GetPlayerType()] = 3
    end
end

function mod:OnDamage(entity, _, flags, _, _)
    local player = entity:ToPlayer()

    if currentHealth ~= nil
    and player:HasCollectible(TTCG.BLOOD_OF_THE_ABYSS.ID) 
    and (flags & DamageFlag.DAMAGE_INVINCIBLE) == 0 
    and (flags & DamageFlag.DAMAGE_FAKE) == 0 then
        local identifier = player.ControllerIndex..","..player:GetPlayerType()

        if not currentHealth[identifier] or currentHealth[identifier] > 0 then
            -- Ignore sacrifices
            if  TTCG.GAME:GetRoom():GetType() == RoomType.ROOM_SACRIFICE and (flags & DamageFlag.DAMAGE_SPIKES) ~= 0 then
                return nil
            end

            -- Update "lives"
            local oldHealth = (currentHealth[identifier] and currentHealth[identifier] or 3)
            local newHealth = oldHealth - 1
        
            currentHealth[identifier] = newHealth

            -- Play "take damage" sfx
            TTCG.SFX:Play(TTCG.BLOOD_OF_THE_ABYSS.DAMAGE_SFX, 3, 0, false, 0.75, 0)

            -- Shake screen
            TTCG.GAME:ShakeScreen(10)

            -- Spawn effects
            Isaac.Spawn(EntityType.ENTITY_EFFECT, TTCG.BLOOD_OF_THE_ABYSS.DAMAGE_FG_GFX, 1, player.Position, Vector(0, 0), player).DepthOffset = player.DepthOffset + 10
            Isaac.Spawn(EntityType.ENTITY_EFFECT, TTCG.BLOOD_OF_THE_ABYSS.DAMAGE_BG_GFX, 1, player.Position, Vector(0, 0), player).DepthOffset = player.DepthOffset - 10

            -- Spawn tears
            local tearColor = Color(1, 1, 1, 1, 0, 0, 0)
            tearColor:SetColorize(0, 0.75, 6, 1)

            for i=1, TTCG.BLOOD_OF_THE_ABYSS.TEARS do
                local randomVelocity = Vector(math.random(3,5)*(math.random(2) == 1 and -1 or 1), math.random(3,5)*(math.random(2) == 1 and -1 or 1))
                local newTear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, player.Position - Vector(0, 4), randomVelocity, player):ToTear()
                newTear.FallingSpeed = -math.random(7, 12)
                newTear.FallingAcceleration = math.random(10, 13)/10
                newTear.Scale = math.random(70, 120)/100
                newTear.Color = tearColor
            end

            -- Fake damage for invis frames
            player:TakeDamage(1, (DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_INVINCIBLE), EntityRef(player), 0)

            -- Remove old costume
            player:TryRemoveNullCostume(TTCG.BLOOD_OF_THE_ABYSS["COSTUME_" .. tostring(oldHealth)])

            -- Add new costume if they still have "lives" left
            if newHealth and newHealth > 0 then
                player:AddNullCostume(TTCG.BLOOD_OF_THE_ABYSS["COSTUME_" .. tostring(newHealth)])
            end

            -- Cancel damage
            return false
        end
    end
end

function mod:OnNewFloor()
    -- Reset health state 
    if currentHealth ~= nil then currentHealth = {} end
end

function mod:OnLoad(isContinued)
    -- Reset save if new run
    if isContinued then
        local loadStatus, LoadValue = pcall(json.decode, mod:LoadData())
        
        if loadStatus and LoadValue["BLOOD_OF_THE_ABYSS"] then
            currentHealth = LoadValue["BLOOD_OF_THE_ABYSS"]
        else
            TTCG.SAVEDATA.BLOOD_OF_THE_ABYSS = nil
            currentHealth = {}
        end
    else
        mod:RemoveData()
        TTCG.SAVEDATA.BLOOD_OF_THE_ABYSS = nil
        currentHealth = {}
    end
end

function mod:OnExit()
    TTCG.SAVEDATA.BLOOD_OF_THE_ABYSS = currentHealth
	mod:SaveData(json.encode(TTCG.SAVEDATA))
    currentHealth = nil
end

function mod:OnGrab(player) TTCG.SFX:Play(TTCG.BLOOD_OF_THE_ABYSS.PICKUP_SFX, 1, 0) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPlayerUpdate                    )
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,    mod.OnDamage, EntityType.ENTITY_PLAYER)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,     mod.OnNewFloor                        )
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,      mod.OnExit                            )
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,  mod.OnLoad                            )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.BLOOD_OF_THE_ABYSS.ID)

return TTCG.BLOOD_OF_THE_ABYSS