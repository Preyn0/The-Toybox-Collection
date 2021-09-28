local mod = RegisterMod("Concussion", 1)
local json = require("json")

--##############################################################################--
--#################################### DATA ####################################--
--##############################################################################--
TTCG.CONCUSSION = {
    ID = Isaac.GetItemIdByName("Concussion"),
    
    PICKUP_SFX = SoundEffect.SOUND_1UP, --Isaac.GetSoundIdByName("TOYCOL_CONCUSSION_PICKUP"),
    HIT_SFX = SoundEffect.SOUND_WHIP_HIT, --Isaac.GetSoundIdByName("TOYCOL_CONCUSSION_HIT"),
    SWIPE_SFX = SoundEffect.SOUND_SWORD_SPIN,

    SWIPE_GFX = Isaac.GetEntityVariantByName("TOYCOL_CONCUSSION_SWIPE"),
    HIT_STAR_GFX = Isaac.GetEntityVariantByName("TOYCOL_CONCUSSION_HIT_STAR"),
    HIT_LINE_GFX = Isaac.GetEntityVariantByName("TOYCOL_CONCUSSION_HIT_LINE"),

    RADIUS = 100,
    BOSS_CHANCE = 30,
    DAMAGE_MULTIPLIER = 2.5,

    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_DEVIL,
        ItemPoolType.POOL_RED_CHEST,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_DEVIL,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Concussion", DESC = "Pushes, confuses and damages enemies#Enters your pocket upon pickup if possible" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Upon use pushes, confuses and damages (2.5x the players damage) enemies that are closeby."},
            {str = "If the player has an empty pocket then the item will enter their pocket instead of their active slot."},
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is a reference to the game "ScourgeBringer".'},
            {str = 'The item is referencing the "Concussion" skill that can be unlocked in the game.'},
        }
    }
}

local swipeDirections = {
    [Direction.NO_DIRECTION] = 270,
    [Direction.LEFT] = 0,
    [Direction.UP] = 90,
    [Direction.RIGHT] = 180,
    [Direction.DOWN] = 270,
}

--##############################################################################--
--################################# ITEM LOGIC #################################--
--##############################################################################--
function mod:OnUse(_, RNG, player, _, _, _)
    local entities = Isaac.FindInRadius(player.Position, TTCG.CONCUSSION.RADIUS, 26)
    local hasHit = false

    for i=1, #entities do
        local ent = entities[i]

        if ent.Type == EntityType.ENTITY_PROJECTILE then
            ent:Remove()
            Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 0, ent.Position, ent.Velocity:Rotated(180), player)
        elseif (ent.Type == EntityType.ENTITY_PICKUP or ent.Type == EntityType.ENTITY_BOMBDROP) then
            ent:AddVelocity((ent.Position - player.Position):Normalized()*10)
        elseif ent.Type ~= EntityType.ENTITY_PLAYER and ent:IsActiveEnemy(false) then
            ent:AddEntityFlags(EntityFlag.FLAG_KNOCKED_BACK | EntityFlag.FLAG_APPLY_IMPACT_DAMAGE | EntityFlag.FLAG_AMBUSH)
            ent:AddVelocity((ent.Position - player.Position):Normalized()*45)
            ent:TakeDamage(player.Damage*TTCG.CONCUSSION.DAMAGE_MULTIPLIER, (DamageFlag.DAMAGE_EXPLOSION | DamageFlag.DAMAGE_CRUSH), EntityRef(player), 0)
        
            if not ent:IsBoss() or RNG:RandomInt(100)+1 <= TTCG.CONCUSSION.BOSS_CHANCE then
                ent:AddConfusion(EntityRef(player), 90, true)
            end

            ent:SetColor(Color(1, 1, 1, 1, 0.99, 0.10, 0.40), 15, 99, true, false)

            local starGfx = TTCG.GAME:Spawn(EntityType.ENTITY_EFFECT, TTCG.CONCUSSION.HIT_STAR_GFX, ent.Position, Vector(0,0), nil, 1, 0):ToEffect()
            starGfx:GetSprite().Rotation = math.random(360)
            starGfx.DepthOffset = ent.DepthOffset + 100
            starGfx:Update()

            local lineGfx = TTCG.GAME:Spawn(EntityType.ENTITY_EFFECT, TTCG.CONCUSSION.HIT_LINE_GFX, ent.Position, Vector(0,0), nil, 1, 0):ToEffect()
            lineGfx:GetSprite().Rotation = (player.Position - ent.Position):GetAngleDegrees()
            lineGfx.DepthOffset = starGfx.DepthOffset + 100
            lineGfx:Update()

            hasHit = true
        end
    end

    local swipe = TTCG.GAME:Spawn(EntityType.ENTITY_EFFECT, TTCG.CONCUSSION.SWIPE_GFX, player.Position + Vector(0, -20), Vector(0,0), nil, 1, 0):ToEffect()
    swipe.DepthOffset = player.DepthOffset + 100
    swipe:GetSprite().Rotation = swipeDirections[player:GetHeadDirection()]
    swipe:FollowParent(player)
    swipe:Update()

    TTCG.SFX:Play(TTCG.CONCUSSION.SWIPE_SFX, 1, 0)

    if hasHit then
        TTCG.GAME:ShakeScreen(16)
        TTCG.SFX:Play(TTCG.CONCUSSION.HIT_SFX, 3, 0, false, 0.65)
    end
end

function mod:OnGrab() TTCG.SharedOnGrab(TTCG.CONCUSSION.PICKUP_SFX) end

function mod:OnCollect(player)
    if player:GetActiveItem(ActiveSlot.SLOT_POCKET) == 0 then
        if player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == TTCG.CONCUSSION.ID or player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) == TTCG.CONCUSSION.ID then
            player:RemoveCollectible(TTCG.CONCUSSION.ID)
            player:SetPocketActiveItem(TTCG.CONCUSSION.ID, ActiveSlot.SLOT_POCKET, false)
        end
    end
end

--##############################################################################--
--############################ CALLBACKS AND EXPORT ############################--
--##############################################################################--
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnUse, TTCG.CONCUSSION.ID)

TCC_API:AddTTCCallback("TCC_ENTER_QUEUE", mod.OnGrab,    TTCG.CONCUSSION.ID)
TCC_API:AddTTCCallback("TCC_EXIT_QUEUE",  mod.OnCollect, TTCG.CONCUSSION.ID)

return TTCG.CONCUSSION