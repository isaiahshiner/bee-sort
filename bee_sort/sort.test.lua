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

-- We prefer a bee that has all traits purebred,
-- even if we don't actually sort by that trait.
-- This way, all produced drones will stack
-- these currently don't work because the raw data was generated incorrectly.
function TestBeesUnrelatedSlotOne()
    local slot = getSlots(10, GetBreedSlot, "example_tables/bees_uncategorized.lua")
    lu.assertEquals(slot, 1)
end

function TestBeesUnrelatedSlotTwo()
    local slot = getSlots(5, GetBreedSlot, "example_tables/bees_uncategorized.lua")
    lu.assertEquals(slot, 1)
end

function TestBeesTrash()
    local expected = {
        72,
        74,
        69,
        69,
        79,
        78,
        68,
        86,
        64,
        84,
        64,
        77,
        85,
        85,
        82,
        81,
        73,
        71,
        83,
        58,
        63,
        37,
        16,
        33,
        37
    }
    local slots = getSlots(5, GetTrashSlots, "example_tables/bees_e2e.lua")
    lu.assertEquals(slots, expected)
end
