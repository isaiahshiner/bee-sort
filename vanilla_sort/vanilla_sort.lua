-- Demo func of bee sorting,
-- but with simplier vanilla Items

require('table_utils.table_utils')

ValueChart =
{
    ["planks"] = 1,
    ["cobblestone"] = 2,
    ["leather"] = 3,
    ["iron_ingot"] = 4,
    ["gold_ingot"] = 5,
    ["dye"] = 6,
    ["diamond"] = 7,
    ["obsidian"] = 8,
    ["emerald"] = 9,
}

local function getBreedSlot(stacks)
    local bestSlot = -1
    local bestValue = -1
    for slot, item in pairs(stacks) do
        local value = ValueChart[item.name]
        if value > bestValue then
            bestSlot = slot
            bestValue = value
        end
    end
    return bestSlot
end

local vanillaRes = table.load("vanilla_sort/vanilla_res.lua")

local slot = getBreedSlot(vanillaRes)
print(slot)
