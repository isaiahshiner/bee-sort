require("bee_sort.selectors")

-- Number of slots to keep in diamond chest
-- TODO: maybe a constants file?
MAX_SPACE = 72

-- Just FYI, I might have the comparisons
-- reversed from what's expected?
-- This assumes 'true' means that
-- 'a' is worse than 'b'
-- and false means that
-- 'a' is better than or equal to 'b'

local function compareRank(a, b)
    return a ~= b, a < b
end

local function compareSpeed(a, b)
    -- we want the fastest speed
    return a ~= b, a < b
end

local function compareLifeSpan(a, b)
    -- we actually want the slowest lifespan
    return a ~= b, a > b
end

local function compareTrait(a, b)
    -- a and b are bools, saying whether
    -- the bees are completely purebred,
    -- even for traits we don't care about,
    -- meaning their produced drones will always stack
    -- with this one.
    if a == b then
        return false, true
    else
        -- if b is true, its the one with equal traits, so 'b' its better
        -- otherwise, a is the one with equal traits, so 'b' is worse.
        return true, b
    end
end

local function compareSpeedComplete(a, b)
    local rankEq, rankCmp =
        compareRank(a.rank, b.rank)
    if rankEq then return rankCmp end

    local speedActEq, speedActCmp =
        compareSpeed(GetSpeed(a.bee, true), GetSpeed(b.bee, true))
    if speedActEq then return speedActCmp end

    local speedInEq, speedInCmp =
        compareSpeed(GetSpeed(a.bee, false), GetSpeed(b.bee, false))
    if speedInEq then return speedInCmp end

    local lifeActEq, lifeActCmp =
        compareLifeSpan(GetLifespan(a.bee, true), GetLifespan(b.bee, true))
    if lifeActEq then return lifeActCmp end

    local lifeInEq, lifeInCmp =
        compareLifeSpan(GetLifespan(a.bee, false), GetLifespan(b.bee, false))
    if lifeInEq then return lifeInCmp end

    local aTrait = table.isEqual(GetTrait(a.bee, true), GetTrait(a.bee, false))
    local bTrait = table.isEqual(GetTrait(b.bee, true), GetTrait(b.bee, false))
    local traitEq, traitCmp =
        compareTrait(aTrait, bTrait)
    if traitEq then return traitCmp end

    return false
end

local function compareLifespanComplete(a, b)
    local rankEq, rankCmp =
        compareRank(a.rank, b.rank)
    if rankEq then return rankCmp end

    local lifeActEq, lifeActCmp =
        compareLifeSpan(GetLifespan(a.bee, true), GetLifespan(b.bee, true))
    if lifeActEq then return lifeActCmp end

    local lifeInEq, lifeInCmp =
        compareLifeSpan(GetLifespan(a.bee, false), GetLifespan(b.bee, false))
    if lifeInEq then return lifeInCmp end

    local speedActEq, speedActCmp =
        compareSpeed(GetSpeed(a.bee, true), GetSpeed(b.bee, true))
    if speedActEq then return speedActCmp end

    local speedInEq, speedInCmp =
        compareSpeed(GetSpeed(a.bee, false), GetSpeed(b.bee, false))
    if speedInEq then return speedInCmp end

    local aTrait = table.isEqual(GetTrait(a.bee, true), GetTrait(a.bee, false))
    local bTrait = table.isEqual(GetTrait(b.bee, true), GetTrait(b.bee, false))
    local traitEq, traitCmp =
        compareTrait(aTrait, bTrait)
    if traitEq then return traitCmp end

    return false
end

-- I'll have to be more clever to make something like this work,
-- Esp with more than 2 criteria.
-- local function createComparator(comparator, selector)
--     local function innerCompare(a, b)
--         local rankEq, rankCmp =
--             compareRank(a.rank, b.rank)
--         if rankEq then return rankCmp end

--         local critActEq, critActCmp =
--             comparator(selector(a.bee, true), selector(b.bee, true))
--         if critActEq then return critActCmp end

--         local critInEq, critInCmp =
--             comparator(selector(a.bee, false), selector(b.bee, false))
--         if critInEq then return critInCmp end

--         return false
--     end

--     return innerCompare
-- end

Criteria = {
    compareSpeedComplete,
    compareLifespanComplete
}

local function getSimpleRank(bee)
    if not IsBee(bee) then return -1 end
    if not IsPure(bee, GetName) then return 0 end
    -- As long as its a purebred bee,
    -- we have to do multiple criteria sort.
    return 1
end

local function getItemsSortedByCriterion(items, criteriaComparator)
    local sortedItems = table.shallow_copy(items)
    table.sort(sortedItems, criteriaComparator)
    return sortedItems
end

function GetSortedItems(stacks, count)
    local items = {}
    for slot, bee in pairs(stacks) do
        local rank = getSimpleRank(bee)
        local slotObj = {
            ["slot"] = slot,
            ["rank"] = rank,
            ["bee"] = bee
        }
        table.insert(items, slotObj)
    end

    local sortedTables = {}
    for _, criteria in ipairs(Criteria) do
        table.insert(sortedTables, getItemsSortedByCriterion(items, criteria))
    end

    -- always choose randomly, not ideal
    -- local sortedTableSlotIndex = {}
    -- for _, _ in ipairs(sortedTables) do
    --     table.insert(sortedTableSlotIndex, count)
    -- end
    -- for rankIndex = count, 1, -1 do
    --     local randomIndex = math.random(criteriaCount)
    --     local chosenTable = sortedTables[randomIndex]
    --     local chosenBee = chosenTable[sortedTableSlotIndex[randomIndex]]
    --     table.insert(finalItems, 1, chosenBee)

    --     for sortedTableIndex = 1, criteriaCount do
    --         local slotIndex = sortedTableSlotIndex[sortedTableIndex]
    --         local maybeBee = sortedTables[sortedTableIndex][slotIndex]
    --         if chosenBee.slot == maybeBee.slot then
    --             sortedTableSlotIndex[sortedTableIndex] = sortedTableSlotIndex[sortedTableIndex] - 1
    --         end
    --     end
    -- end

    local finalItems = {}
    local slotSet = {}

    -- Always choose at least 1 from each list
    -- assumes only 2 lists
    local finalCount = count
    while finalCount > 0 do
        local randomIndex = math.random(2)
        local chosenTable = sortedTables[randomIndex]
        local chosenBee = chosenTable[finalCount]
        table.insert(finalItems, 1, chosenBee)
        slotSet[chosenBee.slot] = true

        local otherIndex = randomIndex == 1 and 2 or 1
        local otherBee = sortedTables[otherIndex][finalCount]
        local otherBeeInUse = slotSet[otherBee.slot]
        if not otherBeeInUse then
            table.insert(finalItems, 1, otherBee)
            slotSet[chosenBee.slot] = true
            finalCount = finalCount - 1
        end
        finalCount = finalCount - 1
    end

    return finalItems
end

function GetBreedSlot(sortedItems, count)
    return sortedItems[count]["slot"]
end

function GetTrashSlots(sortedItems, count)
    local trash = {}
    local trashLimit = count - MAX_SPACE
    if trashLimit <= 0 then return trash end

    for i = 1, trashLimit do
        table.insert(trash, sortedItems[i]["slot"])
    end
    return trash
end
