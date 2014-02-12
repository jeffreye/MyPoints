robot_flag = "~:"
last_bid = { looter = "无人" , bid = 0 , time = 0 } -- time

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
                countdown = countdown - 1
                FinishAuction(frame)
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
    local scrollFrame = self.Container
    scrollFrame.ScrollBar.doNotHide = true
    HybridScrollFrame_CreateButtons(scrollFrame, "AuctionItemButtonTemplate", 0, 0, "TOPLEFT", "TOPLEFT", 0, -SCROLLFRAME_BUTTON_OFFSET, "TOP", "BOTTOM")
    scrollFrame.update = AuctionFrame_UpdateList
    scrollFrame.update()
end

function AuctionFrame_UpdateList()
    local scrollFrame = AuctionFrame.Container
    local offset = HybridScrollFrame_GetOffset(scrollFrame)
    local buttons = scrollFrame.buttons
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
            SetItemButtonNameFrameVertexColor(button, 0.5, 0.5, 0.5);
            SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
            SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
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
    last_bid = { looter = "无人" , bid = 0 , time =  time() } 
end

function FinishAuction( frame )
    Auctioning = false
    UnregisterEvent("CHAT_MSG_OFFICER",VerifyBid)
    frame:SetScript("onUpdate", nil)
    local item = frame:GetParent().itemLink
    local str = ""
    if last_bid.bid == 0 then
        str = "没人出分,装备又烂了╮(╯▽╰)╭  "
    else
        str = last_bid.looter .. "获得" .. last_bid.bid .. "分"
        CurrentRecord:Loot(item,last_bid.looter,las.bid)
        RemoveAuction(frame)
    end
    SendChatMessage(robot_flag .. item..str,"OFFICER")
end

function RemoveAuction( frame )
    local item = frame:GetParent().itemLink
    for i=1,#LootItemList do
        if LootItemList[i] == item then
            table.remove(LootItemList,i)
            break
        end
    end
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

    if string.match(message,"%d") then
        local bid = tonumber(message)
        if CurrentRecord:Lookup(sender) > bid then
            SendChatMessage(robot_flag.."亲,好像你的分数不够喔~","OFFICER")
        elseif bid <= 0 then
            SendChatMessage(robot_flag.."这么点分就想拿东西,太天真了~","OFFICER")
        else
            last_bid.looter = sender
            last_bid.bid = bid
            last_bid.time = time()
        end
    else 
        SendChatMessage(robot_flag.."你真的是在出分吗?别闹~","OFFICER")
    end
end