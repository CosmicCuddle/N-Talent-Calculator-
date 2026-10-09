-- Static UI regression for N Talent Calculator on WoW 3.3.5a / Lua 5.1.
-- Uses the real pinned DBC data and mock Blizzard widgets, no client required.
local frames = {}
local textures = {}
local model = {}
model.__index = model
local function create()
    return setmetatable({visible=false,scripts={}},model)
end
function model:SetWidth(w) self.width=w end
function model:SetHeight(h) self.height=h end
function model:GetWidth() return self.width end
function model:GetHeight() return self.height end
function model:SetSize(w,h) self.width=w self.height=h end
function model:SetScale(s) self.scale=s end
function model:GetFrameLevel() return self.level or 1 end
function model:SetFrameLevel(level) self.level=level end
function model:SetPoint(...) self.pos={...} end
function model:ClearAllPoints() self.pos=nil end
function model:SetAllPoints(target) self.allPoints = target or self.parent end
function model:SetText(t) self.text=t end
function model:GetText() return self.text end
function model:SetTextColor() end
function model:SetJustifyH(value) self.justify = value end
function model:SetShadowOffset(x,y) self.shadowOffset={x,y} end
function model:SetShadowColor(r,g,b,a) self.shadowColor={r,g,b,a} end
function model:SetBackdrop(value) self.backdrop=value end
function model:SetBackdropColor() end
function model:SetBackdropBorderColor(...) self.tint={...} end
function model:SetTexture(t) self.texture=t end
function model:SetVertexColor(...) self.tint={...} end
function model:SetDesaturated(value) self.desaturated=value end
function model:SetHighlightTexture() end
function model:SetFrameStrata() end
function model:SetToplevel() end
function model:SetMovable() end
function model:EnableMouse() end
function model:RegisterForDrag() end
function model:RegisterForClicks() end
function model:SetClampedToScreen() end
function model:SetScript(e,f) self.scripts[e]=f end
function model:CreateFontString()
    local label = create()
    label.parent = self
    return label
