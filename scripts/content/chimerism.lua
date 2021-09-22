local mod = RegisterMod("Chimerism", 1)
local data = require("scripts.datamanager")
local game = Game()
local json = require("json")
mod.CHIMERISM = Isaac.GetItemIdByName("Chimerism")

-- Mod settings
mod.CONFIG = {
    -- Max stats per room limiters
    BOSS_LIMIT = 4,
    MINI_LIMIT = 4,
    ENEMY_LIMIT = 15,

    -- Granted stats
    LUCK = 1,
    DAMAGE = 0.5,
    SPEED = 0.05,
    SHOTSPEED = 0.05,

    -- Do not run stat logic for enemies with armour (can't seem to find a way to find their "armour" value via the API so disabling is the only option)
    DEF_BLACKLIST = {
        [300] = true -- ENTITY_MUSHROOM
    },

    -- Enemies/Bosses that count as mini-bosses
    MINI_WHITELIST = {
        [46] = true,  -- Sloth
        [47] = true,  -- Lust
        [48] = true,  -- Wrath
        [49] = true,  -- Gluttony
        [50] = true,  -- Greed
        [51] = true,  -- Envy
        [52] = true,  -- Pride
        [271] = true, -- Uriel
        [272] = true  -- Gabriel
    }
}

-- CacheFlag and related stat keys table
local cacheFlags = {
    [CacheFlag.CACHE_LUCK] = 'Luck',
    [CacheFlag.CACHE_DAMAGE] = 'Damage',
    [CacheFlag.CACHE_SPEED] = 'MoveSpeed',
    [CacheFlag.CACHE_SHOTSPEED] = 'ShotSpeed'
}

-- I can't be arsed to save rewardList in the mod data so if people really wanted to they could circumvent this and get more stats
-- Disables the ability for the player to get more of same entity type (boss, miniboss, enemy) related statups from the same room.
local rewardList = {
    ['boss'] = {},
    ['mini'] = {},
    ['normal'] = 0
}

-- Local in-file state that tracks the currenly gained stats
mod.modState = nil

local function getTableLength(table)
    local i = 1
    for _ in pairs(table) do i = i + 1 end
    return i
end

local function ApplyStat(type, multiplier) -- Generate and apply a random stat based on params
    local currentStat = math.random(1, 4)
    local stat
    local value

    -- Select a random stat
    if currentStat == 1 then
        stat = 'Luck'
        value = mod.CONFIG.LUCK * multiplier
    elseif currentStat == 2 then
        stat = 'Damage'
        value = mod.CONFIG.DAMAGE * multiplier
    elseif currentStat == 3 then
        stat = 'MoveSpeed'
        value = mod.CONFIG.SPEED * multiplier
    else
        stat = 'ShotSpeed'
        value = mod.CONFIG.SHOTSPEED * multiplier
    end

    -- Apply stat to players
    local numPlayers = Game():GetNumPlayers()
    local hasRockBottom = false
    
    for i=1,numPlayers do
        local player = Game():GetPlayer((i-1))
        if player:HasCollectible(mod.CHIMERISM) then
            if currentStat == 3 then -- MoveSpeed cap of 2
                local moveSpeed = player.MoveSpeed

                if moveSpeed + value >= 2 then
                    player[stat] = 2

                    if player:GetPlayerType() == PlayerType.PLAYER_JACOB or player:GetPlayerType() == PlayerType.PLAYER_ESAU then
                        player:GetOtherTwin()[stat] = 2
                    end
                else
                    player[stat] = player[stat] + value

                    if player:GetPlayerType() == PlayerType.PLAYER_JACOB or player:GetPlayerType() == PlayerType.PLAYER_ESAU then
                        player:GetOtherTwin()[stat] = player:GetOtherTwin()[stat] + value
                    end
                end
            else
                player[stat] = player[stat] + value
            end

            if player:HasCollectible(CollectibleType.COLLECTIBLE_ROCK_BOTTOM) then
                hasRockBottom = true
            end
        end
    end

    -- Update or set stat in state
    if not mod.modState[type] then
        mod.modState[type] = {}
    end

    if mod.modState[type][stat] then
        mod.modState[type][stat] = mod.modState[type][stat] + value
    else
        mod.modState[type][stat] = value
    end

    if hasRockBottom then
        if not mod.modState.totalStats then
            mod.modState.totalStats = {}
        end

        if mod.modState.totalStats[stat] then
            mod.modState.totalStats[stat] = mod.modState.totalStats[stat] + value
        else
            mod.modState.totalStats[stat] = value
        end
    end

    SFXManager():Play(type == 'roomStats' and SoundEffect.SOUND_VAMP_GULP or SoundEffect.SOUND_VAMP_DOUBLE, type == 'roomStats' and 0.5 or 1, 0, false, type == 'roomStats' and 1.1 or 0.8)

    -- If not a room stat (floor or permanent) then save it in the mod data
    if type ~= 'roomStats' then data.overwrite_specific_data('chimerism', mod.modState) end
end

function mod:Consume(entity, amount, damageFlag, source, damageCountdownFrames) -- Grants stats when kills are made
    local player = nil

    if source.Entity then
        if source.Entity.Type == EntityType.ENTITY_PLAYER then -- Source was a player?
            player = source.Entity:ToPlayer()
        elseif source.Entity.SpawnerType == EntityType.ENTITY_PLAYER and source.Entity.SpawnerEntity then -- Damage source was a shot
            player = source.Entity.SpawnerEntity:ToPlayer()
        elseif source.Entity.Player then -- Damage source was a follower
            player = source.Entity.Player
        elseif source.Entity.Parent and source.Entity.Parent.Type == EntityType.ENTITY_PLAYER then -- Damage source parent was a player
            player = source.Entity.Parent
        end
    end

    if player and player:HasCollectible(mod.CHIMERISM) and entity:IsVulnerableEnemy() and entity.HitPoints - amount <= 0 then
        if mod.CONFIG.MINI_WHITELIST[entity.Type] then -- If type is in table of mini-bosses then enemy was a mini-boss
            if not rewardList['mini'][entity.Type] and getTableLength(rewardList['mini']) < mod.CONFIG.MINI_LIMIT then    
                ApplyStat("floorStats", (1+player:GetCollectibleNum(mod.CHIMERISM)))
                rewardList['mini'][entity.Type] = true
            end
        elseif entity:GetBossID() > 0 then  -- If boss id exists then enemy was a boss
            if not rewardList['boss'][entity.Type] and getTableLength(rewardList['boss']) < mod.CONFIG.BOSS_LIMIT then
                ApplyStat("permanentStats", (1+player:GetCollectibleNum(mod.CHIMERISM)))
                rewardList['boss'][entity.Type] = true
            end
        elseif not mod.CONFIG.DEF_BLACKLIST[entity.Type] then -- Normal enemy
            if rewardList['normal'] < mod.CONFIG.ENEMY_LIMIT then
                ApplyStat("roomStats", player:GetCollectibleNum(mod.CHIMERISM))
                rewardList['normal'] = (rewardList['normal']+1)
            end
        end
    end
end

function mod:OnNewRoom() -- Reset stats by room type upon entering a room
    if mod.modState ~= nil then
        rewardList = {
            ['boss'] = {},
            ['mini'] = {},
            ['normal'] = 0
        }

        local numPlayers = Game():GetNumPlayers()

        for i=1,numPlayers do
            local player = Game():GetPlayer(tostring((i-1)))
            if player:HasCollectible(mod.CHIMERISM) and mod.modState and mod.modState['roomStats'] then
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_LUCK | CacheFlag.CACHE_SPEED)
                player:EvaluateItems()
            end
        end

        mod.modState['roomStats'] = {}
    end
