-- default config
pfBrowser_fav = {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

local tooltip_limit = 5

-- add database shortcuts
local items = pfDB["items"]["data"]
local units = pfDB["units"]["data"]
local objects = pfDB["objects"]["data"]
local quests = pfDB["quests"]["data"]
local zones = pfDB["zones"]["loc"]

-- result buttons
local function StartAndFinish(questData, startOrFinish, types)
  local strings = {["start"]="开始自 ", ["end"]="完成自 "}
  for _, key in ipairs(types) do
    if questData[startOrFinish] and questData[startOrFinish][key] then
      local typeName = {["U"]="units",["O"]="objects",["I"]="items"}
      GameTooltip:AddLine("\n|cffffff00"..strings[startOrFinish]..typeName[key]..":|r")
      for _,id in ipairs(questData[startOrFinish][key]) do
        local name = pfDB[typeName[key]]["loc"][id] or id
        GameTooltip:AddDoubleLine(" ", name, 0,0,0, 1,1,1)
      end
    end
  end
end

local function ResultButtonEnter()
  -- item
  if this.btype == "items" then
    this.tex:SetTexture(1,1,1,.1)
    GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetHyperlink("item:" .. this.id .. ":0:0:0")
    GameTooltip:AddLine("\nID: "..this.id, 0.8,0.8,0.8)
    GameTooltip:Show()

  -- quest
  elseif this.btype == "quests" then
    this.tex:SetTexture(1,1,1,.1)
    GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetText(this.name, .3, 1, .8)
    local questTexts = pfDB[this.btype]["loc"][this.id]
    local questData = pfDB[this.btype]["data"][this.id]
    GameTooltip:AddLine(" ")

    -- add levels
    if questData.lvl then
      GameTooltip:AddDoubleLine("|cffffff00任务等级: |r", questData.lvl, 1,1,1, 1,1,1)
    end
    if questData.min then
      GameTooltip:AddDoubleLine("|cffffff00需求等级: |r", questData.min, 1,1,1, 1,1,1)
    end

    -- quest starter
    if questData["start"] or questData["end"] then
      StartAndFinish(questData, "start", {"U","O","I"})
      StartAndFinish(questData, "end", {"U","O"})
    end

    -- obectives
    if questTexts["O"] and questTexts["O"] ~= "" then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(pfDatabase:FormatQuestText(questTexts["O"]),1,1,1,true)
    end

    -- details
    if questTexts["D"] and questTexts["D"] ~= "" then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(pfDatabase:FormatQuestText(questTexts["D"]),.6,.6,.6,true)
    end

    GameTooltip:AddLine("\nID: "..this.id, 0.8,0.8,0.8)
    GameTooltip:Show()

  -- units / objects
  else
    this.tex:SetTexture(1,1,1,.1)
    local id = this.id
    local name = this.name
    local maps = {}
    GameTooltip:SetOwner(this.text, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetText(name, .3, 1, .8)
    if this.btype == "units" then
      local unitData = units[id]
      if unitData.lvl then
        GameTooltip:AddDoubleLine("|cffffff00等级:|r", unitData.lvl, 0,0,0, 1,1,1)
      end
      local reactionStringA = "|c00ff0000敌对|r"
      local reactionStringH = "|c00ff0000敌对|r"
      if unitData.fac then
        if unitData.fac == "AH" then
          reactionStringA = "|c0000ff00友方|r"
          reactionStringH = "|c0000ff00友方|r"
        elseif unitData.fac == "A" then
          reactionStringA = "|c0000ff00友方|r"
        elseif unitData.fac == "H" then
          reactionStringH = "|c0000ff00友方|r"
        end
      end
      GameTooltip:AddLine("|cffffff00反应:|r", 1,1,1)
      GameTooltip:AddDoubleLine("联盟", reactionStringA, 1,1,1, 0,0,0)
      GameTooltip:AddDoubleLine("部落", reactionStringH, 1,1,1, 0,0,0)
    end
    GameTooltip:AddLine("\n|cffffff00位于:|r", 1,1,1)
    if pfDB[this.btype]["data"][id] and pfDB[this.btype]["data"][id]["coords"] then
      for _, data in pairs(pfDB[this.btype]["data"][id]["coords"]) do
        local zone = data[3]
        maps[zone] = maps[zone] and maps[zone] + 1 or 1
      end
    else
      GameTooltip:AddLine(UNKNOWN, 1,.5,.5)
    end
    for zone, count in pairs(maps) do
      GameTooltip:AddDoubleLine(( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), count .. "x", 1,1,1, .5,.5,.5)
    end
    GameTooltip:AddLine("\nID: "..this.id, 0.8,0.8,0.8)
    GameTooltip:Show()
  end
end

local function ResultButtonUpdate()
  GameTooltip:SetHyperlink("item:" .. this.id .. ":0:0:0")
  GameTooltip:Hide()

  local _, _, itemQuality = GetItemInfo(this.id)
  if itemQuality then
    this.itemColor = "|c" .. string.format("%02x%02x%02x%02x", 255, ITEM_QUALITY_COLORS[itemQuality].r * 255, ITEM_QUALITY_COLORS[itemQuality].g * 255, ITEM_QUALITY_COLORS[itemQuality].b * 255)
  end

  if this.itemColor then
    this.text:SetText(this.itemColor .."|Hitem:"..this.id..":0:0:0|h[".. this.name.."]|h|r")
    this.text:SetWidth(this.text:GetStringWidth())
    this:SetScript("OnUpdate", nil)
  end
end

local function ResultButtonClick()
  if this.btype == "items" then
    local link = "item:"..this.id..":0:0:0"
    local text = ( this.itemColor or "|cffffffff" ) .."|H" .. link .. "|h["..this.name.."]|h|r"
    SetItemRef(link, text, arg1)
  elseif this.btype == "quests" then
    if IsShiftKeyDown() then
      ChatFrameEditBox:Show()
      ChatFrameEditBox:Insert("|cffffff00|Hquest:0:0:0:0|h[" .. this.name .. "]|h|r")
    else
      local meta = { ["addon"] = "PFDB" }
      local maps = pfDatabase:SearchQuestID(this.id, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    end
  elseif this.btype == "units" then
    local maps = pfDatabase:SearchMobID(this.id)
    pfMap:UpdateNodes()
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  elseif this.btype == "objects" then
    local maps = pfDatabase:SearchObjectID(this.id)
    pfMap:UpdateNodes()
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
  end
end

local function ResultButtonClickFav()
  local parent = this:GetParent()
  if pfBrowser_fav[parent.btype][parent.id] then
    pfBrowser_fav[parent.btype][parent.id] = nil
    this.icon:SetVertexColor(1,1,1,.1)
  else
    pfBrowser_fav[parent.btype][parent.id] = parent.name
    this.icon:SetVertexColor(1,1,1,1)
  end
end

local function ResultButtonLeave()
  if math.mod(this:GetID(),2) == 1 then
    this.tex:SetTexture(1,1,1,.02)
  else
    this.tex:SetTexture(1,1,1,.04)
  end
  GameTooltip:Hide()
end

local function ResultButtonClickSpecial()
  local param = this:GetParent()[this.parameter]
  local maps = {}
  if this.buttonType == "O" or this.buttonType == "U" then
    maps = pfDatabase:SearchItemID(param, nil, nil, {[this.buttonType]=true})
  elseif this.buttonType == "V" then
    maps = pfDatabase:SearchVendor(param)
  end
  pfMap:UpdateNodes()
  pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
end

local function ResultButtonEnterSpecial()
  local id = this:GetParent().id
  local count = 0
  local skip = false

  GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")

  -- unit
  if this.buttonType == "U" then
    if items[id]["U"] then
      GameTooltip:SetText("拾取自", .3, 1, .8)
      for unitID, chance in pairs(items[id]["U"]) do
        count = count + 1
        if count > tooltip_limit then
          skip = true
        end
        if units[unitID] and not skip then
          local name = pfDB.units.loc[unitID]
          local zone = nil
          if units[unitID].coords then
            zone = units[unitID].coords[1][3]
          end
          GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
        end
      end
    end

  -- object
  elseif this.buttonType == "O" then
    if items[id]["O"] then
      GameTooltip:SetText("拾取自", .3, 1, .8)
      for objectID, chance in pairs(items[id]["O"]) do
        count = count + 1
        if count > tooltip_limit then
          skip = true
        end
        if objects[objectID] and not skip then
          local name = pfDB.objects.loc[objectID] or objectID
          local zone = nil
          if objects[objectID].coords then
            zone = objects[objectID].coords[1][3]
          end
          GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
        elseif not skip then
          GameTooltip:AddLine((pfDB.objects.loc[objectID] or "ID: "..objectID).." (数据缺失)")
        end
      end
    end

  -- vendor
  elseif this.buttonType == "V" then
    if items[id]["V"] then
      GameTooltip:SetText("出售自", .3, 1, .8)
      for unitID, sellcount in pairs(items[id]["V"]) do
        count = count + 1
        if count > tooltip_limit then
          skip = true
        end
        if units[unitID] and not skip then
          local name = pfDB.units.loc[unitID]
          if sellcount ~= 0 then name = name .. " (" .. sellcount .. ")" end
          local zone = units[unitID].coords[1] and units[unitID].coords[1][3]
          GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
        end
      end
    end
  end

  if count > tooltip_limit then
    GameTooltip:AddLine("\n和 "..(count - tooltip_limit).." 其他.",.8,.8,.8)
  end
  GameTooltip:Show()
end

local function ResultButtonLeaveSpecial()
  GameTooltip:Hide()
end

local function ResultButtonReload(self)
  self.idText:SetText("ID: " .. self.id)

  if pfQuest_config.showids == "1" then
    self.idText:Show()
  else
    self.idText:Hide()
  end

  self.itemColor = nil

  -- update faction
  if self.btype ~= "items" then
    self.factionA:Hide()
    self.factionH:Hide()

    local raceMask = pfDatabase:GetRaceMaskByID(self.id, self.btype)
    if (bit.band(77, raceMask) > 0)  or (raceMask == 0 and self.btype == "quests") then
      self.factionA:Show()
    end
    if (bit.band(178, raceMask) > 0)  or (raceMask == 0 and self.btype == "quests") then
      self.factionH:Show()
    end
  end

  -- activate fav buttons if needed
  if pfBrowser_fav and pfBrowser_fav[self.btype] and pfBrowser_fav[self.btype][self.id] then
    self.fav.icon:SetVertexColor(1,1,1,1)
  else
    self.fav.icon:SetVertexColor(1,1,1,.1)
  end

  -- actions by search type
  if self.btype == "quests" then
    self.name = pfDB[self.btype]["loc"][self.id]["T"]
    self.text:SetText("|cffffcc00|Hquest:0:0:0:0|h[" .. self.name .. "]|h|r")
  elseif self.btype == "units" or self.btype == "objects" then
    local level = pfDB[self.btype]["data"][self.id]["lvl"] or ""
    if level and level ~= "" then level = " (" .. level .. ")" end
    self.text:SetText(self.name .. "|cffaaaaaa" .. level)

    if pfDB[self.btype]["data"][self.id]["coords"] then
      self.text:SetTextColor(1,1,1)
    else
      self.text:SetTextColor(.5,.5,.5)
    end
  elseif self.btype == "items" then
    for _, key in ipairs({"U","O","V"}) do
      if items[self.id][key] then
        self[key]:Show()
      else
        self[key]:Hide()
      end
    end

    self.text:SetText("|cffff5555[?] |cffffffff" .. self.name)

    self:SetScript("OnUpdate", ResultButtonUpdate)
  end

  self.text:SetWidth(self.text:GetStringWidth())
  self:Show()
end

local function ResultButtonCreate(i, resultType)
  local f = CreateFrame("Button", nil, pfBrowser.tabs[resultType].list)
  f:SetPoint("TOPLEFT", pfBrowser.tabs[resultType].list, "TOPLEFT", 10, -i*30 + 5)
  f:SetPoint("BOTTOMRIGHT", pfBrowser.tabs[resultType].list, "TOPRIGHT", 10, -i*30 - 15)
  f:Hide()
  f:SetID(i)

  f.btype = resultType

  f.tex = f:CreateTexture("BACKGROUND")
  f.tex:SetAllPoints(f)
  f.tex:SetTexture(1,1,1, ( math.mod(i,2) == 1 and .02 or .04))


  -- text properties
  f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
  f.text:SetAllPoints(f)
  f.text:SetJustifyH("CENTER")
  f.idText = f:CreateFontString("ID", "LOW", "GameFontDisable")
  f.idText:SetPoint("LEFT", f, "LEFT", 30, 0)

  -- favourite button
  f.fav = CreateFrame("Button", nil, f)
  f.fav:SetHitRectInsets(-3,-3,-3,-3)
  f.fav:SetPoint("LEFT", 0, 0)
  f.fav:SetWidth(16)
  f.fav:SetHeight(16)
  f.fav.icon = f.fav:CreateTexture("OVERLAY")
  f.fav.icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\fav")
  f.fav.icon:SetAllPoints(f.fav)

  -- faction icons
  if resultType ~= "items" then
    f.factionA = f:CreateTexture("OVERLAY")
    f.factionA:SetTexture("Interface\\AddOns\\pfQuest\\img\\icon_alliance")
    f.factionA:SetWidth(16)
    f.factionA:SetHeight(16)
    f.factionA:SetPoint("RIGHT", -5, 0)
    f.factionH = f:CreateTexture("OVERLAY")
    f.factionH:SetTexture("Interface\\AddOns\\pfQuest\\img\\icon_horde")
    f.factionH:SetWidth(16)
    f.factionH:SetHeight(16)
    f.factionH:SetPoint("RIGHT", -24, 0)
  end

  -- drop, loot, vendor buttons
  if resultType == "items" then
    local buttons = {
      ["U"] = { ["offset"] = -5,  ["icon"] = "icon_npc",    ["parameter"] = "id",   },
      ["O"] = { ["offset"] = -24, ["icon"] = "icon_object", ["parameter"] = "id",   },
      ["V"] = { ["offset"] = -43, ["icon"] = "icon_vendor", ["parameter"] = "name", },
    }

    for button, settings in pairs(buttons) do
      f[button] = CreateFrame("Button", nil, f)
      f[button]:SetHitRectInsets(-3,-3,-3,-3)
      f[button]:SetPoint("RIGHT", settings.offset, 0)
      f[button]:SetWidth(16)
      f[button]:SetHeight(16)

      f[button].buttonType = button
      f[button].parameter = settings.parameter

      f[button].icon = f[button]:CreateTexture("OVERLAY")
      f[button].icon:SetAllPoints(f[button])
      f[button].icon:SetTexture("Interface\\AddOns\\pfQuest\\img\\"..settings.icon)

      f[button]:SetScript("OnEnter", ResultButtonEnterSpecial)
      f[button]:SetScript("OnLeave", ResultButtonLeaveSpecial)
      f[button]:SetScript("OnClick", ResultButtonClickSpecial)
    end
  end

  -- bind functions
  f.Reload = ResultButtonReload
  f:SetScript("OnLeave", ResultButtonLeave)
  f:SetScript("OnEnter", ResultButtonEnter)
  f:SetScript("OnClick", ResultButtonClick)
  f.fav:SetScript("OnClick", ResultButtonClickFav)

  return f
end

local function SelectView(view)
  for id, frame in pairs(pfBrowser.tabs) do
    frame:Hide()
  end
  view:Show()
end

-- sets the browser result values when they change
local function RefreshView(i, key, caption)
  pfBrowser.tabs[key].list:SetHeight(i * 30 )
  pfBrowser.tabs[key].list:GetParent():SetScrollChild(pfBrowser.tabs[key].list)
  pfBrowser.tabs[key].list:GetParent():SetVerticalScroll(0)
  pfBrowser.tabs[key].list:GetParent():UpdateScrollState()

  pfBrowser.tabs[key].button:SetText(caption .. " " .. "|cffaaaaaa(" .. i .. ")")
  for j=i+1, table.getn(pfBrowser.tabs[key].buttons) do
    if pfBrowser.tabs[key].buttons[j] then pfBrowser.tabs[key].buttons[j]:Hide() end
  end
end

-- sets up all the browse windows and their activation buttons
local function CreateBrowseWindow(fname, name, parent, anchor, x, y)
  if not parent.tabs then parent.tabs = {} end
  parent.tabs[fname] = pfUI.api.CreateScrollFrame(name, parent)
  parent.tabs[fname]:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -65)
  parent.tabs[fname]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 45)
  parent.tabs[fname].buttons = { }

  parent.tabs[fname].backdrop = CreateFrame("Frame", name .. "Backdrop", parent.tabs[fname])
  parent.tabs[fname].backdrop:SetFrameLevel(1)
  parent.tabs[fname].backdrop:SetPoint("TOPLEFT", parent.tabs[fname], "TOPLEFT", -5, 5)
  parent.tabs[fname].backdrop:SetPoint("BOTTOMRIGHT", parent.tabs[fname], "BOTTOMRIGHT", 5, -5)
  pfUI.api.CreateBackdrop(parent.tabs[fname].backdrop, nil, true)

  parent.tabs[fname].button = CreateFrame("Button", name .. "Button", parent)
  parent.tabs[fname].button:SetPoint(anchor, x, y)
  parent.tabs[fname].button:SetWidth(153)
  parent.tabs[fname].button:SetHeight(30)
  parent.tabs[fname].button:SetScript("OnClick", function()
    SelectView(parent.tabs[fname])
  end)

  parent.tabs[fname].button.text = parent.tabs[fname].button:CreateFontString("Caption", "LOW", "GameFontWhite")
  parent.tabs[fname].button.text:SetAllPoints(parent.tabs[fname].button)
  parent.tabs[fname].button.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  pfUI.api.SkinButton(parent.tabs[fname].button)

  parent.tabs[fname].list = pfUI.api.CreateScrollChild(name .. "Scroll", parent.tabs[fname])
  parent.tabs[fname].list:SetWidth(600)

  parent.tabs[fname]:Hide()
end

-- minimap icon
pfBrowserIcon = CreateFrame('Button', "pfBrowserIcon", Minimap)
pfBrowserIcon:SetClampedToScreen(true)
pfBrowserIcon:SetMovable(true)
pfBrowserIcon:EnableMouse(true)
pfBrowserIcon:RegisterForDrag('LeftButton')
pfBrowserIcon:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
pfBrowserIcon:SetScript("OnDragStart", function()
  if IsShiftKeyDown() then
    this:StartMoving()
  end
end)
pfBrowserIcon:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
pfBrowserIcon:SetScript("OnClick", function()
  if arg1 == "RightButton" then
    if pfQuestConfig:IsShown() then pfQuestConfig:Hide() else pfQuestConfig:Show() end
  else
    if pfBrowser:IsShown() then pfBrowser:Hide() else pfBrowser:Show() end
  end
end)

pfBrowserIcon:SetScript("OnEnter", function()
  GameTooltip:SetOwner(this, ANCHOR_BOTTOMLEFT)
  GameTooltip:SetText("pfQuest 数据浏览器 - 3.0测试版")
  GameTooltip:AddDoubleLine("左键", "打开浏览器", 1, 1, 1, 1, 1, 1)
  GameTooltip:AddDoubleLine("右键", "打开配置", 1, 1, 1, 1, 1, 1)
  GameTooltip:AddDoubleLine("Shift左键", "移动按钮", 1, 1, 1, 1, 1, 1)
  GameTooltip:Show()
end)

pfBrowserIcon:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)

