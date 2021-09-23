TTCG = RegisterMod("The Toybox Collection", 1)

local json = require("json")

--[[##########################################################################
######################## MOD CONTENT IMPORT AND SETUP ########################
##########################################################################]]--

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

-- Import content
local contentImports = {}
for _, title in pairs(content) do table.insert(contentImports, require(path .. title)) end

for _, item in ipairs(contentImports) do
    if EID and item.EID_DESCRIPTIONS then
        for i=1, #item.EID_DESCRIPTIONS do
            if item.TYPE == 100 then
                EID:addCollectible(item.ID, item.EID_DESCRIPTIONS[i].DESC, item.EID_DESCRIPTIONS[i].NAME, item.EID_DESCRIPTIONS[i].LANG)
            else
                EID:addTrinket(item.ID, item.EID_DESCRIPTIONS[i].DESC, item.EID_DESCRIPTIONS[i].NAME, item.EID_DESCRIPTIONS[i].LANG)
            end
        end
    end
    
    if Encyclopedia and (item.EID_DESCRIPTIONS or item.ENC_DESCRIPTION) then
        if item.TYPE == 100 then
            local pools = {}
            if item.POOLS then
                for i, pool in ipairs(item.POOLS) do table.insert(pools, (pool+1)) end    
            end
            Encyclopedia.AddItem({
                Class = "Toybox Collection",
                ModName= "Toybox Collection",
                ID = item.ID,
                WikiDesc = item.ENC_DESCRIPTION and item.ENC_DESCRIPTION or Encyclopedia.EIDtoWiki(item.EID_DESCRIPTIONS[1].DESC),
                Pools = pools
            })    
        else
            Encyclopedia.AddTrinket({
                Class = "Toybox Collection",
                ModName= "Toybox Collection",
                ID = item.ID,
                WikiDesc = item.ENC_DESCRIPTION and item.ENC_DESCRIPTION or Encyclopedia.EIDtoWiki(item.EID_DESCRIPTIONS[1].DESC)
            }) 
        end
    end
end

---[[ ### DEV CODE ### --
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