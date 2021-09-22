local mod = RegisterMod("Sick maggot", 1)
mod.SICK_MAGGOT = Isaac.GetTrinketIdByName("Sick maggot")

local rottenHearts = {}

function mod:OnLoad(_) rottenHearts = {} end

function mod:HandleHealth(player) -- Grant red health when a rotten heart is lost
    if player:HasTrinket(mod.SICK_MAGGOT) then
        local identifier = player.ControllerIndex..","..player:GetPlayerType()
        if rottenHearts[identifier] == nil or rottenHearts[identifier] < player:GetRottenHearts() then
            rottenHearts[identifier] = player:GetRottenHearts()
        elseif rottenHearts[identifier] > player:GetRottenHearts() then
            player:AddHearts(player:GetTrinketMultiplier(mod.SICK_MAGGOT))
            -- player:AddBlueFlies(5, player.Position, nil) -- Possible extra feature
            rottenHearts[identifier] = player:GetRottenHearts() 
        end
    end
end

function mod:HandleHeal(pickup, collider, low) -- Give the player rotten health when colliding with red hearts when possible
    if collider.Type == EntityType.ENTITY_PLAYER
    and collider:ToPlayer():HasTrinket(mod.SICK_MAGGOT)
    and (pickup.SubType == HeartSubType.HEART_FULL or pickup.SubType == HeartSubType.HEART_HALF or pickup.SubType == HeartSubType.HEART_DOUBLEPACK)
    and not pickup:ToPickup():IsShopItem()
    and not collider:ToPlayer():CanPickRedHearts()
    and collider:ToPlayer():CanPickRottenHearts() 
    then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LEECH_EXPLOSION, 0, pickup.Position, RandomVector() * ((math.random() * 2) + 1), nil)
        for i = 1, 4 do   
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_PARTICLE, 0, pickup.Position, RandomVector() * ((math.random() * 2) + 1), nil)
        end
    
        SFXManager():Play(SoundEffect.SOUND_ROTTEN_HEART, 1, 0, false, 1)
        collider:ToPlayer():AddRottenHearts((pickup.SubType == HeartSubType.HEART_DOUBLEPACK and 4 or 2))
        pickup:Remove()

        return true
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE,   mod.HandleHealth                            )
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED,    mod.OnLoad                                  )
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, mod.HandleHeal,   PickupVariant.PICKUP_HEART)

return { 
    ID = mod.SICK_MAGGOT,
    TYPE = 350,
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Sick maggot",     DESC = "{{HalfHeart}} Rotten hearts turn into half red hearts when lost#{{RottenHeart}} Red hearts turn into rotten hearts while at full health" },
        { LANG = "ru",    NAME = "Больная личинка", DESC = "{{HalfHeart}} Гнилые сердца превращаются в половину красных сердец, когда теряются#{{RottenHeart}} Красные сердца превращаются в гнилые сердца при полном здоровье" },
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "When losing a rotten heart the heart gets replaced by red heart(s)"},
            {str = "The amount of red health changes based on the trinket multiplier"},
            {str = "Default: Half a heart, Gold/Mom's Box: a full heart, Both: 1,5 hearts, etc..."},
            {str = "When at full health red hearts picked up will be transformed into rotten hearts if the player can hold them"},
        }
    }
}