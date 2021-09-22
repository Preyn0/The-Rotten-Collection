local mod = RegisterMod("Cube of rot", 1)
local sfx = SFXManager()
mod.CUBE_OF_ROT = Isaac.GetItemIdByName("Cube of rot")
mod.VARIANT = Isaac.GetEntityVariantByName("Cube of rot")

local hasReskinned = 0
local hasBeenCollected = false
local currentCubeState = {
    OrbitSpeed = 0.02,
    OrbitDistance = Vector(70, 70),
    ProcessState = 0
}

--[[##########################################################################
############################## STATE MANAGEMENT ##############################
##########################################################################]]--
function mod:OnLoad(isContinue) -- Reset settings when a new run is started
    if not isContinue then
        hasBeenCollected = false
        hasReskinned = 0
        currentCubeState = {
            OrbitSpeed = 0.02,
            OrbitDistance = Vector(70, 70),
            ProcessState = 0
        }
    end
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnLoad);

--[[##########################################################################
############################# CUBE OF ROT LOGIC ##############################
##########################################################################]]--
function mod:OnInit(cubeOfRot) -- Initialize familiar
    hasBeenCollected = true
    cubeOfRot:GetSprite():Play("Float")
    cubeOfRot:AddToFollowers()
    cubeOfRot:AddToOrbit(95)
	cubeOfRot.OrbitDistance = Vector(70, 70)
	cubeOfRot.OrbitSpeed = 0.02
end

function mod:OnUpdate(cubeOfRot) -- Handle familiar animations, updating and teleportation
    local player = cubeOfRot.Player
    local sprite = cubeOfRot:GetSprite()
    local room = Game():GetRoom()

    if Game():GetFrameCount() % 120 == 0 and room:GetAliveEnemiesCount() ~= 0 then
        currentCubeState.ProcessState = 1
        sfx:Play(SoundEffect.SOUND_PLOP, 0.7, 10, false, 1)
        sprite:Play("Dissapear", false)
    end

    if sprite:IsEventTriggered("Appear") then
        sprite:Play("Float", false) 
    end

    if sprite:IsEventTriggered("Dissapear") then
        if currentCubeState.ProcessState == 1 then
            local randomDistance = math.random(40, 80)
            currentCubeState = {
                OrbitSpeed = math.random(1, 4)/100,
                OrbitDistance = Vector(randomDistance, randomDistance),
                -- OrbitAngleOffset = (math.random(-360, 360)/100),
                ProcessState = 2
            }
        end
        sprite:Play("Appear", false)
    end

    cubeOfRot.OrbitDistance = currentCubeState.OrbitDistance
    cubeOfRot.OrbitSpeed = currentCubeState.OrbitSpeed
    cubeOfRot.Velocity = cubeOfRot:GetOrbitPosition(player.Position + player.Velocity) - cubeOfRot.Position
end

function mod:OnCollision(cubeOfRot, entity, _) -- Poison enemies on contact
    if entity.Type == EntityType.ENTITY_PROJECTILE then entity:Remove()
    elseif entity:IsVulnerableEnemy() then entity:AddPoison(EntityRef(cubeOfRot), 30, 1) end
end

function mod:OnCacheUpdate(player, flag) -- Reset familiar(s) on change
    if flag == CacheFlag.CACHE_FAMILIARS then
        player:CheckFamiliar(mod.VARIANT, player:GetCollectibleNum(mod.CUBE_OF_ROT), player:GetCollectibleRNG(mod.CUBE_OF_ROT))
    end
end

mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,          mod.OnInit,       mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,        mod.OnUpdate,     mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.OnCollision,  mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,         mod.OnCacheUpdate            )

--[[##########################################################################
######################### COLLECTIBLE SPAWNING LOGIC #########################
##########################################################################]]--
function mod:OnPickupSpawn(collectible) -- Potentially replace cube of meat/ball of bandages spawns with cube of rot
    if not hasBeenCollected and (collectible.SubType == 73 or collectible.SubType == 207) and math.random(1,5) > 4 then
        local numPlayers = Game():GetNumPlayers()
        local isBlacklisted = false

        for i=1,numPlayers do
            local player = Game():GetPlayer(tostring((i-1)))

            if player:HasCollectible(CollectibleType.COLLECTIBLE_BINGE_EATER) 
            or player:HasCollectible(CollectibleType.COLLECTIBLE_GLITCHED_CROWN) 
            or player:GetPlayerType() == PlayerType.PLAYER_ISAAC_B then
                isBlacklisted = true
            end
        end

        if not isBlacklisted then
            collectible.SubType = mod.CUBE_OF_ROT
            local sprite = collectible:GetSprite()
            sprite:ReplaceSpritesheet ( 1, "gfx/items/collectibles/cube_of_rot.png")
            sprite:LoadGraphics()
            sprite:Update()
            sprite:Render(collectible.Position, Vector(0,0), Vector(0,0))
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.OnPickupSpawn, PickupVariant.PICKUP_COLLECTIBLE) -- Replace collectible spawns with cube of rot by chance

--[[##########################################################################
############################# MEATBOY SYNERGIES ##############################
##########################################################################]]--
local function HandleMeatboyReskin(meatboy, isReset) -- Apply or remove special synergy skin for meatboy follower
    local player = meatboy.Player
    local sprite = meatboy:GetSprite()

    if isReset then
        sprite:Reload()
        hasReskinned = (hasReskinned > 4 and (hasReskinned-4) or 0)
    else
        if meatboy.Variant == 44 then
            sprite:ReplaceSpritesheet (0, "gfx/familiar/rotcol_familiar_other_01_cubeofmeatlevel1.png") --Give special sprite
        end

        if meatboy.Variant == 45 then
            sprite:ReplaceSpritesheet (0, "gfx/familiar/rotcol_familiar_other_02_cubeofmeatlevel2.png") --Give special sprite
        end

        if meatboy.Variant == 46 then
            sprite:ReplaceSpritesheet (0, "gfx/familiar/rotcol_monster_000_bodies01b.png") --Body
            sprite:ReplaceSpritesheet (1, "gfx/familiar/rotcol_familiar_other_03_cubeofmeatlevel3.png") --Head
        end

        if meatboy.Variant == 47 then
            sprite:ReplaceSpritesheet (0, "gfx/familiar/rotcol_monster_000_bodies01b.png") --Body
            sprite:ReplaceSpritesheet (1, "gfx/familiar/rotcol_familiar_other_04_cubeofmeatlevel4.png") --Head
        end

        hasReskinned = (meatboy.Player:GetCollectibleNum(73) >= hasReskinned and (hasReskinned+4) or meatboy.Player:GetCollectibleNum(73))
    end

    sprite:LoadGraphics()
end

function mod:OnMeatCollision(meatboy, entity, _) -- Allow meatboy to apply poision to collided enemies
    if meatboy.Player:HasCollectible(mod.CUBE_OF_ROT) and entity:IsVulnerableEnemy() then entity:AddPoison(EntityRef(meatboy), 30, 1) end
end

function mod:OnMeatOrbitUpdate(meatboy) -- Allow meatboy orbital to teleport (every 120 frames) and handle adding/removing skins
    if meatboy.Player:HasCollectible(mod.CUBE_OF_ROT) then
        local room = Game():GetRoom()

        if room:GetAliveEnemiesCount() ~= 0 and Game():GetFrameCount() % 120 == 0 then
            meatboy:SetColor(Color(1, 1, 1, 1, 255, 255, 255), 5, 1, false, false)
            meatboy.OrbitAngleOffset = math.random(-360, 360)/100
        end

        if hasReskinned < meatboy.Player:GetCollectibleNum(73) then HandleMeatboyReskin(meatboy, false) end

        if meatboy.Variant == 45 then
            local entities = Isaac.FindByType(EntityType.ENTITY_TEAR)
            for i = 1, #entities do
                if entities[i].Type == 2 and entities[i].SpawnerType == 3 and entities[i].SpawnerVariant == 45 then
                    entities[i]:ToTear().TearFlags = entities[i]:ToTear().TearFlags | TearFlags.TEAR_POISON
                end
            end
        end
    elseif hasReskinned and not meatboy.Player:HasCollectible(mod.CUBE_OF_ROT) then
        HandleMeatboyReskin(meatboy, true)
    end
end

function mod:OnMeatWalkUpdate(meatboy) -- Allow meatboy to teleport (every 120 frames) and handle adding/removing skins
    if meatboy.Player:HasCollectible(mod.CUBE_OF_ROT) then
        local room = Game():GetRoom()

        if hasReskinned < meatboy.Player:GetCollectibleNum(73) then HandleMeatboyReskin(meatboy, false) end

        if room:GetAliveEnemiesCount() ~= 0 and Game():GetFrameCount() % 120 == 0 then
            local enemies = Isaac.GetRoomEntities()

            for i = 1, #enemies do
                if enemies[i]:IsVulnerableEnemy() then 
                    local enemy = enemies[i]

                    local poof = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, meatboy.Position, Vector(0,0), nil)
                    poof:SetColor(Color(0.91, 0.83, 0.74, 1, 0, 0, 0), 0, 1, false, false)
                    meatboy:SetColor(Color(1, 1, 1, 1, 255, 255, 255), 5, 1, false, false)
                    meatboy.Position = enemy.Position
                    return nil
                end
            end
        end
    elseif hasReskinned and not meatboy.Player:HasCollectible(mod.CUBE_OF_ROT) then
        HandleMeatboyReskin(meatboy, true)
    end
end

function mod:OnMeatInit(meatboy) HandleMeatboyReskin(meatboy) end -- Reskin meatboy on spawn

mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.OnMeatCollision,    44) -- Level 1 poision contact synergy
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.OnMeatCollision,    45) -- Level 2 poision contact synergy
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.OnMeatCollision,    46) -- Level 3 poision contact synergy
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, mod.OnMeatCollision,    47) -- Level 4 poision contact synergy
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,        mod.OnMeatOrbitUpdate,  44) -- Level 1 orbit teleportation synergy 
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,        mod.OnMeatOrbitUpdate,  45) -- Level 1 orbit teleportation and poision shooting synergy 
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,        mod.OnMeatWalkUpdate,   46) -- Level 3 walking teleportation synergy
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,        mod.OnMeatWalkUpdate,   47) -- Level 4 walking teleportation synergy
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,          mod.OnMeatInit,         44) -- Replace level 1 textures
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,          mod.OnMeatInit,         45) -- Replace level 2 textures
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,          mod.OnMeatInit,         46) -- Replace level 3 textures
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,          mod.OnMeatInit,         47) -- Replace level 4 textures