end

function mod:OnNewFloor() -- Remove floor stats from state and save when switching floors and re-apply permanent stats because they aren't cached and get cleared
    local numPlayers = Game():GetNumPlayers()

    if mod.modState ~= nil then
        mod.modState['floorStats'] = {}
        for i=1,numPlayers do
            local player = Game():GetPlayer(tostring((i-1)))
            if player:HasCollectible(mod.CHIMERISM) then -- This presents the edgecase that if the item is removed the stats granted that floor will be semi-permanent but i can't be arsed to fix it
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_LUCK | CacheFlag.CACHE_SPEED)
                player:EvaluateItems()
            end
        end
    end
end

function mod:OnCache(player, flag) -- Reload/Apply room and floor based stats
    if mod.modState ~= nil then
        local currentStat = cacheFlags[flag]

        if currentStat then
            if player:HasCollectible(mod.CHIMERISM) then
                if mod.modState then
                    mod.modState['roomStats'] = {}
                    if player:HasCollectible(CollectibleType.COLLECTIBLE_ROCK_BOTTOM) then
                        if mod.modState.totalStats and mod.modState.totalStats[currentStat] then 
                            if currentStat == "MoveSpeed" and player[currentStat] + mod.modState.totalStats[currentStat] >= 2 then
                                player[currentStat] = 2
                            else
                                player[currentStat] = player[currentStat] + mod.modState.totalStats[currentStat] 
                            end
                        end
                    else
                        for key, value in pairs(mod.modState) do
                            if value[currentStat] and key ~= "totalStats" then
                                if currentStat == "MoveSpeed" and player[currentStat] + value[currentStat] >= 2 then
                                    player[currentStat] = 2
                                else
                                    player[currentStat] = player[currentStat] + value[currentStat] 
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function mod:OnLoad(isContinue) -- Setup mod state and apply stats from save
    if isContinue then
        mod.modState = data.load_specific_data('chimerism', isContinue)
        if not mod.modState then mod.modState = {} end

        local numPlayers = Game():GetNumPlayers()

        for i=1,numPlayers do
            local playerIndex = tostring((i-1))
            local player = Game():GetPlayer(playerIndex)
            if player:HasCollectible(mod.CHIMERISM) then
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED | CacheFlag.CACHE_LUCK | CacheFlag.CACHE_SPEED)
                player:EvaluateItems()
            end
        end
    else
        mod.modState = {}
        data.overwrite_specific_data('chimerism', {})
    end
