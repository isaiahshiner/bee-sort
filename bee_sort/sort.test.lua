require("table_utils.table_utils")
require("bee_sort.sort")
local lu = require('luaunit')

local function getStacks(path)
    local stacks = table.load(path)
    local count = table.length(stacks)
    return stacks, count
end

local function getSlots(randomseed, chooser, path)
    local stacks, count = getStacks(path)
    math.randomseed(randomseed)
    local sortedItems = GetSortedItems(stacks, count)
    local slots = chooser(sortedItems, count)
    return slots
end

-- We should randomly choose between both bees.
-- I found a seed which always chooses one or the other
function TestBeesInactiveSlotOne()
    local slot = getSlots(10, GetBreedSlot, "example_tables/bees_inactive.lua")
    lu.assertEquals(slot, 1)
end

function TestBeesInactiveSlotTwo()
    local slot = getSlots(5, GetBreedSlot, "example_tables/bees_inactive.lua")
    lu.assertEquals(slot, 2)
end

function TestBeesTrash()
    local slots = getSlots(5, GetTrashSlots, "example_tables/bees_e2e.lua")
    lu.assertEquals(slots, { 66, 65, 50, 53, 51, 36, 58, 35, 36 })
end