pfBrowserIcon:SetFrameStrata('LOW')
pfBrowserIcon:SetWidth(31)
pfBrowserIcon:SetHeight(31)
pfBrowserIcon:SetFrameLevel(9)
pfBrowserIcon:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
pfBrowserIcon:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

pfBrowserIcon.overlay = pfBrowserIcon:CreateTexture(nil, 'OVERLAY')
pfBrowserIcon.overlay:SetWidth(53)
pfBrowserIcon.overlay:SetHeight(53)
pfBrowserIcon.overlay:SetTexture('Interface\\Minimap\\MiniMap-TrackingBorder')
pfBrowserIcon.overlay:SetPoint('TOPLEFT', 0,0)

pfBrowserIcon.icon = pfBrowserIcon:CreateTexture(nil, 'BACKGROUND')
pfBrowserIcon.icon:SetWidth(20)
pfBrowserIcon.icon:SetHeight(20)
pfBrowserIcon.icon:SetTexture('Interface\\AddOns\\pfQuest\\img\\logo')
pfBrowserIcon.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
pfBrowserIcon.icon:SetPoint('CENTER',1,1)

-- browser window
pfBrowser = CreateFrame("Frame", "pfQuestBrowser", UIParent)
pfBrowser:Hide()
pfBrowser:SetWidth(640)
pfBrowser:SetHeight(480)
pfBrowser:SetPoint("CENTER", 0, 0)
pfBrowser:SetFrameStrata("FULLSCREEN_DIALOG")
pfBrowser:SetMovable(true)
pfBrowser:EnableMouse(true)
pfBrowser:SetScript("OnMouseDown",function()
  this:StartMoving()
end)

