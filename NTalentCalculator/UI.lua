-- N Talent Calculator - visual, read-only 3-tree planner (WoW 3.3.5a).
-- Share/import the exact NT1 codes used on Naxxramas Resource Hub.
-- Select text and use Ctrl+C to copy: 3.3.5a has no clipboard-write API.
-- Uses WoW's native TalentFrame artwork and UISpecialFrames Escape handling.

local M = NTalentCalculator
local window
local trees = {}
local buttons = {}
local shown = {}

-- Compact, consistent spacing across the header, three trees and footer.
-- 31 + (282 * 3) + (16 * 2) + 31 = 940 UI pixels.
local LAYOUT = {
    width = 940,
    panelX = 31,
    panelWidth = 282,
    panelGap = 16,
    panelTop = 119,
    rowStep = 39,
    columnStep = 63,
    iconX = 28,
    iconY = 45,
    panelBaseHeight = 52,
    frameBaseHeight = 277,
}


local function Label(parent, font, content, x, y, width)
    local value = parent:CreateFontString(nil, "OVERLAY", font)
    value:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then value:SetWidth(width) end
    value:SetJustifyH("LEFT")
    value:SetText(content or "")
    return value
end

local function PushButton(parent, title, width, x, y, func)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(title)
    button:SetScript("OnClick", func)
    return button
end

local function ShowTooltip(button)
    local talent = button.talent
    if not talent or not GameTooltip then return end
    local count = M.points[talent[1]] or 0
    local maxRank = #talent[4]
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(talent[5], 1, 0.84, 0.34)
    GameTooltip:AddLine("Rank " .. count .. "/" .. maxRank, 1, 1, 1)
    local function ShowRank(rank, heading)
        local spell = talent[4][rank]
        local effect = M.Data.tooltips[tostring(spell)]
        local text = effect and effect[1] or
            (talent[10] and talent[10][rank]) or talent[6] or
            "Tooltip not available in the supplied Spell.dbc."
        GameTooltip:AddLine(heading .. " (rank " .. rank .. "):", 0.53, 0.80, 1)
        GameTooltip:AddLine(text, 0.94, 0.94, 0.94, true)
        if effect and effect[2] then
            GameTooltip:AddLine("Some effect values depend on the client.", 1, 0.64, 0.35, true)
        end
    end
    if count > 0 then ShowRank(count, "Current") end
    if count < maxRank then ShowRank(count + 1, "Next") end
    if button.lockReason and count == 0 then
        GameTooltip:AddLine("Locked: " .. button.lockReason, 1, 0.42, 0.35, true)
    end
    GameTooltip:AddLine("Left-click: add rank. Right-click: remove rank.", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local function NewTalentButton(parent)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(35, 35)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- Crisp 35x35 talent slot: border hugs the button, with a 2px inset
    -- icon. The previous Quickslot2 texture protruded beyond the icon.
    local shadow = button:CreateTexture(nil, "BACKGROUND")
    shadow:SetTexture("Interface\\Buttons\\WHITE8X8")
    shadow:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    shadow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
    shadow:SetVertexColor(0, 0, 0, 0.75)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    button.icon = icon

    local border = CreateFrame("Frame", nil, button)
    border:SetAllPoints(button)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
        insets = {left=0, right=0, top=0, bottom=0}
    })
    button.border = border
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    -- Small inset counter with its own dark backing; avoids white ranks
    -- hanging outside the icon border on high UI scales.
    local rankBacking = button:CreateTexture(nil, "OVERLAY")
    rankBacking:SetTexture("Interface\\Buttons\\WHITE8X8")
    rankBacking:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
    rankBacking:SetWidth(25)
    rankBacking:SetHeight(11)
    rankBacking:SetVertexColor(0.015, 0.012, 0.018, 0.88)
    button.rankBacking = rankBacking

    local rank = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    rank:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 1)
    rank:SetShadowOffset(1, -1)
    button.rank = rank
    button:SetScript("OnClick", function(self, mouseButton)
        local delta = mouseButton == "RightButton" and -1 or 1
        local ok, issue = M:Adjust(self.talent[1], delta)
        if not ok then M:Print(issue) end
        if GameTooltip then
            GameTooltip:Hide()
            ShowTooltip(self)
        end
    end)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:Hide()
    return button
end