end

function mod:OnLeave() mod.modState = nil end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,    mod.OnCache   )
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,   mod.Consume   )
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnLoad    )
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT,     mod.OnLeave   )
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,     mod.OnNewRoom )
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL,    mod.OnNewFloor)

return {
    ID = mod.CHIMERISM,
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_BOSS,
        ItemPoolType.POOL_ROTTEN_BEGGAR,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Chimerism", DESC = "{{ArrowUp}} Room stat up-when killing enemies#{{ArrowUp}} Floor stat-up when killing mini-bosses#{{ArrowUp}} Permanent stat-up when killing bosses" },
        { LANG = "ru",    NAME = "Химеризм",  DESC = "{{ArrowUp}} При убийстве обычного врага даёт удвоенный показатель до конца комнаты#{{ArrowUp}} При убийстве мини-боссов даёт показатель до конца этажа#{{ArrowUp}} При убийстве боссов даёт удвоенный показатель навсегда" }
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "When killing an enemy a random stat-up is granted for the current room. This stat-up dissapears when leaving the room"},
            {str = "When killing a mini-boss a random stat-up (x2) is granted for the current floor. This stat-up dissapears when going to a new floor"},
            {str = "When killing a boss a random stat up (x2) is granted permanently"},
            {str = "The amount of a stat granted is multiplied by the amount of the item held. I.E: Holding the item 3 times will grant +3 luck instead of +1"},
            {str = "The possible stats granted are the following: 1 luck, 0.5 damage, 0.05 speed, 0.05 shotspeed"},
            {str = "Killing the same mini-boss/boss or killing more than 3 mini-bosses/bosses while still in the same room does not grant another stat up"},
            {str = "Killing more than 15 enemies while still in the same room does not grant another stat up"}
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'A chimera in real life is an organism with more than one genotype'},
            {str = 'Chimerism was named after the greek mythological creature named the "Chimera". This creature was made up of multiple animals'},
        },
    }
}