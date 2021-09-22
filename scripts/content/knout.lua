-- Thanks to the Crane Game mod for showing me how to give items to a player in a nice looking way
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2106770230


local mod = RegisterMod("Knout", 1)
local sfx = SFXManager()

mod.KNOUT = Isaac.GetItemIdByName("Knout")
mod.EFFECT_VARIANT = Isaac.GetEntityVariantByName("Rot Collection Knout")
mod.COSTUME = Isaac.GetCostumeIdByPath("gfx/characters/rotcol_knout.anm2")

local angles = {
    [0] = {["Dir"] = 180, ["Tag"] = "Left" },  -- LEFT
    [1] = {["Dir"] = 270, ["Tag"] = "Up"   },  -- UP
    [2] = {["Dir"] = 0,   ["Tag"] = "Right"},  -- RIGHT
    [3] = {["Dir"] = 90,  ["Tag"] = "Down" }   -- DOWN
}

function mod:InitKnout(player) -- Create a knout
    local angle = angles[player:GetHeadDirection()]

    if not angle then  -- BACKUP 1
        angle = angles[player:GetFireDirection()]
        if not angle then  -- BACKUP 2
            return false
        end
    end

    local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, mod.EFFECT_VARIANT, 0, player.Position, Vector(0,0), player):ToEffect()
    effect.DepthOffset = player:GetHeadDirection() == 1 and -1 or 10
    effect:FollowParent(player)

    local sprite = effect:GetSprite()
    sprite.Offset = Vector(0, -5)
    sprite:Play("Whip" .. angle.Tag, true)

    effect:Update()

    sfx:Play(SoundEffect.SOUND_WHIP, 0.6, 0, false, 1)

    return (player.Position + Vector(180, 0):Rotated(angle.Dir))
end

function mod:OnPlayerUpdate(player) -- Handle the "spawning" of the knout on shot/charge
    if player:HasCollectible(mod.KNOUT)
    and Game():GetFrameCount() % 10 == 0
    and player:GetCollectibleRNG(mod.KNOUT):RandomInt(math.floor((15-(player.Luck >= 10 and 10 or (player.Luck > 0 and player.Luck or 0))))) <= 1
    and not player:IsHoldingItem()
    and (
        Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) or 
        Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) or 
        Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex) or 
        Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex) or
        Input.IsMouseBtnPressed(0)
    ) then
        local endpoint = mod:InitKnout(player)

        if type(endpoint) == "boolean" then return end

        local hasConnected = false

        for _, ent in pairs(Isaac.FindInRadius(player.Position, 200, 24)) do
            if (endpoint:Distance(ent.Position) < 45 or ((endpoint + player.Position)/2):Distance(ent.Position) < 40) then
                if ent.Type == EntityType.ENTITY_PICKUP then
                    local pickup = ent:ToPickup()
                    if pickup and not pickup:IsShopItem() then
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pickup.Position, Vector(0,0), nil)
                        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.IMPACT, 0, pickup.Position, Vector(0,0), nil)
    
                        pickup.Position = player.Position
    
                        if pickup.Variant == 100 then
                            pickup.TargetPosition = Game():GetRoom():FindFreePickupSpawnPosition(player.Position, 0, true)
                        else
                            pickup:PlayDropSound()
                        end
    
                        pickup:Update()

                        hasConnected = true
                    end
                elseif ent:IsVulnerableEnemy() then
                    local enemy = ent:ToNPC()
                    enemy:TakeDamage(player.Damage*2.5, 0, EntityRef(player), 1)
    
                    if not enemy:IsBoss() or player:GetCollectibleRNG(mod.KNOUT):RandomInt(100)+1 <= 20 then
                        enemy:AddConfusion(EntityRef(player), 99, false)
                    end
    
                    hasConnected = true
                end
            end
        end

        if hasConnected then sfx:Play(SoundEffect.SOUND_WHIP_HIT, 0.6, 0, false, 1) end
    end
end

function mod:OnUpdate(effect, offset) -- Handle the position and despawning of the knout
    if effect:GetSprite():IsEventTriggered("Finished") then effect:Remove() end
end

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.OnUpdate, mod.EFFECT_VARIANT)
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE,  mod.OnPlayerUpdate)

return {
    ID = mod.KNOUT,
    -- KEY = "knout",
    -- OWRP_ID = "rotcol01",
    -- OWRP_NAME = "The Scourge",
    -- OWRP_LOCK = false,
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_ROTTEN_BEGGAR,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTION = "Chance to shoot a whip#This whip stuns enemies#This whip can pick up items",
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Knout", DESC = "Chance to shoot a whip#This whip stuns enemies#This whip can pick up items" },
        { LANG = "ru",    NAME = "Хлыст", DESC = "Дает шанс выстрелить хлыстом в направлении стрельбы#Может оглушать врагов#Может подбирать предметы" },
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "While shooting or charging the player has a chance to shoot out a whip in the same direction"},
            {str = "This whip will permanently stun normal enemies"},
            {str = "This whip will also slow both normal enemies and bosses"},
            {str = "If the whip hits consumables, items or chests they will be dragged towards the player"}
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'This item is inspired by "The Scourge"'},
            {str = 'The whip is a reskin of the whips shot by "Snappers"'},
            {str = 'Credit to the "Crane Game mod" which was used as an example for some of the code used for this item'},
            {str = 'Crane Game mod: steamcommunity.com/sharedfiles/ filedetails/?id=2106770230'}
        },
    }
}