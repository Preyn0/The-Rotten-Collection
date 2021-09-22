local mod = RegisterMod("Rotten gut", 1);
local sfx = SFXManager()
mod.ROTTEN_GUT = Isaac.GetItemIdByName("Rotten gut")
mod.VARIANT = Isaac.GetEntityVariantByName("Rotten gut")

function mod:OnInit(rottenGut)
    local sprite = rottenGut:GetSprite()
    sprite:SetOverlayRenderPriority(true)
end

function mod:OnUpdate(rottenGut)
    rottenGut.Velocity = Vector(0,0)
    local sprite = rottenGut:GetSprite()
    local room = Game():GetRoom()

    if room:GetAliveEnemiesCount() == 0 then
        if sprite:IsPlaying('Suck') then
            sprite:RemoveOverlay()
            sprite:Play('Dissapear', false)
        end

        if sprite:IsEventTriggered("Dissapear") or sprite:IsPlaying("Appear") then sprite:Play("Hidden", false) end
    else
        if sprite:IsPlaying('Hidden') then
            rottenGut.Position = room:FindFreePickupSpawnPosition(room:GetRandomPosition(0))
            sprite:Play("Appear", false) 
        end

        if sprite:IsEventTriggered("Appear") then
            sprite:Play("Suck", false)
            sprite:PlayOverlay("Suction", false)
        end

        if sprite:IsPlaying('Suck') then
            local hasBFF = rottenGut.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS)
            local entities = Isaac.FindInRadius(rottenGut.Position, 120 * (hasBFF and 1.5 or 1))
            for i = 1, #entities do
                if entities[i].Type == EntityType.ENTITY_PLAYER then 
                    entities[i]:AddVelocity((rottenGut.Position - entities[i].Position):Normalized() * 0.25)
                elseif entities[i]:IsVulnerableEnemy() or entities[i].Type == EntityType.ENTITY_PICKUP or entities[i].Type == EntityType.ENTITY_PROJECTILE then
                    if entities[i].Mass < 60 then entities[i]:AddVelocity((rottenGut.Position - entities[i].Position):Normalized() * (hasBFF and 3 or 2)) end
                end
            end
        end
    end
end

function mod:OnCollision(_, entity, _)
    if entity.Type == EntityType.ENTITY_PROJECTILE then entity:Remove() end
end

function mod:OnCacheUpdate(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        player:CheckFamiliar(mod.VARIANT, player:GetCollectibleNum(mod.ROTTEN_GUT), player:GetCollectibleRNG(mod.ROTTEN_GUT))
    end
end

mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,          mod.OnInit,      mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,        mod.OnUpdate,    mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.OnCollision, mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,         mod.OnCacheUpdate           )

return {
    ID = mod.ROTTEN_GUT,
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_BABY_SHOP,
        ItemPoolType.POOL_ROTTEN_BEGGAR,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Rotten gut",      DESC = "Appears at a random position in the room#Sucks everything towards it#Damages enemies and blocks projectiles" },
        { LANG = "ru",    NAME = "Гнилой кишечник", DESC = "Появляется в случайном месте комнаты#Засасывает все к себе#Наносит контактный урон врагам и засасывает их выстрелы" },
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Teleports to a random position in the room"},
            {str = "While in combat starts sucking enemies, projectiles and consumables into it"},
            {str = "Can block projectiles"},
            {str = "Damages enemies touching it"},
        },
        { -- Synergies
            {str = "Synergies", fsize = 2, clr = 3, halign = 0},
            {str = "While holding BFFS! it's sucking range and strength are increased by 1.5x"}
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'The sucking animation for this follower was directly taken from the "Stone Grimace" variant "Gaping Maw"'},
            {str = 'Credit to the "Black hole mod" (Was added to the game in a booster pack) which was used as an example for some of the code used for this item'},
            {str = 'Black hole mod: steamcommunity.com/sharedfiles/ filedetails/?id=840640979'}
        }
    }
}