pfBrowser:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
end)

pfUI.api.CreateBackdrop(pfBrowser, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestBrowser")

pfBrowser.title = pfBrowser:CreateFontString("Status", "LOW", "GameFontNormal")
pfBrowser.title:SetFontObject(GameFontWhite)
pfBrowser.title:SetPoint("TOP", pfBrowser, "TOP", 0, -8)
pfBrowser.title:SetJustifyH("LEFT")
pfBrowser.title:SetFont(pfUI.font_default, 14)
pfBrowser.title:SetText("|cff33ffccpf|rQuest 数据浏览器 - 3.0测试版")

pfBrowser.close = CreateFrame("Button", "pfQuestBrowserClose", pfBrowser)
pfBrowser.close:SetPoint("TOPRIGHT", -5, -5)
pfBrowser.close:SetHeight(12)
pfBrowser.close:SetWidth(12)
pfBrowser.close.texture = pfBrowser.close:CreateTexture("pfQuestionDialogCloseTex")
pfBrowser.close.texture:SetTexture("Interface\\AddOns\\pfQuest\\compat\\close")
pfBrowser.close.texture:ClearAllPoints()
pfBrowser.close.texture:SetAllPoints(pfBrowser.close)
pfBrowser.close.texture:SetVertexColor(1,.25,.25,1)
pfUI.api.SkinButton(pfBrowser.close, 1, .5, .5)
pfBrowser.close:SetScript("OnClick", function()
 this:GetParent():Hide()
end)

pfBrowser.clean = CreateFrame("Button", "pfQuestBrowserClean", pfBrowser)
pfBrowser.clean:SetPoint("TOPLEFT", pfBrowser, "TOPLEFT", 545, -30)
pfBrowser.clean:SetPoint("BOTTOMRIGHT", pfBrowser, "TOPRIGHT", -5, -55)
pfBrowser.clean:SetScript("OnClick", function()
  pfMap:DeleteNode("PFDB")
  pfMap:UpdateNodes()
end)
pfBrowser.clean.text = pfBrowser.clean:CreateFontString("Caption", "LOW", "GameFontWhite")
pfBrowser.clean.text:SetAllPoints(pfBrowser.clean)
pfBrowser.clean.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.clean.text:SetText("清除地图")
pfUI.api.SkinButton(pfBrowser.clean)

CreateBrowseWindow("units", "pfQuestBrowserUnits", pfBrowser, "BOTTOMLEFT", 5, 5)
CreateBrowseWindow("objects", "pfQuestBrowserObjects", pfBrowser, "BOTTOMLEFT", 164, 5)
CreateBrowseWindow("items", "pfQuestBrowserItems", pfBrowser, "BOTTOMRIGHT", -164, 5)
CreateBrowseWindow("quests", "pfQuestBrowserQuests", pfBrowser, "BOTTOMRIGHT", -5, 5)

SelectView(pfBrowser.tabs["units"])

pfBrowser.input = CreateFrame("EditBox", "pfQuestBrowserSearch", pfBrowser)
pfBrowser.input:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.input:SetAutoFocus(false)
pfBrowser.input:SetText("搜索")
pfBrowser.input:SetJustifyH("LEFT")
pfBrowser.input:SetPoint("TOPLEFT", pfBrowser, "TOPLEFT", 5, -30)
pfBrowser.input:SetPoint("BOTTOMRIGHT", pfBrowser, "TOPRIGHT", -100, -55)
pfBrowser.input:SetTextInsets(10,10,5,5)
pfBrowser.input:SetScript("OnEscapePressed", function() this:ClearFocus() end)
pfBrowser.input:SetScript("OnEditFocusGained", function()
  if this:GetText() == "搜索" then this:SetText("") end
end)

pfBrowser.input:SetScript("OnEditFocusLost", function()
  if this:GetText() == "" then this:SetText("搜索") end
end)

-- This script updates all the search tabs when the search text changes
pfBrowser.input:SetScript("OnTextChanged", function()
  local text = this:GetText()
  if (text == "搜索") then text = "" end

  for _, caption in ipairs({"Units","Objects","Items","Quests"}) do
    local searchType = strlower(caption)

    local data = strlen(text) >= 3 and pfDatabase:GetIDByName(text, searchType, true) or pfBrowser_fav[searchType]

    local i = 0
    for id, text in pairs(data) do
      i = i + 1

      pfBrowser.tabs[searchType].buttons[i] = pfBrowser.tabs[searchType].buttons[i] or ResultButtonCreate(i, searchType)
      pfBrowser.tabs[searchType].buttons[i].id = id
      pfBrowser.tabs[searchType].buttons[i].name = text
      pfBrowser.tabs[searchType].buttons[i]:Reload()
      --if i >= search_limit then break end
    end

    RefreshView(i, searchType, caption)
  end
end)

pfUI.api.CreateBackdrop(pfBrowser.input, nil, true)
