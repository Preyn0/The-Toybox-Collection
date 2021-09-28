--[[##########################################################################
######################## MOD CONTENT IMPORT AND SETUP ########################
##########################################################################]]--
TTCG = RegisterMod("The Toybox Collection", 1)

TTCG.SAVEDATA = {}
TTCG.SFX = SFXManager()
TTCG.GAME = Game()

--TODO: API custom sounds are currently broken. Keep an eye out for this possibly being fixed!

-- Define content and path
local path = 'scripts.content.'
local content = { 'ancestral_assistance', 'old_relic', 'blank', 'concussion', 'wow_factor', 'jar_of_air', 'witch_wand', 'sigil_of_knowledge', 'blood_of_the_abyss' }

require('scripts.toycol_callbacks') -- Import custom/shared callbacks

function TTCG.SharedOnGrab(sound)
    TTCG.SFX:Play(sound, 1, 10) 
    TTCG.SFX:Stop(SoundEffect.SOUND_CHOIR_UNLOCK)
end

function TTCG.SharedHas(id)
    local numPlayers = TTCG.GAME:GetNumPlayers()

    for i=1,numPlayers do
        local player = TTCG.GAME:GetPlayer(tostring((i-1)))
        
        if player:HasCollectible(id) then
            return player
        end
    end

    return false
end

function TTCG.GetShooter(ent)
    if ent and ent.SpawnerType == EntityType.ENTITY_PLAYER then
        if ent.SpawnerEntity ~= nil then
            return ent.SpawnerEntity:ToPlayer()
        elseif ent.Parent ~= nil then
            return ent.Parent:ToPlayer()
        end
    end

    return nil
end

-- Import content
local contentImports = {}
for _, title in pairs(content) do table.insert(contentImports, require(path .. title)) end
contentImports = TCC_API:InitContent(contentImports, "Toybox Collection")

--[[ ### DEV CODE ### --
local function loadItems()
    if TTCG.GAME:GetFrameCount() == 0 then
        local offset = 0
        local offsetY = 0
        for _, item in ipairs(contentImports) do
            if item.SHOW_DEV or true then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, item.TYPE, item.ID, Vector(320+offset, 300-offsetY), Vector(0, 0), nil)

                if item.TYPE == 350 then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, item.TYPE, item.ID+32768, Vector(320+offset, 300-offsetY), Vector(0, 0), nil)
                end

                if offset == -200 then
                    offset = 0
                    offsetY = offsetY+50
                elseif offset == 0 then
                    offset = 50
                elseif offset > 0 then
                    offset = offset - (offset*2)
                else
                    offset = -1*offset+50
                end
            end
        end
    end
end

TTCG:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, loadItems);
-- ### END DEV CODE ### ]]--