require("bee_sort.selectors")

local function compareItems(a, b)
    return a["rank"] < b["rank"]
    -- if not a["rank"] == b["rank"] then

    -- end
    -- return true
end

local function getSimpleRank(bee)
    if not IsBee(bee) then return -1 end
    if not IsPure(bee, GetName) then return 0 end
    -- Either as long as its a purebred bee,
    -- we have to do multiple criteria sort.
    return 1
end

function GetSortedItems(stacks)
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
    table.sort(items, compareItems)
    return items
end