end
function model:CreateTexture(name, drawLayer, sublevel)
    local texture = create()
    texture.parent = self
    texture.drawLayer = drawLayer
    texture.sublevel = sublevel
    textures[#textures + 1] = texture
    return texture
end
function model:SetAutoFocus() end
function model:SetMaxLetters() end
function model:SetFocus() self.focused=true end
function model:HighlightText() self.selected=true end
function model:ClearFocus() self.focused=false end
function model:Show() self.visible=true end
function model:Hide() self.visible=false end
function model:IsShown() return self.visible end
function CreateFrame(kind,name,parent,template)
    local f=create()
    f.kind=kind
    f.template=template
    f.parent=parent
    if name then _G[name]=f end
    table.insert(frames,f)
    return f
end
UIParent=create()
UIParent:SetSize(1920,1080)
SlashCmdList={}
UISpecialFrames={}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
function UnitClass() return "Warrior","WARRIOR" end

dofile("NTalentCalculator/Data.lua")
dofile("NTalentCalculator/Engine.lua")
local M=NTalentCalculator
assert(M:Initialize())
dofile("NTalentCalculator/UI.lua")
M:SetProgression("vanilla",1)
M:ToggleWindow()
local window=NTalentCalculatorFrame
assert(window and window:IsShown(), "Talent UI failed to open")
assert(window.width == 940 and window.height == 550,
    "Compact Vanilla planner must use the reviewed 940px layout")
assert(window.code.width == 552, "Code box must leave room for its buttons")
assert(43 + window.code.width + 15 <=
    window.width - 226 - window.exportButton.width,
    "Code box must never overlap the Show code button")
assert(window.className.justify == "CENTER" and window.budget.justify == "CENTER",
    "Class controls should be visually grouped")
local header = window.headerBar
assert(header and header.parent == window and
       header.width == 878 and header.height == 52,
    "The status and class controls must share one compact header bar")
assert(header.pos and header.pos[4] == 31 and header.pos[5] == -60,
    "Header bar must align with the three talent panels")
assert(header.backdrop and header.backdrop.edgeSize == 12,
    "Native WoW framed background is required on the new header")
assert(window.previous.parent == header and window.nextClass.parent == header,
    "Previous/next class buttons must belong to the grouped status bar")
assert(window.className.parent == header and window.budget.parent == header and
       window.era.parent == header and window.tierLabel.parent == header,
    "Tier, class and talent budget must remain visually grouped")
assert(window.previous.pos[4] == 320 and window.nextClass.pos[4] == 566,
    "Class controls should use short, compact navigation buttons")
assert(window.tierLabel.text:find("TIER 1", 1, true),
    "The header must report the authoritative progression tier")
assert(window.era.text:find("Rows 1-7", 1, true),
    "The header must still communicate visible talent rows")
local panelFrames = {}
for _, frame in ipairs(frames) do
    if frame.parent == window and frame.kind == "Frame" and
       frame.width == 282 then
        panelFrames[#panelFrames + 1] = frame
    end
end
assert(#panelFrames == 3, "Expected three identically sized compact tree panels")
for index, panel in ipairs(panelFrames) do
    assert(panel.pos[4] == 31 + (index - 1) * 298 and
        panel.pos[5] == -119,
        "Tree panels should align to symmetric 31px margins and 16px gaps")
    assert(panel.height == 325,
        "Vanilla panel should fit its seven rows without surplus empty space")
end
assert(window.height - (119 + panelFrames[1].height) - 80 >= 20,
    "Keep breathing room between bottom of talents and share-code section")
assert(#UISpecialFrames == 1 and UISpecialFrames[1] == "NTalentCalculatorFrame",
    "WoW must recognize the window as closable with Escape")
assert(window.era.text:find("Vanilla",1,true))
local function visibleTalentButtons()
    local count=0
    for _, frame in ipairs(frames) do
        if frame.talent and frame.visible then count=count+1 end
    end
    return count
end
local function expected()
    local total=0
    for _,tree in ipairs(M:GetTrees()) do
        for _,talent in ipairs(tree[4]) do
            if M:Available(talent,tree) then total=total+1 end
        end
    end
    return total
end
local function AssertThreeSpecBackgrounds(class)
    -- One seamless native-client spec image per panel. No more transparent
    -- 2x2 overlays or enlarged duplicate TopLeft texture (alpha.7 issue).
    assert(M:SetClass(class), "Class should be selectable in WotLK: " .. class)
    local artworks, imageBases = {}, {}
    for _, texture in ipairs(textures) do
        if texture.texture and texture.visible and
            texture.drawLayer == "ARTWORK" and texture.sublevel == -5 and
            texture.texture:find("^Interface\\TalentFrame\\") then
            artworks[#artworks+1] = texture
            local base = texture.texture:match("^Interface\\TalentFrame\\(.+)%-TopLeft$")
            assert(base, "Artwork must use one single-piece client background")
            imageBases[base] = true
        end
    end
    local imageCount = 0
    for _ in pairs(imageBases) do imageCount = imageCount + 1 end
    assert(#artworks == 3 and imageCount == 3,
        class .. " must have exactly one coherent art layer per spec, not stacked tiles")
    for _, art in ipairs(artworks) do
        assert(art.allPoints == art.parent,
            "Spec artwork must fill the entire talent panel")
        assert(art.tint and art.tint[4] >= 0.65 and art.tint[4] <= 0.80,
            "Artwork must be visible without overwhelming locked talents")
    end
    for _, tex in ipairs(textures) do
        assert(not (tex.visible and tex.sublevel == -6),
            "Old duplicate fill artwork must not remain visible")
    end
end

local vanilla=visibleTalentButtons()
assert(vanilla==expected(),"Vanilla UI must render all and only allowed talents")

-- Requirement-locked icons must actually become grey/desaturated,
-- not only show a subdued border. First-row talents stay vibrant.
local initialUnlocked, initialLocked
for _, button in ipairs(frames) do
    if button.visible and button.talent then
        if button.talent[2] == 0 and not button.lockReason then
            initialUnlocked = button
        end
        if button.talent[2] >= 1 and button.lockReason then
            initialLocked = button
        end
    end
end
assert(initialUnlocked and initialLocked,
    "Expected a selectable first row and an unavailable later row")
assert(initialUnlocked.icon.desaturated == false,
    "Purchasable talent should retain its colour")
assert(initialUnlocked.icon.tint[1] == 1,
    "Purchasable talent icon must not be darkened")
assert(initialLocked.icon.desaturated == true,
    "Locked talent should be desaturated")
assert(initialLocked.icon.tint[1] < 0.5,
    "Locked talent needs a faded icon as well as a grey border")
assert(type(initialLocked.lockReason) == "string" and
    initialLocked.lockReason:find("requires",1,true),
    "Unavailable talent should explain the prerequisite or row points")

M:SetProgression("tbc",8)
local tbc=visibleTalentButtons()
assert(tbc==expected(),"TBC UI must render all and only allowed talents")
assert(tbc>vanilla,"TBC should expose more talent options than Vanilla")

M:SetProgression("wotlk",13)
local wrath=visibleTalentButtons()
assert(wrath==expected(),"Wrath UI must render all and only allowed talents")
assert(wrath>tbc,"Wrath should expose more talents than TBC")

for _, class in ipairs(M.CLASS_ORDER) do
    AssertThreeSpecBackgrounds(class)
end
assert(M:SetClass("warlock"), "Could not test Warlock's historical spec textures")
local bases = {}
for _, texture in ipairs(textures) do
    if texture.texture and texture.visible then
        bases[texture.texture] = true
    end
end
assert(bases["Interface\\TalentFrame\\WarlockCurses-TopLeft"],
    "Affliction art must use actual Blizzard WarlockCurses filename")
assert(bases["Interface\\TalentFrame\\WarlockSummoning-TopLeft"],
    "Demonology art must use actual Blizzard WarlockSummoning filename")

-- Prerequisite connectors come from the approved Talent.dbc IDs and must
-- disappear when a later-era talent is hidden, with colours reflecting
-- completion of the specific required talent rank.
local function LinkStrokes()
    local strokes = {}
    for _, tex in ipairs(textures) do
        if tex.drawLayer == "ARTWORK" and tex.sublevel == -3 and tex.visible then
            strokes[#strokes+1] = tex
        end
    end
    return strokes
end

local candidate, chosenClass, chosenTree, expectedTarget
local greatestDelta = 0
for _, class in ipairs(M.CLASS_ORDER) do
    assert(M:SetClass(class))
    M:SetProgression("vanilla", 1)
    local countVanilla = #LinkStrokes()
    M:SetProgression("wotlk", 13)
    local countWotlk = #LinkStrokes()
    greatestDelta = math.max(greatestDelta, countWotlk - countVanilla)

    for _, tree in ipairs(M:GetTrees()) do
        local lookup = {}
        for _, talent in ipairs(tree[4]) do lookup[talent[1]] = talent end
        for _, talent in ipairs(tree[4]) do
            local req = talent[7]
            local source = req and lookup[req]
            if source and M:Available(talent, tree) and
               M:Available(source, tree) and
               (talent[2] > source[2] or talent[3] ~= source[3]) then
                local requiredRank = (talent[8] or 0) + 1
                if requiredRank <= #source[4] then
                    candidate, chosenClass, chosenTree = source, class, tree
                    expectedTarget = talent
                    break
                end
            end
        end
        if candidate then break end
    end
    if candidate then break end
end
assert(greatestDelta > 0 or candidate,
    "DBC talent dependencies should produce rendered connector lines")
assert(candidate and chosenClass,
    "Could not find any visible Talent.dbc prerequisite relationship")
assert(M:SetClass(chosenClass))
M:SetProgression("wotlk", 13)
local before = LinkStrokes()
assert(#before > 0, "Unfulfilled prerequisite links must be displayed")
local greyStroke = false
for _, tex in ipairs(before) do
    if math.abs(tex.tint[1] - 0.80) < 0.01 then greyStroke = true break end
end
assert(greyStroke, "Locked prerequisite connector must be grey")
local hasTrunk, hasHorizontal = false, false
for _, tex in ipairs(before) do
    if tex.width and tex.height then
        if tex.height >= 18 and tex.width <= 3 then hasTrunk = true end
        if tex.width >= 10 and tex.height <= 3 then hasHorizontal = true end
    end
end
assert(hasTrunk,
    "Prerequisite connections must extend visibly down an icon-free gutter")
assert(hasHorizontal,
    "Prerequisite connectors must attach to a talent icon across the gutter")
local arrowheads = 0
for _, tex in ipairs(textures) do
    if tex.visible and tex.drawLayer == "ARTWORK" and tex.sublevel == -2 then
        arrowheads = arrowheads + 1
    end
end
assert(arrowheads >= 3,
    "Every visible prerequisite path needs a distinct arrowhead near its target")
M.points[candidate[1]] = (expectedTarget[8] or 0) + 1
M:RefreshUI()
local greenStroke = false
for _, tex in ipairs(LinkStrokes()) do
    if tex.tint[2] > 0.90 and tex.tint[1] < 0.5 then
        greenStroke = true
        break
    end
end
assert(greenStroke, "Completed prerequisite connector must become green")
M.points = {}
M:RefreshUI()

-- Return to Warrior for the click / share-code assertions below.
assert(M:SetClass("warrior"))

local first
for _,frame in ipairs(frames) do
    if frame.talent and frame.visible and frame.talent[2]==0 then
        first=frame
        break
    end
end
assert(first,"No first-row talent available")
local rankBefore=M.points[first.talent[1]] or 0
first.scripts.OnClick(first,"LeftButton")
assert((M.points[first.talent[1]] or 0)==rankBefore+1,
    "Left click must allocate a planner point")
assert(first.icon.desaturated == false,
    "Allocated talents should never look greyed out")
assert(first.icon.tint[1] == 1 and first.border.tint[2] > 0.9,
    "Allocated talents should have full-colour icon and green border")
assert(first.border.allPoints == first,
    "Slot frame must fit the talent button with no protruding border")
assert(first.rankBacking == nil,
    "Talent ranks must be numbers only, without an opaque backing box")
assert(first.rank and first.rank.shadowOffset and
    first.rank.shadowOffset[1] == 1 and first.rank.shadowOffset[2] == -1,
    "Rank numbers should have a subtle readable offset shadow")
assert(first.rank.shadowColor and
    first.rank.shadowColor[1] == 0 and first.rank.shadowColor[2] == 0 and
    first.rank.shadowColor[3] == 0 and first.rank.shadowColor[4] == 1,
    "Rank numbers need a dark text shadow for visibility on bright icons")
assert(first.rank.pos and first.rank.pos[4] == -2 and
    first.rank.pos[5] == 1,
    "Rank counter should remain inside the talent slot")
assert(first.rank.text == "1/" .. #first.talent[4],
    "The numeric rank counter must continue to update when points are added")
for _, talentButton in ipairs(frames) do
    if talentButton.talent then
        assert(talentButton.rankBacking == nil,
            "No talent button should create a black box behind the numbers")
    end
end
assert(first.level and first.level >= 4,
    "Talent buttons must render above their spec artwork")
assert(first.border.backdrop and first.border.backdrop.edgeSize == 2,
    "Use a precise 2px edge rather than misaligned Quickslot art")
assert(first.icon.pos and first.icon.pos[1] == "BOTTOMRIGHT" and
       first.icon.pos[4] == -2 and first.icon.pos[5] == 2,
    "Talent icon must be inset within the 35x35 border")
local code=M:ExportCode()
window.exportButton.scripts.OnClick(window.exportButton)
assert(window.code:GetText()==code and window.code.selected,
    "Show code must select the website-compatible build for Ctrl+C")
M.points={}
window.code:SetText(code)
window.importButton.scripts.OnClick(window.importButton)
assert((M.points[first.talent[1]] or 0)==rankBefore+1,
    "Import button failed to restore the selected build")

-- Escape must work even if an edit box currently holds keyboard focus.
window.code:SetFocus()
window.code.scripts.OnEscapePressed(window.code)
assert(not window:IsShown() and not window.code.focused,
    "Escape in the build-code input must close the window")
M:ToggleWindow()
assert(window:IsShown(), "Calculator did not reopen after Escape")
M:ToggleWindow()
assert(not window:IsShown(), "Calculator should toggle closed")
assert(#UISpecialFrames == 1, "Escape registration must never be duplicated")
print("N Talent Calculator UI: 30 spec backgrounds, fitted borders, Escape, era filters and code sharing passed")