-- The greyed-out state is visual only; M:Validate remains the authority.
-- Already-ranked talents stay in full colour so players can distinguish
-- chosen skills from currently unavailable choices.
local function UpdateTalentAppearance(button, rank, reason)
    local locked = rank == 0 and reason ~= nil and reason ~= false
    button.lockReason = locked and reason or nil
    if button.icon.SetDesaturated then
        button.icon:SetDesaturated(locked and true or false)
    end
    if locked then
        button.icon:SetVertexColor(0.43, 0.43, 0.43)
        button.border:SetBackdropBorderColor(0.36, 0.36, 0.36)
    elseif rank > 0 then
        button.icon:SetVertexColor(1, 1, 1)
        button.border:SetBackdropBorderColor(0.22, 0.95, 0.30)
    else
        button.icon:SetVertexColor(1, 1, 1)
        button.border:SetBackdropBorderColor(0.90, 0.75, 0.27)
    end
end

-- Exact 3.3.5a TalentTab.dbc BackgroundFile names (Blizzard TalentFrameBase.lua).
-- A background texture is drawn ABOVE the panel backdrop, not behind it. They deliberately
-- differ from specialization titles for several specs (e.g. WarlockCurses).
-- Blizzard already ships these four-piece TalentFrame textures with WoW:
-- no extra image files, internet requests or third-party art licences.
local SPEC_BACKGROUNDS = {
    warrior = {arms="WarriorArms", fury="WarriorFury", protection="WarriorProtection"},
    paladin = {holy="PaladinHoly", protection="PaladinProtection", retribution="PaladinCombat"},
    hunter = {beastmastery="HunterBeastMastery", marksmanship="HunterMarksmanship", survival="HunterSurvival"},
    rogue = {assassination="RogueAssassination", combat="RogueCombat", subtlety="RogueSubtlety"},
    priest = {discipline="PriestDiscipline", holy="PriestHoly", shadow="PriestShadow"},
    deathknight = {blood="DeathKnightBlood", frost="DeathKnightFrost", unholy="DeathKnightUnholy"},
    shaman = {elemental="ShamanElementalCombat", enhancement="ShamanEnhancement", restoration="ShamanRestoration"},
    mage = {arcane="MageArcane", fire="MageFire", frost="MageFrost"},
    warlock = {affliction="WarlockCurses", demonology="WarlockSummoning", destruction="WarlockDestruction"},
    druid = {balance="DruidBalance", feralcombat="DruidFeralCombat", restoration="DruidRestoration"}
}

local function SpecTextureBase(class, treeName)
    local specs = SPEC_BACKGROUNDS[class]
    local key = type(treeName) == "string" and
        treeName:lower():gsub("[^a-z]", "") or ""
    local basename = specs and specs[key]
    if not basename then return nil end
    return "Interface\\TalentFrame\\" .. basename .. "-"
end

local function SetTreeBackground(view, class, treeName, panelHeight)
    local base = SpecTextureBase(class, treeName)
    for index, piece in ipairs(view.art) do
        piece:SetHeight(panelHeight / 2)
        if base then
            piece:SetTexture(base .. view.artSuffixes[index])
            piece:Show()
        else
            piece:Hide()
        end
    end
end

local function UpdateLayout()
    local rule = M.ERA[M.era]
    if not window or not rule then return end
    local visibleRows = rule.maxRow + 1
    local height = LAYOUT.frameBaseHeight + visibleRows * LAYOUT.rowStep
    window:SetHeight(height)
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if screenW > 100 and screenH > 100 then
        window:SetScale(math.max(0.55, math.min(1,
            (screenW - 38) / LAYOUT.width, (screenH - 38) / height)))
    end
end

