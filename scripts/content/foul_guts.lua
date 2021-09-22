local mod = RegisterMod("Foul Guts", 1)
local data = require("scripts.datamanager")
local json = require("json")
mod.FOUL_GUTS = Isaac.GetItemIdByName("Foul Guts")
mod.COSTUME = Isaac.GetCostumeIdByPath("gfx/characters/rotcol_foul_guts.anm2")

local spawnableHearts = {
    [1] = HeartSubType.HEART_SOUL,
    [2] = HeartSubType.HEART_BLACK,
    [3] = HeartSubType.HEART_HALF_SOUL,
    [4] = HeartSubType.HEART_BLENDED,
    [5] = HeartSubType.HEART_BONE,
    [6] = HeartSubType.HEART_ROTTEN
}

function mod:OnCollect(player) -- Apply stats on pickup if they haven't been granted
    player:AddMaxHearts(2)
    player:AddBoneHearts(2)
    local max = player:GetEffectiveMaxHearts()

    if max > 0 then
        player:AddRottenHearts(max)
    else
        local room = Game():GetRoom()
        for i = 1, math.random(4,8) do
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, spawnableHearts[math.random(1, 6)], room:FindFreePickupSpawnPosition(player.Position, 0, true), Vector(0,0), player)
        end
    end
end

TCC_API:AddTTCCallback("TCC_EXIT_QUEUE", mod.OnCollect, mod.FOUL_GUTS)

return { 
    ID = mod.FOUL_GUTS,
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_BOSS,
        ItemPoolType.POOL_ROTTEN_BEGGAR,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Foul Guts",     DESC = "{{EmptyHeart}} +1 Heart container#{{EmptyBoneHeart}} +2 Bone hearts#{{RottenHeart}} Fills all containers with rotten hearts#{{BlendedHeart}} Drops random hearts when no red hearts can be held" },
        { LANG = "ru",    NAME = "Грязные кишки", DESC = "{{EmptyHeart}} +1 красное сердце#{{EmptyBoneHeart}} +2 костяных сердца#{{RottenHeart}} Заменяет все контейнеры гнилыми сердцами#{{BlendedHeart}} Выбрасывает рандомные сердца если персонаж не может иметь красные сердца" },
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "+1 Heart container"},
            {str = "+2 Bone Hearts"},
            {str = "Replace all red hearts and fills all empty containers with rotten hearts"},
            {str = "When the player can't hold any red/rotten hearts then between 4 and 8 of the following hearts will be dropped: Soul, Half soul, Black, Blended, Bone and Rotten"}
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = 'The texture of this item was based on the "Guts" enemy variant named "Cyst"'}
        },
    }
}