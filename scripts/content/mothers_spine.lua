local mod = RegisterMod("Mother's spine", 1)
mod.MOTHERS_SPINE = Isaac.GetItemIdByName("Mother's spine")
mod.VARIANT = Isaac.GetEntityVariantByName("Mother's spine")

local lasers = {}

function mod:OnInit(mothersSpine) -- Initialize familiar
    mothersSpine:AddToFollowers()
    mothersSpine:AddToOrbit(90)
	mothersSpine.OrbitDistance = Vector(50, 50) 
	mothersSpine.OrbitSpeed = 0.006
    mothersSpine.SpriteRotation = (mothersSpine.Player.Position - mothersSpine.Position):GetAngleDegrees()
end

function mod:OnUpdate(mothersSpine) -- Create a laser for the familiar if one doesn't exist. Otherwise change it's rotation to match it's familiar 
    local player = mothersSpine.Player
    local angle = (player.Position - mothersSpine.Position):GetAngleDegrees()

    if lasers[mothersSpine.Index] and lasers[mothersSpine.Index]:Exists() then
        lasers[mothersSpine.Index].Angle = angle-180
    else
        local laser = EntityLaser.ShootAngle(2, player.Position, angle-180, 0, Vector(0,0), player)
        laser.CollisionDamage = player.Damage*(player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and 1.5 or 0.05)
        laser.TearFlags = TearFlags.TEAR_POISON
        laser.Visible = false
        lasers[mothersSpine.Index] = laser
    end

    mothersSpine.SpriteRotation = angle
	mothersSpine.OrbitDistance = Vector(50, 50)
	mothersSpine.OrbitSpeed = 0.01
    mothersSpine.Velocity = mothersSpine:GetOrbitPosition(player.Position + player.Velocity) - mothersSpine.Position
end

function mod:OnCacheTrigger(player, flag) -- Reset familiar(s) and remove lasers on change 
    if flag == CacheFlag.CACHE_FAMILIARS then
        for i in pairs(lasers) do lasers[i]:Remove() end
        player:CheckFamiliar(mod.VARIANT, player:GetCollectibleNum(mod.MOTHERS_SPINE), player:GetCollectibleRNG(mod.MOTHERS_SPINE))
    end
end

function mod:ResetLasers() lasers = {} end -- Remove lasers from state when room is changed

mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,      mod.OnInit,        mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,    mod.OnUpdate,      mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,      mod.ResetLasers               )
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,     mod.OnCacheTrigger            )

return { 
    ID = mod.MOTHERS_SPINE,
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_BABY_SHOP,
        ItemPoolType.POOL_ROTTEN_BEGGAR,
        ItemPoolType.POOL_MOMS_CHEST,
        ItemPoolType.POOL_OLD_CHEST,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Mother's spine",    DESC = "Orbits around the player#Poisons, damages and pushes enemies in line with it" },
        { LANG = "ru",    NAME = "Мамин позвоночник", DESC = "Летает вокруг игрока#При касании к врагам отравляет их и наносит контактный урон" },
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Grants a follower that orbits the player"},
            {str = 'Enemies that are being "pointed at" by the familiar will be poisoned, damaged and pushed'},
        },
        { -- Synergies
            {str = "Synergies", fsize = 2, clr = 3, halign = 0},
            {str = 'While holding BFFS! enemies "pointed at" will take 1.5x the players damage'}
        },
    }
}