local function CreateWindow()
    if window then return window end
    window = CreateFrame("Frame", "NTalentCalculatorFrame", UIParent)
    -- Blizzard's Escape-key close mechanism for named WoW UI windows.
    if type(UISpecialFrames) == "table" then
        local registered = false
        for _, name in ipairs(UISpecialFrames) do
            if name == "NTalentCalculatorFrame" then registered = true break end
        end
        if not registered then table.insert(UISpecialFrames, "NTalentCalculatorFrame") end
    end
    window:SetWidth(LAYOUT.width)
    window:SetHeight(LAYOUT.frameBaseHeight + 11 * LAYOUT.rowStep)
    window:SetPoint("CENTER", UIParent, "CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetClampedToScreen(true)
    window:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false, edgeSize = 32,
        insets = {left=9, right=9, top=9, bottom=9}
    })
    window:SetBackdropColor(0.025, 0.025, 0.035, 0.98)
    window:SetBackdropBorderColor(0.69, 0.55, 0.29, 1)
    window:Hide()

    -- Header: title + one compact three-column status/control bar.
    -- The old text and class buttons floated apart; the grouped bar gives
    -- progression, class selection, and talent budget equal visual weight.
    local heading = Label(window, "GameFontNormalLarge",
        "N Talent Calculator", 31, -17)
    heading:SetTextColor(1, 0.85, 0.37)
    Label(window, "GameFontDisableSmall",
        "Plan and share builds  |  Never changes your actual talents",
        31, -41, 650)

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -8, -8)

    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT", window, "TOPLEFT", 31, -60)
    header:SetWidth(878)
    header:SetHeight(52)
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 12,
        insets = {left=3, right=3, top=3, bottom=3}
    })
    header:SetBackdropColor(0.07, 0.06, 0.08, 0.96)
    header:SetBackdropBorderColor(0.52, 0.41, 0.24, 0.85)
    window.headerBar = header

    local function Divider(x)
        local divider = header:CreateTexture(nil, "ARTWORK")
        divider:SetTexture("Interface\\Buttons\\WHITE8X8")
        divider:SetPoint("TOPLEFT", header, "TOPLEFT", x, -10)
        divider:SetHeight(32)
        divider:SetWidth(1)
        divider:SetVertexColor(0.70, 0.55, 0.28, 0.48)
    end
    Divider(305)
    Divider(628)

    -- Left: compact automatic Individual Progression status.
    window.tierLabel = Label(header, "GameFontDisableSmall",
        "INDIVIDUAL PROGRESSION", 15, -8, 279)
    window.era = Label(header, "GameFontNormal",
        "Checking your progression...", 15, -27, 279)
    window.era:SetTextColor(1, 0.81, 0.36)

    -- Centre: one unified class selector.
    local classLabel = Label(header, "GameFontDisableSmall",
        "CLASS", 394, -7, 146)
    classLabel:SetJustifyH("CENTER")
    window.previous = PushButton(header, "<", 48, 320, -23, function()
        M:CycleClass(-1)
    end)
    window.className = Label(header, "GameFontNormal",
        "", 375, -31, 187)
    window.className:SetJustifyH("CENTER")
    window.nextClass = PushButton(header, ">", 48, 566, -23, function()
        M:CycleClass(1)
    end)

    -- Right: clearly identified current/planned talent-point budget.
    local pointLabel = Label(header, "GameFontDisableSmall",
        "TALENT POINTS", 649, -8, 209)
    pointLabel:SetJustifyH("CENTER")
    window.budget = Label(header, "GameFontNormal",
        "", 649, -27, 209)
    window.budget:SetJustifyH("CENTER")
    window.budget:SetTextColor(1, 0.81, 0.36)

    for i=1,3 do
        local panel = CreateFrame("Frame", nil, window)
        panel:SetPoint("TOPLEFT", window, "TOPLEFT",
            LAYOUT.panelX + (i - 1) * (LAYOUT.panelWidth + LAYOUT.panelGap),
            -LAYOUT.panelTop)
        panel:SetWidth(LAYOUT.panelWidth)
        panel:SetHeight(LAYOUT.panelBaseHeight + 11 * LAYOUT.rowStep)
        panel:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 14,
            insets = {left=3,right=3,top=3,bottom=3}
        })
        panel:SetBackdropColor(0.04, 0.035, 0.05, 0.96)
        panel:SetBackdropBorderColor(0.55, 0.43, 0.23, 1)

        -- BACKGROUND-layer tiles were hidden behind the nearly opaque
        -- backdrop in actual 3.3.5a client screenshots. Render the spec
        -- artwork on a low ARTWORK sublayer, ABOVE the backdrop, with a
        -- separate translucent veil one sublayer higher.
        local art = {}
        local suffixes = {"TopLeft", "TopRight", "BottomLeft", "BottomRight"}
        local anchors = {"TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"}
        for tileIndex=1,4 do
            local piece = panel:CreateTexture(nil, "ARTWORK", -5)
            piece:SetPoint(anchors[tileIndex], panel, anchors[tileIndex])
            piece:SetWidth(LAYOUT.panelWidth / 2)
            piece:SetHeight((LAYOUT.panelBaseHeight + 11 * LAYOUT.rowStep) / 2)
            -- Authentic Blizzard artwork should be visible, while retaining
            -- enough contrast for disabled talents and rank counters.
            piece:SetVertexColor(0.89, 0.86, 0.81, 0.90)
            art[tileIndex] = piece
        end
        local veil = panel:CreateTexture(nil, "ARTWORK", -4)
        veil:SetTexture("Interface\\Buttons\\WHITE8X8")
        veil:SetAllPoints(panel)
        veil:SetVertexColor(0.018, 0.015, 0.022, 0.28)

        -- Dark title bar and fine gold accent, above artwork and veil.
        local titleBar = panel:CreateTexture(nil, "ARTWORK", 1)
        titleBar:SetTexture("Interface\\Buttons\\WHITE8X8")
        titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 3, -3)
        titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -3, -3)
        titleBar:SetHeight(34)
        titleBar:SetVertexColor(0.025, 0.021, 0.025, 0.85)

        local titleLine = panel:CreateTexture(nil, "ARTWORK", 2)
        titleLine:SetTexture("Interface\\Buttons\\WHITE8X8")
        titleLine:SetPoint("TOPLEFT", panel, "TOPLEFT", 9, -37)
        titleLine:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -9, -37)
        titleLine:SetHeight(1)
        titleLine:SetVertexColor(0.75, 0.56, 0.20, 0.55)

        local name = Label(panel, "GameFontNormal", "", 14, -11, 185)
        local count = Label(panel, "GameFontHighlightSmall", "",
            LAYOUT.panelWidth - 64, -11, 52)
        count:SetJustifyH("RIGHT")
        trees[i] = {panel=panel, title=name, count=count, art=art, artSuffixes=suffixes, veil=veil}
    end

    -- All code sharing happens through the input field. Show code places a
    -- validated NT1 string here, and players use Ctrl+C to copy it.
    local codeLabel = Label(window, "GameFontNormalSmall",
        "Website-compatible NT1 build code (Ctrl+C to copy):", 31, -1, 450)
    codeLabel:ClearAllPoints()
    codeLabel:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 31, 80)

    window.code = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    window.code:SetSize(552, 26)
    window.code:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 43, 44)
    window.code:SetAutoFocus(false)
    window.code:SetMaxLetters(2000)
    window.code:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        window:Hide()
    end)
    window.code:SetScript("OnEnterPressed", function(self)
        local ok, reason = M:ImportCode(self:GetText())
        if not ok then M:Print(reason) else M:Print("Build imported.") end
        self:ClearFocus()
    end)

    window.exportButton = PushButton(window, "Show code", 95, 0, 0, function()
        local value = M:ExportCode()
        if not value then M:Print("Still waiting for progression tier.") return end
        window.code:SetText(value)
        window.code:SetFocus()
        window.code:HighlightText()
        M:Print("Code selected. Press Ctrl+C to copy.")
    end)
    window.exportButton:ClearAllPoints()
    window.exportButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -226, 45)

    window.importButton = PushButton(window, "Import", 85, 0, 0, function()
        local ok, reason = M:ImportCode(window.code:GetText())
        if not ok then M:Print(reason) else M:Print("Build imported.") end
    end)
    window.importButton:ClearAllPoints()
    window.importButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -133, 45)

    window.resetButton = PushButton(window, "Reset", 82, 0, 0, function()
        M.points = {}
        M:RefreshUI()
    end)
    window.resetButton:ClearAllPoints()
    window.resetButton:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -36, 45)

    window.notice = Label(window, "GameFontHighlightSmall",
        "Share builds with the website using NT1 codes. Save with /ntalent save NAME.", 32, -1, 880)
    window.notice:ClearAllPoints()
    window.notice:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 32, 20)
    return window
