require("table_utils.table_utils")
require("bee_sort.sort")
local lu = require('luaunit')

GenerateComparators()

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
    return slots, count
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
    -- This is 12 stacks of cobblestone, 1-5 and then multiples of 12
    local expected = { 1, 36, 24, 48, 72, 60, 12, 84, 4, 2, 5, 3 }
    local slots = getSlots(5, GetTrashSlots, "example_tables/bees_trash.lua")
    for i, expectedSlot in ipairs(expected) do
        -- we don't care about order
        lu.assertTableContains(slots, expectedSlot)
    end
    lu.assertEquals(table.length(slots), table.length(expected))
end

function TestLength()
    local function chooseAll(sortedItems, count) return sortedItems end
    local slots, count = getSlots(5, chooseAll, "example_tables/bees_e2e.lua")
    local length = table.length(slots)
    lu.assertEquals(length, count)
end

TestLength()

function TestComparatorValidity()
    -- manually prove that the comparator is valid
    -- Meaning, com(a, b) and com(b, a) are never both true
    -- They _can_ both be false, but not true.
    local stacks, count = getStacks("example_tables/bees_e2e.lua")

    -- WET: copied from GetSortedItems
    local items = GetItemObjsFromStacks(stacks)

    -- literally just compare every item to every other item, including itself
    for _, comparator in ipairs(ComparatorList) do
        for _, itemOne in ipairs(items) do
            for _, itemTwo in ipairs(items) do
                -- manual conditional breakpoint
                -- if itemOne.slot == 3 and itemTwo.slot == 40 then
                --     print("here")
                -- end
                local aBetter = comparator(itemOne, itemTwo)
                local bBetter = comparator(itemTwo, itemOne)
                lu.assertFalse(aBetter and bBetter)
            end
        end
    end
end
