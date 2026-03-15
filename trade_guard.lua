local f = CreateFrame("Frame")

-- ===== SavedVariables =====
-- SavedVariables: TradeGuardDB
TradeGuardDB = TradeGuardDB or {}
TradeGuardDB.enabled = TradeGuardDB.enabled == nil and true or TradeGuardDB.enabled

-- Commands to toggle TradeGuard
SLASH_TRADEGUARD1 = "/tradeguard"
SlashCmdList["TRADEGUARD"] = function(msg)
    msg = msg:lower()
    if msg == "on" then
        TradeGuardDB.enabled = true
        print("|cffff4444[TradeGuard]|r TradeGuard ENABLED. Trade protection active.")
    elseif msg == "off" then
        TradeGuardDB.enabled = false
        print("|cffff4444[TradeGuard]|r TradeGuard DISABLED. Trade protection inactive.")
    else
        print("|cffff4444[TradeGuard]|r Usage: /tradeguard on | off")
        print("Current status: " .. (TradeGuardDB.enabled and "ENABLED" or "DISABLED"))
    end
end

-- Events
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("TRADE_SHOW")
f:RegisterEvent("TRADE_ACCEPT_UPDATE")
f:RegisterEvent("TRADE_TARGET_ITEM_CHANGED")
f:RegisterEvent("TRADE_PLAYER_ITEM_CHANGED")
f:RegisterEvent("TRADE_CLOSED")

-- State variables
local playerAccepted = false
local firstPopupConfirmed = false
local blockTrade = false
local tradeHit = false
local lastPlayerGold = 0
local lastTargetGold = 0
local targetItems = {}
local targetCounts = {}
local playerItems = {}
local playerCounts = {}
local pendingChanges = {}
local tradeClosedHandled = false

-- Utility: color name by class
local function ColorName(unit)
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    if not name then return "Unknown" end
    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return string.format("|cFF%02x%02x%02x%s|r", c.r*255, c.g*255, c.b*255, name)
    end
    return name
end

-- Determine unit
local function GetUnit()
    if UnitExists("NPC") then return "NPC" end
    if UnitExists("target") then return "target" end
end

-- Check if target is in party/raid
local function IsTargetInGroup()
    local targetName = UnitName("target")
    if not targetName then return false end

    for i = 1,4 do
        if UnitExists("party"..i) and UnitName("party"..i) == targetName then
            return true
        end
    end

    for i = 1,40 do
        if UnitExists("raid"..i) and UnitName("raid"..i) == targetName then
            return true
        end
    end

    return false
end

-- Reset trade state
local function ResetTradeState()
    playerAccepted = false
    firstPopupConfirmed = false
    blockTrade = false
    tradeHit = false
    tradeClosedHandled = false

    wipe(targetItems)
    wipe(targetCounts)
    wipe(playerItems)
    wipe(playerCounts)
    wipe(pendingChanges)

    StaticPopup_Hide("TRADE_GUARD_FIRST")
    StaticPopup_Hide("TRADE_GUARD_WARNING")
end

-- First popup
local function ShowFirstPopup()
    if not TradeGuardDB.enabled then return end

    local unit = GetUnit()
    if not unit then return end

    local level = UnitLevel(unit) or 0

    -- Skip popup if target is level 70
    if level == 70 then
        firstPopupConfirmed = true
        playerAccepted = true
        print("|cffff4444[TradeGuard]|r Target is level 70. Initial verification popup skipped.")
        return
    end

    local name = ColorName(unit)
    local race = UnitRace(unit) or "Unknown"
    local classLocalized = select(1, UnitClass(unit)) or "Unknown"
    local guild = GetGuildInfo(unit) or "No Guild"
    local inGroup = IsTargetInGroup() and "Yes" or "No"

    local levelWarning = ""
    if level < 70 then
        levelWarning =
        "\n\n|cffff0000WARNING: Character under level 70.\nMay not be able to apply some enchants/recipes.|r"
    end

    local text =
    "Trade initiated with:\n\n" ..
    name .. "\n" ..
    "Level: "..level.." "..race.."\n" ..
    "Class: "..classLocalized.."\n" ..
    "Guild: <"..guild..">\n" ..
    "In Group/Raid: "..inGroup ..
    levelWarning ..
    "\n\n|cffffcc00Verify the player before trading.|r\n\nContinue?"

    StaticPopupDialogs["TRADE_GUARD_FIRST"] = {
        text = text,
        button1 = "Confirm",
        button2 = "Cancel Trade",

        OnAccept = function()
            firstPopupConfirmed = true
            playerAccepted = true
            print("|cffff4444[TradeGuard]|r First popup confirmed. You may now trade.")
        end,

        OnCancel = function()
            CancelTrade()
            print("|cffff4444[TradeGuard]|r Trade canceled by player.")
        end,

        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }

    StaticPopup_Show("TRADE_GUARD_FIRST")
end

