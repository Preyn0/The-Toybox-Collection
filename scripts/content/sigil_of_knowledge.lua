local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
local item = {
    ID = Isaac.GetItemIdByName("Sigil of knowledge"),
    EFFECT = Isaac.GetEntityVariantByName("Sigil text"),

    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_SIGIL_PICKUP"),
    TRIGGER_SFX = SoundEffect.SOUND_BLACK_POOF, --Isaac.GetSoundIdByName("TOYCOL_SIGIL_TRIGGER"),

    CLEAR_PERCENT = 55,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Sigil of knowledge", DESC = "Reveals the map after enough rooms have been explored" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "After exploring 55% (or higher) of the floors room the map will be revealed and secret rooms will be opened."},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "Dead cells".'},
            {str = "The item and it's effects reference the " .. '"' .. "Explorer's Rune" .. '"' .. " that can be found in the game."},
        }
    }
}

local clearData = nil

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
local function revealUltra(level)
    for i = 0, 169 do -- 13*13 is void floor size
        local room = level:GetRoomByIdx(i)
        
        if room.Data and room.Data.Type == RoomType.ROOM_ULTRASECRET then
            if room.DisplayFlags & 1 << 2 == 0 then
                room.DisplayFlags = room.DisplayFlags | 1 << 2
                return
            end
        end
    end
end

function item:OnNewFloor()
    if clearData then
        TTCG.SAVEDATA.SIGIL_OF_KNOWLEDGE = nil
        clearData = { clearCount = 0, hasTriggered = false } 
    end
end


function item:OnEnter()
    if clearData and not clearData.hasTriggered and TTCG.GAME:GetRoom():IsFirstVisit() then
        local player = TTCG.SharedHas(item.ID)
            
        if player then
            clearData.clearCount = clearData.clearCount+1

            local level = TTCG.GAME:GetLevel()
            if clearData.clearCount >= (level:GetRooms().Size/100*item.CLEAR_PERCENT) then
                
                -- Trigger mechanical effect
                level:SetCanSeeEverything(true)
                level:RemoveCurses(LevelCurse.CURSE_OF_DARKNESS | LevelCurse.CURSE_OF_THE_LOST)

                level:ApplyBlueMapEffect()
                level:ApplyCompassEffect(true)
                level:ApplyMapEffect()

                revealUltra(level)

                level:UpdateVisibility()
                
                -- Trigger visuals
                local SigilEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, item.EFFECT, 1, Vector(320, 300), Vector(0,0), player)
                SigilEffect:GetSprite():Play('Idle')
                SigilEffect.DepthOffset = 10000
                SigilEffect:Update()

                SigilEffect:GetSprite():Render(Vector(360, 300), Vector(0,0), Vector(0,0));

                -- Trigger SFX
                TTCG.SFX:Play(item.TRIGGER_SFX, 1.5, 0, false, 0.75)

                -- Update state
                clearData.hasTriggered = true
            end
        end
    end
end

function item:OnLoad(isContinued)
    -- Reset save if new run
    if isContinued then
        local loadStatus, LoadValue = pcall(json.decode, TTCG:LoadData())
        
        if loadStatus and LoadValue["SIGIL_OF_KNOWLEDGE"] then
            clearData = LoadValue["SIGIL_OF_KNOWLEDGE"]
            return
        end
    end

    
    TTCG.SAVEDATA.SIGIL_OF_KNOWLEDGE = nil
    clearData = { clearCount = 0, hasTriggered = false }
    TTCG:SaveData(json.encode(TTCG.SAVEDATA))
end

function item:OnExit()
    TTCG.SAVEDATA.SIGIL_OF_KNOWLEDGE = clearData
	TTCG:SaveData(json.encode(TTCG.SAVEDATA))
    clearData = nil
end

function item:OnGrab() TTCG.SharedOnGrab(item.PICKUP_SFX) end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
TTCG:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,        item.OnNewFloor)
TTCG:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,         item.OnEnter   )
TTCG:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,     item.OnLoad    )
TTCG:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,         item.OnExit    )

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", item.OnGrab, item.ID)

return item