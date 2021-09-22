local mod = RegisterMod("ROTCOL_DATA_MANAGER", 1)
local json = require("json")

local fetchedData = nil

local loadStatus, LoadValue = pcall(json.decode, mod:LoadData())   
if loadStatus then
    fetchedData = LoadValue 
else
    fetchedData = {}
end

local function load(_, isContinued)
    -- Reset save if new run
    if isContinued then
        local loadStatus, LoadValue = pcall(json.decode, mod:LoadData())
        
        if loadStatus then
            fetchedData = LoadValue 
        else
            fetchedData = {}
        end
    else
        mod:SaveData(json.encode({}))
    end
end

local function overwrite_specific_data(key, content)
    if fetchedData == nil then fetchedData = {} end
    fetchedData[key] = content
    mod:SaveData(json.encode(fetchedData))
end

local function load_specific_data(key, isContinue)
    if not fetchedData and isContinue then load(nil, true) end
    return (fetchedData and fetchedData[key]) and fetchedData[key] or nil
end

local function save_all_data()
    mod:SaveData(json.encode(fetchedData))
end

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, save_all_data)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, load);

return {
    overwrite_specific_data = overwrite_specific_data,
    load_specific_data = load_specific_data,
    save_all_data = save_all_data,
}