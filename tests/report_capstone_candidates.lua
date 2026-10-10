-- Print exact custom Talent.dbc candidates and positions from the pinned server DBC.
-- Kept as a maintainer diagnostic so expansions can be rechecked after DBC updates.
dofile("NTalentCalculator/Data.lua")
local db = assert(NTalentCalculatorData)
local chosen = {shaman = "Enhancement", warlock = "Affliction"}
for class, name in pairs(chosen) do
    local found = false
    for _, tree in ipairs(db.classes[class] or {}) do
        if tree[2] == name then
            found = true
            print("TREE", class, tree[1], tree[2])
            for _, talent in ipairs(tree[4]) do
                local label = string.lower(talent[5] or "")
                if talent[2] >= 5 and talent[2] <= 8 or
                    label:find("dual wield", 1, true) or
                    label:find("contagion", 1, true) or
                    label:find("stormstrike", 1, true) or
                    label:find("dark pact", 1, true) then
                    print("TALENT", class, tree[1], talent[1],
                        "row=" .. (talent[2] + 1), "col=" .. (talent[3] + 1),
                        talent[5], "maxrank=" .. #talent[4],
                        "prereq=" .. tostring(talent[7] or 0))
                end
            end
        end
    end
    assert(found, "Missing specialization " .. class .. ": " .. name)
end
print("Approved custom DBC capstone candidate report complete.")
