--[[##########################################################################
############################### INIT CALLBACKS ###############################
##########################################################################]]--
if not TCC_API then
    TCC_API = RegisterMod("The Collection Controller", 1)
    TCC_API.CALLBACKS = {}
    TCC_API.ENABLED = {}

    function TCC_API:AddTTCCallback(Type, Func, Data)
        if TCC_API.CALLBACKS[Type] == nil then TCC_API.CALLBACKS[Type] = {} end
        table.insert(TCC_API.CALLBACKS[Type], { ["Func"] = Func, ["Data"] = Data })

        if Type == "TCC_ENTER_QUEUE" or Type == "TCC_EXIT_QUEUE" or Type == "TCC_VOID_QUEUE" then
            TCC_API.ENABLED.QUEUE = true
        elseif Type == "TCC_BEGGAR_LEAVE" or Type == "TCC_MACHINE_BREAK" or Type == "TCC_SLOT_UPDATE" then
            TCC_API.ENABLED.SLOT = true
        end

        TCC_API.ENABLED[Type] = true
    end
end

--[[##########################################################################
############################ ITEM QUEUE CALLBACKS ############################
##########################################################################]]--
if not TCC_API.OnQueueEvent then
    TCC_API.QUEUE_CACHE = {}

    local function RunQueueEvent(callBack, pickupId, player)
        if TCC_API.CALLBACKS[callBack] then
            for i=1, #TCC_API.CALLBACKS[callBack] do
                if not TCC_API.CALLBACKS[callBack][i].Data or pickupId == TCC_API.CALLBACKS[callBack][i].Data then
                    TCC_API.CALLBACKS[callBack][i].Func(self, player, pickupId) 
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