return { 
    ID = mod.CUBE_OF_ROT, 
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_BABY_SHOP,
        ItemPoolType.POOL_ROTTEN_BEGGAR,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Cube of rot", DESC = "Orbits around the player#Randomly teleports#Poisons on contact#Blocks projectiles" },
        { LANG = "ru",    NAME = "Кубик гнили", DESC = "Летает вокруг игрока#Случайно телепортируется#Отравляет врагов при контакте#Блокирует выстрелы" },
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Grants a follower that orbits the player"},
            {str = "Occasionally teleports"},
            {str = "Orbit position, speed and distance will change when teleporting"},
            {str = "Poisons and damages enemies on contact"}
        },
        { -- Spawning
            {str = "Spawing", fsize = 2, clr = 3, halign = 0},
            {str = 'Even though this item is not within the boss pool. When "cube of meat" or "ball of bandages" spawn there is a 1/5 chance that it will be replaced by this item'}
        },
        { -- Synergies
            {str = "Synergies", fsize = 2, clr = 3, halign = 0},
            {str = 'Level 1 and Level 2 "Cube of meat" will occasionally teleport to a different orbit position'},
            {str = 'Level 2 "Cube of meat" will shoot poison shots'},
            {str = 'Level 3 and Level 4 "Cube of meat" will occasionally teleport towards a random enemy'},
            {str = 'All levels of "Cube of meat" will poison enemies on contact'},
            {str = 'All levels of "Cube of meat" will gain a different sprite'}
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'Credit to the "Custom Mr Dollies mod" which was used as an example for some of the code used for this item'},
            {str = 'Custom Mr Dollies mod: steamcommunity.com/sharedfiles/ filedetails/?id=2489635144'}
        }
    }
}
