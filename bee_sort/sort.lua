-- Sort a list of bees based on multiple criteria.
-- That is, we actually want a bee that has both fast speed and short lifespan
-- (short because you can mutate faster)
-- But if we only have some fast bees with long lifespans,
-- and some slow bees with short lifespans,
-- we need to need to at least *sometimes* pick the fast bee,
-- and sometimes pick the short lifespan bee.

-- So, we sort the bees by each criteria separately,
-- then we pick from each sorted list in random/round-robin fashion.
-- We're just relying on built-in `table.sort`, but providing a custom comparator.
-- But the comparator is complicated, because each one has to check every criteria.
-- Each criteria starts as just a comparator and a selector,
-- and the final comparators are generated from those.

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

local function compareEffect(a, b)
    -- There are some good and bad effects,
    -- I'll probably edit this manually as I find out which are which.
    local badEffects = {
        ["Lightning"] = true,
    }
    local aBad = badEffects[a] or false
    local bBad = badEffects[b] or false
    if aBad == bBad then
        return false, false
    else
        return true, aBad
    end
end

local function compareFlower(a, b)
    -- I think I can safely assume 'Flowers' are always the best?
    local aIsFlowers = a == "Flowers"
    local bIsFlowers = b == "Flowers"
    if aIsFlowers == bIsFlowers then
        return false, false
    else
        return true, bIsFlowers
    end
end

local function compareTrait(a, b)
    -- a and b are bools, saying whether
    -- the bees are completely purebred,
    -- even for traits we don't care about,
    -- meaning their produced drones will always stack.
    if a == b then
        return false, false
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
    },
    {
        comparator = compareEffect,
        selector = GetEffect
    },
    {
        comparator = compareFlower,
        selector = GetFlower
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

-- Forestry has Mendelian genetics, so we check both the
-- dominant (active) and recessive (inactive) alleles.
local generateCriteriaComparator = function(criteria)
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
    -- For each criteria, we need a comparator that starts with a comparator
    --- for that criteria, followed by comparators for all other criteria.
    -- The order of the other criteria doesn't really matter (TODO?),
    -- so we can just rotate through them.
    -- Meaning if we have criteria A, B, C,
    -- we generate comparators for:
    -- A, B, C
    -- B, C, A
    -- C, A, B

    -- Also note that each comparator starts by comparing "rank",
    -- which sorts by simple stuff that we don't need multiple criteria for.
    -- Then, at the end, we compare whether the bee is fully purebred,
    -- which only matters if the bee is already basically perfect.

    local criteriaCount = #CriteriaList
    for i, criteria in ipairs(CriteriaList) do
        local comparatorList = {}
        table.insert(comparatorList, generateBasicComparator(compareRank, GetRank))
        for j = 0, criteriaCount - 1 do
            local index = ((i - 1 + j) % criteriaCount) + 1
            table.insert(comparatorList, generateCriteriaComparator(CriteriaList[index]))
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

    -- Outer loop goes over each index of all the items in reverse order.
    -- The best items are at the end of each list (for some reason?),
    -- so we choose from the end, and always insert at the start of the final list.
    for i = count, 1, -1 do
        local availableIndexes = {}
        for i = 1, criteriaCount do
            table.insert(availableIndexes, i)
        end

        -- Inner loop goes over each sorted list, randomly choosing one.
        -- We always check all the lists at each index, so none get randomly preferred.
        -- Consider sortedTables:
        --      [A, B, C] and [C, A, B],
        -- The first item will always be random between A or C,
        -- and the second place will always be the other one.
        -- B will always be last.
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
