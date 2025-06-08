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
    if a == -1 and b == -1 then
        -- -1 means not a bee, pretend they're different so it short circuits
        return true, false
    end
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

CriteriaList = {
    {
        comparator = compareSpeed,
        selector = GetSpeed
    },
    {
        comparator = compareLifeSpan,
        selector = GetLifespan
    }
}

local generateBasicComparator = function(comparator, selector)
    local function innerCompare(a, b)
        local valDiff, valCmp =
            comparator(selector(a), selector(b))
        if valDiff then return valDiff, valCmp end
        return false, false
    end

    return innerCompare
end

local generateSingleCriteriaComparator = function(criteria)
    local comparator = criteria.comparator
    local selector = criteria.selector

    local function innerCompare(a, b)
        local critActDiff, critActCmp =
            comparator(selector(a, true), selector(b, true))
        if critActDiff then return critActDiff, critActCmp end

        local critInDiff, critInCmp =
            comparator(selector(a, false), selector(b, false))
        if critInDiff then return critInDiff, critInCmp end

        return false, false
    end

    return innerCompare
end

ComparatorList = {}
GenerateComparators = function()
    -- For each criteria, we need a comparator that starts with a comparator for that criteria,
    -- followed by comparators for all other criteria.
    -- There should be 1 final comparator for each criteria.
    -- The order that criteria are applied should just cycle,
    -- So, if we have criteria A, B, and C,
    -- The first comparator should be:
    -- checkRank, then A, B, C, then trait equal
    -- then the second comparator should be:
    -- checkRank, then B, C, A, then trait equal

    local criteriaCount = #CriteriaList
    for i, criteria in ipairs(CriteriaList) do
        local comparatorList = {}
        table.insert(comparatorList, generateBasicComparator(compareRank, GetRank))
        for j = 0, criteriaCount - 1 do
            local index = ((i - 1 + j) % criteriaCount) + 1
            table.insert(comparatorList, generateSingleCriteriaComparator(CriteriaList[index]))
        end
        table.insert(comparatorList, generateBasicComparator(compareTrait, IsFullyPure))

        local function finalComparator(a, b)
            for _, comparator in ipairs(comparatorList) do
                local resDiff, resCmp = comparator(a, b)
                if resDiff then return resCmp end
            end
            return false
        end
        table.insert(ComparatorList, finalComparator)
    end
end

function GetSimpleRank(bee)
    if not IsBee(bee) then return -1 end
    if not IsPure(bee, GetName) then return 0 end
    -- As long as its a purebred bee,
    -- we have to do multiple criteria sort.
    return 1
end

local function getItemsSortedByCriterion(items, comparator)
    local sortedItems = table.shallow_copy(items)
    table.sort(sortedItems, comparator)
    return sortedItems
end

function GetItemObjsFromStacks(stacks)
    local items = {}
    for slot, item in pairs(stacks) do
        local slotObj = {
            ["slot"] = slot,
            ["bee"] = item
        }
        local rank = GetSimpleRank(slotObj)
        slotObj["rank"] = rank

        table.insert(items, slotObj)
    end
    return items
end

local function getSortedTablesFromItems(items)
    local sortedTables = {}
    for _, comparator in ipairs(ComparatorList) do
        table.insert(sortedTables, getItemsSortedByCriterion(items, comparator))
    end
    return sortedTables
end

local function popRandomFromArray(array)
    local size = table.length(array)
    local index = math.random(size)
    local value = array[index]
    table.remove(array, index)
    return value
end

local function getFinalSortedItems(sortedTables, count)
    local finalItems = {}
    local slotSet = {}
    local criteriaCount = table.length(sortedTables)
    for i = count, 1, -1 do
        local availableIndexes = {}
        for i = 1, criteriaCount do
            table.insert(availableIndexes, i)
        end
        for j = 1, criteriaCount do
            local randomIndex = popRandomFromArray(availableIndexes)
            local chosenBee = sortedTables[randomIndex][i]
            if not slotSet[chosenBee.slot] then
                table.insert(finalItems, 1, chosenBee)
                slotSet[chosenBee.slot] = true
            end
        end
    end

    return finalItems
end

function GetSortedItems(stacks, count)
    local items = GetItemObjsFromStacks(stacks)
    local sortedTables = getSortedTablesFromItems(items)
    local finalItems = getFinalSortedItems(sortedTables, count)
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
