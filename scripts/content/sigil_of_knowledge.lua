local mod = RegisterMod("Sigil of knowledge", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.SIGIL_OF_KNOWLEDGE = {
    ID = Isaac.GetItemIdByName("Sigil of knowledge"),
    EFFECT = Isaac.GetEntityVariantByName("Sigil text"),

    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_SIGIL_PICKUP"),
    TRIGGER_SFX = SoundEffect.SOUND_BLACK_POOF, Isaac.GetSoundIdByName("TOYCOL_SIGIL_TRIGGER"),

    CLEAR_PERCENT = 65,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Sigil of knowledge", DESC = "Deez" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Deez"},
        }
    }
}

local clearData = nil

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnNewFloor()
    if clearData then
        TTCG.SAVEDATA.SIGIL_OF_KNOWLEDGE = nil
        clearData = { clearCount = 0, hasTriggered = false } 
    end
end

function mod:OnEnter()
    if clearData and not clearData.hasTriggered and TTCG.GAME:GetRoom():IsFirstVisit() then
        local numPlayers = TTCG.GAME:GetNumPlayers()
        for i=1,numPlayers do
            local player = TTCG.GAME:GetPlayer(tostring((i-1)))
            
            if player:HasCollectible(TTCG.SIGIL_OF_KNOWLEDGE.ID) then
                clearData.clearCount = clearData.clearCount+1

                local level = TTCG.GAME:GetLevel()
                if clearData.clearCount >= (level:GetRooms().Size/100*TTCG.SIGIL_OF_KNOWLEDGE.CLEAR_PERCENT) then
                    
                    -- Trigger mechanical effect
                    level:SetCanSeeEverything(true)
                    level:RemoveCurses(LevelCurse.CURSE_OF_DARKNESS | LevelCurse.CURSE_OF_THE_LOST)

                    level:ApplyBlueMapEffect()
            	    level:ApplyCompassEffect(true)
                	level:ApplyMapEffect()

                    level:UpdateVisibility()
                    
                    -- Trigger visuals
                    local SigilEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, TTCG.SIGIL_OF_KNOWLEDGE.EFFECT, 1, Vector(320, 300), Vector(0,0), player)
                    SigilEffect:GetSprite():Play('Idle')
                    SigilEffect.DepthOffset = 10000
                    SigilEffect:Update()

                    SigilEffect:GetSprite():Render(Vector(360, 300), Vector(0,0), Vector(0,0));

                    -- Trigger SFX
                    TTCG.SFX:Play(TTCG.SIGIL_OF_KNOWLEDGE.TRIGGER_SFX, 1.5, 0, false, 0.75)

                    -- Update state
                    clearData.hasTriggered = true
                end
            end
        end
    end
end

function mod:OnLoad(isContinued)
    -- Reset save if new run
    if isContinued then
        local loadStatus, LoadValue = pcall(json.decode, mod:LoadData())
        
        if loadStatus and LoadValue["SIGIL_OF_KNOWLEDGE"] then
            clearData = LoadValue["SIGIL_OF_KNOWLEDGE"]
        else
            TTCG.SAVEDATA.SIGIL_OF_KNOWLEDGE = nil
            clearData = { clearCount = 0, hasTriggered = false }
        end
    else
        mod:RemoveData()
        TTCG.SAVEDATA.SIGIL_OF_KNOWLEDGE = nil
        clearData = { clearCount = 0, hasTriggered = false }
    end
end

function mod:OnExit()
    TTCG.SAVEDATA.SIGIL_OF_KNOWLEDGE = clearData
	mod:SaveData(json.encode(TTCG.SAVEDATA))
    clearData = nil
end

function mod:OnGrab() TTCG.SFX:Play(TTCG.SIGIL_OF_KNOWLEDGE.PICKUP_SFX, 2, 10) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,        mod.OnNewFloor )
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,         mod.OnEnter    )
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,     mod.OnLoad     )
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,         mod.OnExit     )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab, TTCG.SIGIL_OF_KNOWLEDGE.ID)

-- if TCC_API.OnQueueEvent then
--     print("callback exists")
-- else
--     print("callback doesn't exist")
-- end

return TTCG.SIGIL_OF_KNOWLEDGE