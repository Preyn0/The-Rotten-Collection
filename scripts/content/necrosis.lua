local mod = RegisterMod("Necrosis", 1)
local data = require("scripts.datamanager")
local game = Game()
local json = require("json")

mod.VARIANT = Isaac.GetEntityVariantByName("Rot Collection Necrosis")
mod.NECROSIS = Isaac.GetItemIdByName("Necrosis")
mod.COSTUME = Isaac.GetCostumeIdByPath("gfx/characters/rotcol_necrosis.anm2")

local types = {
    [EntityType.ENTITY_TEAR] = "tear",
    [EntityType.ENTITY_LASER] = "laser",
    [EntityType.ENTITY_KNIFE] = "knife"
}

local function GetPlayer(entity)
    if entity and entity.SpawnerType == EntityType.ENTITY_PLAYER and entity.SpawnerEntity then 
        return entity.SpawnerEntity:ToPlayer()
    else
        return nil
    end
end

function mod:OnShot(shot)
    local player = GetPlayer(shot)

    -- Roll between luck stat and 30. If luck stat is above 20 rol between 20 and 30
    if player and player:HasCollectible(mod.NECROSIS) and math.random(player.Luck >= 20 and 20 or math.ceil(player.Luck), 25) > 24 then
        local type = types[shot.Type]

        if type then
            -- shot:SetColor(Color(0.278, 0.286, 0.243, 1, 0, 0, 0), 0, 1, false, false)
            shot.CollisionDamage = shot.CollisionDamage*1.75
            shot:GetData()["rotcol_necrosis"] = true

            if type == 'tear' then
                shot = shot:ToTear()
                shot:ChangeVariant(mod.VARIANT)
            end

            shot:Update()
        end
    end
end

function mod:OnUpdate(entity)
    if entity.SpawnerType == EntityType.ENTITY_PLAYER then
        entity = entity:ToTear()
        local data = entity:GetData()

        if entity:CollidesWithGrid() or entity.Height >= -5 then
            local small = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TEAR_POOF_A, 0, entity.Position, Vector(0, 0), nil):ToEffect()
            small:SetColor(Color(0.114, 0.118, 0.098, 1, 0, 0, 0), 0, 1, false, false)
            for i = 1, 3 do
                local large = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BLOOD_PARTICLE, 0, entity.Position, RandomVector() * ((math.random() * 2) + 1), nil):ToEffect()
                large:SetColor(Color(0.278, 0.286, 0.243, 1, 0, 0, 0), 0, 1, false, false)
            end

            entity:Remove()
        end
    end
end

function mod:OnHit(entity, _, _, source, _) -- On hit for special necrosis tears
    local player = GetPlayer(source.Entity)

    if player 
    and player:HasCollectible(mod.NECROSIS) 
    and entity:IsVulnerableEnemy() then
        local type = types[source.Type]

        if type then
            if type == "tear" and source.Entity and source.Entity:GetData()["rotcol_necrosis"] then
                if player:HasCollectible(CollectibleType.COLLECTIBLE_CONTAGION) then
                    entity:AddEntityFlags(EntityFlag.FLAG_CONTAGIOUS)
                    -- Conditional fart because killing an enemy with the contagion flag already creates one
                    if not entity:IsBoss() then entity:Kill() else -- Insta kill like euthanasia
                        game:Fart(entity.Position, 50, player, 1, 1, source.Color)
                    end
                else
                    game:Fart(entity.Position, 50, player, 1, 0, source.Color)
                    if not entity:IsBoss() then entity:Kill() end -- Insta kill like euthanasia
                end
            elseif type == "laser" or type == "knife" then
                if player:HasCollectible(CollectibleType.COLLECTIBLE_CONTAGION) then
                    entity:AddEntityFlags(EntityFlag.FLAG_CONTAGIOUS)
                end

                if entity:IsBoss() then
                    if Game():GetFrameCount() % 4 == 0 then
                        game:Fart(source.Position, 50, player, 1, 0, source.Color)
                    end
                elseif not entity:HasEntityFlags(EntityFlag.FLAG_POISON) then
                    game:Fart(source.Position, 50, player, 1, 0, source.Color)
                end
            end
        end
    end
end

function mod:OnCollect(player) -- Apply stats on pickup if they haven't been granted
    player:AddMaxHearts(4)
    player:AddBrokenHearts(1)
    player:AddRottenHearts(4)
end

mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE,   mod.OnUpdate, mod.VARIANT)
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR,     mod.OnShot               )
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,    mod.OnHit                )

TCC_API:AddTTCCallback("TCC_EXIT_QUEUE", mod.OnCollect, mod.NECROSIS)

return {
	ID = mod.NECROSIS,
    TYPE = 100,
    POOLS = {
        ItemPoolType.POOL_TREASURE,
        ItemPoolType.POOL_ROTTEN_BEGGAR,
        ItemPoolType.POOL_GREED_TREASUREL,
        ItemPoolType.POOL_GREED_SHOP,
    },
    EID_DESCRIPTIONS = {
        { LANG = "en_us", NAME = "Necrosis", DESC = "{{EmptyHeart}} +2 Heart Containers#{{RottenHeart}} +2 Rotten hearts#{{ArrowDown}} +1 Broken heart#Chance to fire clumps#Clumps leave farts on impact#Clumps kill normal enemies instantly" },
        { LANG = "ru",    NAME = "Некроз",   DESC = "{{EmptyHeart}} +2 красных сердец#{{RottenHeart}} +2 гнилых сердец#{{ArrowDown}} +1 костяное сердце#Шанс выстрелить сгустками#Сгустки оставляют пуки при попадании#Сгустки мгновенно убивают обычных врагов" },
    },
    ENC_DESCRIPTION = {
        { -- Effect
            {str = "Effect", fsize = 2, clr = 3, halign = 0},
            {str = "Isaac has a. chance to shoot a clump instead of a tear"},
            {str = "These clumps will instantly kill normal enemies and leave a fart on impact"},
            {str = "+2 Heart containers filled with rotten hearts"},
            {str = "+1 Broken heart"},
        },
        { -- Synergies
            {str = "Synergies", fsize = 2, clr = 3, halign = 0},
            {str = "While holding mom's knife fired knifes can leave a fart on impact."},
            {str = 'While holding contagion the item will apply the contagion effect to enemies.'}
        },
        { -- Trivia
            {str = "Trivia", fsize = 2, clr = 3, halign = 0},
            {str = [[The texture of this item was based on the "Child's Heart" trinket]]},
            {str = "Necrosis in real life is the premature death of living tissue"},
            {str = "Necrosis is named after the ancient greek word for death"},
            {str = 'Credit to the "Strawpack 2 mod" which was used as an example for some of the code used for this item'},
            {str = 'Strawpack 2 mod: steamcommunity.com/sharedfiles/ filedetails/?id=1163138153'}
        },
    }
}