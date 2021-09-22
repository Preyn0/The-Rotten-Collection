local mod = RegisterMod("The Rotten Collection", 1)
local json = require("json")

-- Define content and path
local path = 'scripts.content.'
local content = {'cube_of_rot', 'foul_guts', 'chimerism', 'necrosis', 'knout', 'mothers_spine', 'rotten_gut', 'sick_maggot'}

require('scripts.rotcol_callbacks') -- Import custom/shared callbacks
require('scripts.datamanager') -- Import data manager

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
                Class = "Rotten Collection",
                ModName= "Rotten Collection",
                ID = item.ID,
                WikiDesc = item.ENC_DESCRIPTION and item.ENC_DESCRIPTION or Encyclopedia.EIDtoWiki(item.EID_DESCRIPTIONS[1].DESC),
                Pools = pools
            })    
        else
            Encyclopedia.AddTrinket({
                Class = "Rotten Collection",
                ModName= "Rotten Collection",
                ID = item.ID,
                WikiDesc = item.ENC_DESCRIPTION and item.ENC_DESCRIPTION or Encyclopedia.EIDtoWiki(item.EID_DESCRIPTIONS[1].DESC)
            }) 
        end
    end
end

--[[ ### DEV CODE ### --
local function loadItems()
    if Game():GetFrameCount() == 0 then
        local offset = 0
        for _, item in ipairs(contentImports) do
            -- I can't get this to work. Might wait for some API docs for this mod to release and then try it again
            -- if WardrobePlus ~= nil and item.OWRP_ID and item.KEY then
            --     OWRP.AddNewCostume(
            --         item.OWRP_ID, 
            --         item.OWRP_NAME or item.KEY:sub(1,1):upper()..item.KEY:sub(2), 
            --         "gfx/characters/rotcol_"..item.KEY..".anm2", 
            --         item.OWRP_FLY or false,
            --         item.OWRP_LOCK or false
            --     )
            -- end

            if item.SHOW_DEV or true then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, item.TYPE, item.ID, Vector(320+offset, 300), Vector(0, 0), nil)

                if item.TYPE == 350 then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, item.TYPE, item.ID+32768, Vector(320+offset, 300), Vector(0, 0), nil)
                end

                if offset == 0 then
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

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, loadItems);
-- ### END DEV CODE ### ]]--