-- Warning popup
local function ShowWarningPopupStatic()
    if not TradeGuardDB.enabled or #pendingChanges == 0 then return end

    local text = table.concat(pendingChanges,"\n")
    text = text:gsub("(%[TradeGuard%] Your.-)\n?", "|cffff4444%1|r\n")
    text = text:gsub("(%[TradeGuard%] Target.-)\n?", "|cffff8800%1|r\n")
    text = text:gsub("(%[TradeGuard%].-gold.-)\n?", "|cffffff00%1|r\n")

    StaticPopupDialogs["TRADE_GUARD_WARNING"] = {
        text = text,
        button1 = "Confirm",
        button2 = "Cancel Trade",

        OnAccept = function()
            blockTrade = false
            tradeHit = false
            wipe(pendingChanges)
            print("|cffff4444[TradeGuard]|r Warning confirmed. You may now trade.")
        end,

        OnCancel = function()
            CancelTrade()
            print("|cffff4444[TradeGuard]|r Trade canceled by player.")
        end,

        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3
    }

    StaticPopup_Show("TRADE_GUARD_WARNING")
    blockTrade = true
end

-- Scan target items
local function ScanTargetItems()
    for i=1,6 do
        local link = GetTradeTargetItemLink(i)
        local _,_,count = GetTradeTargetItemInfo(i)
        count = count or 1

        if link ~= targetItems[i] or count ~= targetCounts[i] then
            local oldCount = targetCounts[i] or 0
            local msg

            if targetItems[i] and link and targetItems[i] ~= link then
                msg = string.format("[TradeGuard] Target replaced item in slot %d: %s -> %s x%d",i,targetItems[i],link,count)
            elseif link and not targetItems[i] then
                msg = string.format("[TradeGuard] Target added item in slot %d: %s x%d",i,link,count)
            elseif not link and targetItems[i] then
                msg = string.format("[TradeGuard] Target removed item in slot %d: %s",i,targetItems[i])
            elseif link and count ~= oldCount then
                msg = string.format("[TradeGuard] Target stack size of %s changed: %d -> %d",link,oldCount,count)
            end

            if msg then
                print(msg)
                if tradeHit then
                    table.insert(pendingChanges,msg)
                end
            end
        end

        targetItems[i] = link
        targetCounts[i] = count
    end
end

-- Scan player items
local function ScanPlayerItems()
    for i=1,6 do
        local link = GetTradePlayerItemLink(i)
        local _,_,count = GetTradePlayerItemInfo(i)
        count = count or 1

        if link ~= playerItems[i] or count ~= playerCounts[i] then
            local oldCount = playerCounts[i] or 0
            local msg

            if playerItems[i] and link and playerItems[i] ~= link then
                msg = string.format("[TradeGuard] Your item in slot %d changed: %s -> %s x%d",i,playerItems[i],link,count)
            elseif link and not playerItems[i] then
                msg = string.format("[TradeGuard] You added item in slot %d: %s x%d",i,link,count)
            elseif not link and playerItems[i] then
                msg = string.format("[TradeGuard] You removed item in slot %d: %s",i,playerItems[i])
            elseif link and count ~= oldCount then
                msg = string.format("[TradeGuard] Your stack size of %s changed: %d -> %d",link,oldCount,count)
            end

            if msg then
                print(msg)
                if tradeHit then
                    table.insert(pendingChanges,msg)
                end
            end
        end

        playerItems[i] = link
        playerCounts[i] = count
    end
end

-- Event handler
f:SetScript("OnEvent", function(self,event,...)
    if event == "PLAYER_LOGIN" then
        print("|cffff4444[TradeGuard]|r Loaded. Protection: "..(TradeGuardDB.enabled and "ENABLED" or "DISABLED"))
        return
    end

    if not TradeGuardDB.enabled then return end

    if event == "TRADE_SHOW" then
        ResetTradeState()
        lastPlayerGold = GetPlayerTradeMoney()
        lastTargetGold = GetTargetTradeMoney()
        ShowFirstPopup()
        print("|cffff4444[TradeGuard]|r Trade started.")
    end

    if event == "TRADE_ACCEPT_UPDATE" then
        local playerState = ...
        if playerState == 1 then
            tradeHit = true
            if not firstPopupConfirmed then
                CancelTrade()
                print("|cffff4444[TradeGuard]|r Trade blocked! Confirm first popup first.")
                return
            end
            if blockTrade then
                CancelTrade()
                print("|cffff4444[TradeGuard]|r Trade blocked! Confirm warning popup.")
                ShowWarningPopupStatic()
                return
            end
        end
    end

    if event == "TRADE_TARGET_ITEM_CHANGED" then ScanTargetItems() end
    if event == "TRADE_PLAYER_ITEM_CHANGED" then ScanPlayerItems() end

    local playerGold = GetPlayerTradeMoney()
    local targetGold = GetTargetTradeMoney()

    if playerGold ~= lastPlayerGold then
        local msg = string.format("[TradeGuard] Your gold changed: %d -> %d",lastPlayerGold,playerGold)
        print(msg)
        if tradeHit then table.insert(pendingChanges,msg) end
        lastPlayerGold = playerGold
    end

    if targetGold ~= lastTargetGold then
        local msg = string.format("[TradeGuard] Target gold changed: %d -> %d",lastTargetGold,targetGold)
        print(msg)
        if tradeHit then table.insert(pendingChanges,msg) end
        lastTargetGold = targetGold
    end

    if tradeHit and firstPopupConfirmed and #pendingChanges > 0 and not blockTrade then
        ShowWarningPopupStatic()
    end

    if event == "TRADE_CLOSED" and not tradeClosedHandled then
        tradeClosedHandled = true
        ResetTradeState()
        print("|cffff4444[TradeGuard]|r Trade closed. All states reset.")
    end
end)
