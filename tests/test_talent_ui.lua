-- Static UI regression for N Talent Calculator on WoW 3.3.5a / Lua 5.1.
-- Uses the real pinned DBC data and mock Blizzard widgets, no client required.
local frames = {}
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
function model:SetPoint(...) self.pos={...} end
function model:ClearAllPoints() self.pos=nil end
function model:SetAllPoints() end
function model:SetText(t) self.text=t end
function model:GetText() return self.text end
function model:SetTextColor() end
function model:SetJustifyH() end
function model:SetShadowOffset() end
function model:SetBackdrop() end
function model:SetBackdropColor() end
function model:SetBackdropBorderColor() end
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
function model:CreateFontString() return create() end
function model:CreateTexture() return create() end
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
local code=M:ExportCode()
window.exportButton.scripts.OnClick(window.exportButton)
assert(window.code:GetText()==code and window.code.selected,
    "Show code must select the website-compatible build for Ctrl+C")
M.points={}
window.code:SetText(code)
window.importButton.scripts.OnClick(window.importButton)
assert((M.points[first.talent[1]] or 0)==rankBefore+1,
    "Import button failed to restore the selected build")

M:ToggleWindow()
assert(not window:IsShown(),"Calculator should toggle closed")
print("N Talent Calculator UI: Vanilla/TBC/Wrath visibility, clicks, code copy/import passed")
