--[[##########################################################################
################################# INIT SETUP #################################
##########################################################################]]--
if not TCC_API then
    TCC_API = RegisterMod("The Collection Controller", 1)
    TCC_API.CALLBACKS = {}
    TCC_API.ENABLED = {}

    function TCC_API:AddTTCCallback(Type, Func, arg1, arg2, arg3)
        if TCC_API.CALLBACKS[Type] == nil then TCC_API.CALLBACKS[Type] = {} end
        table.insert(TCC_API.CALLBACKS[Type], { ["Func"] = Func, ["arg1"] = arg1, ["arg2"] = arg2, ["arg3"] = arg3 })

        if Type == "TCC_ENTER_QUEUE" or Type == "TCC_EXIT_QUEUE" or Type == "TCC_VOID_QUEUE" then
            TCC_API.ENABLED.QUEUE = true
        elseif Type == "TCC_BEGGAR_LEAVE" or Type == "TCC_MACHINE_BREAK" or Type == "TCC_SLOT_UPDATE" then
            TCC_API.ENABLED.SLOT = true
        end

        TCC_API.ENABLED[Type] = true
    end

    function TCC_API:InitContent(data, mod)
        for _, item in ipairs(data) do
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
                        Class = mod,
                        ModName= mod,
                        ID = item.ID,
                        WikiDesc = item.ENC_DESCRIPTION and item.ENC_DESCRIPTION or Encyclopedia.EIDtoWiki(item.EID_DESCRIPTIONS[1].DESC),
                        Pools = pools
                    })    
                else
                    Encyclopedia.AddTrinket({
                        Class = mod,
                        ModName= mod,
                        ID = item.ID,
                        WikiDesc = item.ENC_DESCRIPTION and item.ENC_DESCRIPTION or Encyclopedia.EIDtoWiki(item.EID_DESCRIPTIONS[1].DESC)
                    }) 
                end
            end
        end
    end
end

--[[##########################################################################
############################ ITEM QUEUE CALLBACKS ############################
##########################################################################]]--
if not TCC_API.OnQueueEvent then
    TCC_API.QUEUE_CACHE = {}

    local function RunQueueEvent(callBack, pickupId, player)
        if TCC_API.CALLBACKS[callBack] then
            for i,d in pairs(TCC_API.CALLBACKS[callBack]) do
                if not d.arg1 or pickupId == d.arg1 then
                    d.Func(self, player, pickupId) 
                end
            end
        end
    end

    local function QueueHasGained(player) 
        if TCC_API.QUEUE_CACHE[player.InitSeed].Amount < player:GetCollectibleNum(TCC_API.QUEUE_CACHE[player.InitSeed].ID, true) then
            RunQueueEvent("TCC_EXIT_QUEUE", TCC_API.QUEUE_CACHE[player.InitSeed].ID, player) -- got added
        else
            RunQueueEvent("TCC_VOID_QUEUE", TCC_API.QUEUE_CACHE[player.InitSeed].ID, player) -- got destroyed
        end

        TCC_API.QUEUE_CACHE[player.InitSeed] = nil
    end

    function TCC_API:OnQueueEvent(player)
        if TCC_API.ENABLED.QUEUE then
            local itemqueue = player.QueuedItem
            if itemqueue and itemqueue.Item then
                if TCC_API.QUEUE_CACHE[player.InitSeed] and TCC_API.QUEUE_CACHE[player.InitSeed].ID ~= itemqueue.Item.ID then
                    QueueHasGained(player)
                end
                
                -- got picked up/queued
                if not TCC_API.QUEUE_CACHE[player.InitSeed] then RunQueueEvent("TCC_ENTER_QUEUE", itemqueue.Item.ID, player) end

                TCC_API.QUEUE_CACHE[player.InitSeed] = { ["ID"] = itemqueue.Item.ID, ["Amount"] = player:GetCollectibleNum(itemqueue.Item.ID, true) }
            elseif TCC_API.QUEUE_CACHE[player.InitSeed] then
                QueueHasGained(player)
            end
        end
    end

    TCC_API:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, TCC_API.OnQueueEvent)
end