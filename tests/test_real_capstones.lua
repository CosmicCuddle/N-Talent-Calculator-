-- Regression against the REAL approved custom server Talent.dbc snapshot.
-- This catches incorrect hardcoded capstones even if synthetic engine tests pass.
dofile("NTalentCalculator/Data.lua")
function UnitClass() return "Shaman", "SHAMAN" end
DEFAULT_CHAT_FRAME = {AddMessage=function() end}
NTalentCalculatorDB = {builds={}}
dofile("NTalentCalculator/Engine.lua")
local M = NTalentCalculator
assert(M:Initialize(), "Talent engine must initialise against actual approved DBC")

local function verify(class, treeId, name, preferredId, preferredName,
                      sideId, sideName)
    local tree
    for _, candidate in ipairs(M:GetTrees(class) or {}) do
        if candidate[1] == treeId then tree = candidate break end
    end
    assert(tree and tree[2] == name, "Missing approved tree " .. class .. ":" .. name)
    local capstone, side
    for _, talent in ipairs(tree[4]) do
        if talent[1] == preferredId then capstone = talent end
        if talent[1] == sideId then side = talent end
    end
    assert(capstone and capstone[5] == preferredName,
        "Wrong talent ID or name for Vanilla " .. name)
    assert(side and side[5] == sideName,
        "Incorrect later-era talent mapping in " .. name)
    assert(capstone[2] == 6 and capstone[3] == 1,
        preferredName .. " must be row 7, centre column in custom DBC")
    assert(side[2] == 6 and side[3] ~= 1,
        sideName .. " must be an off-centre row-7 talent")
    assert(M:Available(capstone, tree, "vanilla"),
        preferredName .. " must be the Vanilla capstone")
    assert(not M:Available(side, tree, "vanilla"),
        sideName .. " must not be displayed in Vanilla")
    assert(M:Available(capstone, tree, "tbc") and
        M:Available(side, tree, "tbc"),
        "Both row-7 talents become visible during TBC")
    assert(M:Available(side, tree, "wotlk"),
        sideName .. " should remain visible in Wrath")
    local count = 0
    local soleTalent
    for _, talent in ipairs(tree[4]) do
        if talent[2] == 6 and M:Available(talent, tree, "vanilla") then
            count = count + 1
            soleTalent = talent[1]
        end
    end
    assert(count == 1 and soleTalent == preferredId,
        name .. ": expected only " .. preferredName .. " in Vanilla row 7")

    assert(M:SetProgression("vanilla", 6))
    assert(M:SetClass(class))
    local valid, why = M:Validate({[sideId]=1})
    assert(not valid and why and why:find("unavailable",1,true),
        "Invalid Vanilla side talent must be rejected by build validation")
    print("Verified: Vanilla " .. class .. " " .. name .. " = " ..
        preferredName .. " (" .. preferredId .. "); " ..
        sideName .. " (" .. sideId .. ") starts in TBC")
end

verify("shaman", 263, "Enhancement", 1690, "Dual Wield",
    901, "Stormstrike")
verify("warlock", 302, "Affliction", 1669, "Contagion",
    1022, "Dark Pact")

-- The original (valid) TBC Holy off-centre rule must not be lost.
local holy
for _, tree in ipairs(M:GetTrees("paladin") or {}) do
    if tree[1] == 382 then holy = tree break end
end
assert(holy and M.OFF_CENTRE.tbc[382] == 1747,
    "TBC Holy off-centre special case must be preserved")
local illumination = M:FindTalent(1747, "paladin")
assert(illumination and M:Available(illumination, holy, "tbc"),
    "Divine Illumination must remain the TBC Holy capstone")

-- Dual Wield has a real prerequisite in the custom DBC; it cannot be
-- bypassed by choosing its era. Verify its source talent still exists.
local dw = M:FindTalent(1690, "shaman")
local prerequisite = dw and M:FindTalent(dw[7], "shaman")
assert(dw and dw[7] and dw[7] ~= 0 and prerequisite,
    "Dual Wield's real DBC prerequisite must remain present and enforced")
print("Approved DBC Vanilla capstone regression tests passed.")