end

function M:CycleClass(step)
    if not self.era then self:Print("Waiting for your Individual Progression tier.") return end
    local index = 1
    for i, class in ipairs(self.CLASS_ORDER) do
        if class == self.class then index = i break end
    end
    for _=1,#self.CLASS_ORDER do
        index = ((index - 1 + step + #self.CLASS_ORDER) % #self.CLASS_ORDER) + 1
        local class = self.CLASS_ORDER[index]
        if class ~= "deathknight" or self.era == "wotlk" then
            self:SetClass(class)
            return
        end
    end
end

function M:RefreshUI()
    if not window or not window:IsShown() then return end
    if not self.era or not self:GetTrees(self.class) then
        window.era:SetText("Waiting for progression...")
        window.tierLabel:SetText("INDIVIDUAL PROGRESSION")
        window.budget:SetText("")
        window.className:SetText("")
        for _, button in ipairs(buttons) do button:Hide() end
        for _, tree in ipairs(trees) do tree.panel:Hide() end
        return
    end

    UpdateLayout()
    local rule = self.ERA[self.era]
    window.era:SetText(rule.title .. "   |   Rows 1-" .. (rule.maxRow + 1))
    window.tierLabel:SetText(self.tier and ("PROGRESSION  /  TIER " .. self.tier) or
        "PROGRESSION  /  QUEST ERA")
    window.className:SetText(string.upper(self.class))
    window.budget:SetText(self:Spent() .. " / " .. (self.level - 9) .. " points")
    for _, button in ipairs(buttons) do button:Hide() end

    local poolIndex = 0
    for index, tree in ipairs(self:GetTrees()) do
        local view = trees[index]
        view.panel:Show()
        local panelHeight = LAYOUT.panelBaseHeight +
            (rule.maxRow + 1) * LAYOUT.rowStep
        view.panel:SetHeight(panelHeight)
        SetTreeBackground(view, self.class, tree[2], panelHeight)
        view.title:SetText(tree[2])
        view.count:SetText(self:TreeSpent(tree) .. " pts")
        for _, talent in ipairs(tree[4]) do
            if self:Available(talent, tree) then
                poolIndex = poolIndex + 1
                local button = buttons[poolIndex]
                if not button then
                    button = NewTalentButton(window)
                    buttons[poolIndex] = button
                end
                -- Talent buttons are parented to the main window and can
                -- otherwise render under a tree panel's ARTWORK layer.
                -- Put their frame level above both the art and the veil.
                button:SetFrameLevel(view.panel:GetFrameLevel() + 3)
                local row, col = talent[2], talent[3]
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", view.panel, "TOPLEFT",
                    LAYOUT.iconX + col * LAYOUT.columnStep,
                    -LAYOUT.iconY - row * LAYOUT.rowStep)
                local iconKey = self.Data.icons[tostring(talent[9])]
                if type(iconKey) == "string" and
                    iconKey:match("^[a-zA-Z0-9_%-]+$") then
                    button.icon:SetTexture("Interface\\Icons\\" .. iconKey)
                else
                    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end
                button.talent = talent
                local rank = self.points[talent[1]] or 0
                button.rank:SetText(rank .. "/" .. #talent[4])
                local lockReason
                if rank == 0 then
                    local trial = {}
                    for k, v in pairs(self.points) do trial[k] = v end
                    trial[talent[1]] = 1
                    local available, why = self:Validate(trial)
                    if not available then lockReason = why or "Requirements not met." end
                end
                UpdateTalentAppearance(button, rank, lockReason)
                button:Show()
            end
        end
    end
    for i=poolIndex+1,#buttons do buttons[i]:Hide() end
end

function M:ToggleWindow()
    local frame = CreateWindow()
    if frame:IsShown() then frame:Hide() else frame:Show() self:RefreshUI() end
end

SLASH_NTALENT1 = "/ntalent"
SLASH_NTALENT2 = "/ntc"
SlashCmdList["NTALENT"] = function(text)
    text = (text or ""):match("^%s*(.-)%s*$")
    if text == "" then M:ToggleWindow()
    elseif text == "refresh" then
        M:RequestProgression()
        M:Print("Requested your Individual Progression tier from the server.")
    elseif text == "code" then
        M:ToggleWindow()
        local value = M:ExportCode()
        if window and value then
            window.code:SetText(value)
            window.code:SetFocus()
            window.code:HighlightText()
        end
    elseif text:sub(1,7) == "import " then
        local ok, reason = M:ImportCode(text:sub(8))
        if not ok then M:Print(reason) else M:Print("Build imported.") end
    elseif text:sub(1,5) == "save " then
        local ok, reason = M:SaveBuild(text:sub(6))
        M:Print(ok and "Build saved." or reason)
    elseif text:sub(1,5) == "load " then
        local ok, reason = M:LoadBuild(text:sub(6))
        M:Print(ok and "Saved build loaded." or reason)
    else
        M:Print("Commands: /ntalent, /ntalent code, /ntalent refresh, " ..
            "/ntalent import NT1:..., /ntalent save NAME, /ntalent load NAME")
    end
end
