robot_flag = "~:"
last_bid = { looter = "无人" , bid = 0 , time = 0 ,item = "" } -- time

Auctioning = false
countdown = -1


function AuctionFrame_OnLoad( self )
    tinsert(UISpecialFrames, self:GetName());
    --register for moving frame
    self:RegisterForDrag("LeftButton")


    local total =  0
    local function AuctioningTimerCallback(frame , elapsed)
        if not Auctioning then 
            return
        end
        total = total + elapsed
        if total < 1 then
            return
        end
        total = 0

        local delta = time() - last_bid.time
        if delta >= DKP_Options["item_auction_countdown_after_slience"] then
            if countdown == 0 then
                SendChatMessage(robot_flag .. "禁止出分","OFFICER")
                FinishAuction()
                --reset all
                countdown = -1
                return
            elseif countdown ~= -1 then
                SendChatMessage(robot_flag ..tostring(countdown),"OFFICER")
                countdown = countdown - 1
                return
            else
                SendChatMessage(robot_flag .. "无人出分,开始倒数","OFFICER")
                countdown = 5
            end
        else 
            countdown = -1
        end
    end
    CreateTimer(AuctioningTimerCallback)
end

function AuctionFrame_OnShow( self )    
    -- update list
    local scrollFrame = AuctionFrame.Container
    scrollFrame.ScrollBar.doNotHide = true
    HybridScrollFrame_CreateButtons(scrollFrame, "AuctionItemButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, 0, "TOP", "BOTTOM")
    scrollFrame.update = AuctionFrame_UpdateList
    scrollFrame.update()
end

function AuctionFrame_UpdateList()
    local scrollFrame = AuctionFrame.Container
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local buttons = scrollFrame.buttons
    local LootItemList = GetLootItems()
    local count = #LootItemList
    for i=1,#buttons do
        local btn = buttons[i]
        if i + offset > count then
            btn:Hide()
        else
            local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, _ = GetItemInfo(LootItemList[i+offset])

            btn.itemLink = link
            local color = ITEM_QUALITY_COLORS[quality]
            local text = _G[btn:GetName() .. "Text"]
            text:SetText(name)
            text:SetVertexColor(color.r, color.g, color.b);
            btn.icon:SetTexture(texture);
            SetItemButtonNameFrameVertexColor(btn, 0.5, 0.5, 0.5);
            SetItemButtonTextureVertexColor(btn, 1.0, 1.0, 1.0);
            SetItemButtonNormalTextureVertexColor(btn, 1.0, 1.0, 1.0);
            btn:Show()
        end
    end

    local totalHeight = count * (36 + 2)
    local displayedHeight = #buttons * (36 + 2)
    HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
end

function StartAuction(frame)
    Auctioning = true
    SendChatMessage(robot_flag .. frame:GetParent().itemLink.."30,开始出分","OFFICER")
    RegisterEvent("CHAT_MSG_OFFICER",VerifyBid)
    -- register time callbacks
    -- create a timer
    last_bid = { looter = "无人" , bid = 0 , time =  time() , item = frame:GetParent().itemLink } 
end

function FinishAuction( frame )
    Auctioning = false
    UnregisterEvent("CHAT_MSG_OFFICER",VerifyBid)
    local item = last_bid.item
    local str = ""
    if last_bid.bid == 0 then
        str = "没人出分,装备又烂了╮(╯▽╰)╭  "
    else
        str = last_bid.looter .. "获得" .. tostring(last_bid.bid) .. "分"
        CurrentRecord:Loot(item,last_bid.looter,last_bid.bid)
        RemoveAuction(item)
    end
    SendChatMessage(robot_flag .. item..str,"OFFICER")
end

function RemoveAuction( item )
    RemovePendingItem(item)
    AuctionFrame.Container.update()
end


function OpenItemInfoTooltip( btn )
    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(btn.itemLink)
    CursorUpdate(btn)
end

function CloseItemInfoTooltip( btn )
    GameTooltip:Hide()
    ResetCursor()
end

function AuctionItem_Click( btn )
     if ( IsModifiedClick() ) then
        HandleModifiedItemClick(btn.itemLink)
    end
end


function VerifyBid(frame , event , message , sender )
    if not Auctioning or StartsWith(message,robot_flag) then
        return
    end

    local bid = 0
    message = string.upper(message)
    if string.match(message,"%d") then
        bid = tonumber(message)
    elseif message == "SH" then
        SendChatMessage(robot_flag .. sender .."出" .. tostring(CurrentRecord:Lookup(sender)) .. "分","OFFICER")
        bid = CurrentRecord:Lookup(sender)
    elseif message == "P" or message == "PASS" then
        return
    else 
        SendChatMessage(robot_flag.."你真的是在出分吗?别闹~","OFFICER")
        return
    end

    if bid < 30 or bid < last_bid.bid then
        SendChatMessage(robot_flag.."这么点分就想拿东西,太天真了~","OFFICER")
    elseif CurrentRecord:Lookup(sender) < bid then
        SendChatMessage(robot_flag.."亲,好像你的分数没那么多喔~","OFFICER")
    else
        last_bid.looter = sender
        last_bid.bid = bid
        last_bid.time = time()
        countdown = -1
    end
end



function RemovePendingItem( item )
    for i=1,#PendingItems do
        if PendingItems[i] == item then
            table.remove(PendingItems,i)
            break
        end
    end
end

function GetLootItems()
    return PendingItems
end



function AddLootItem( item)
    table.insert(PendingItems,item)
    return PendingItems
end