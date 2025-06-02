-- Demo func of bee sorting,
-- but with simplier vanilla Items

Direction = nil
local function findDirection()
    local function tryWest()
        -- There should never be anything in slot 9
        -- This will crash if there's no chest,
        -- and return 0 (num items) if there is
        Top.pullItem("west", 9)
    end

    if pcall(tryWest) then
        Direction = "west"
    else
        Direction = "east"
    end
end

Top = nil -- OpenPeripheral chest object on "top" of this computer
StaticExampleStacks = {}
local function startup(filePath)
    -- When run from computerCraft,
    -- shell will exist
    if shell then
        Top = peripheral.wrap("top");
        findDirection()

        --There might be an item already in the dropper,
        -- we should remove it, add it back later.
        Top.pullItem(Direction, 1)
    else
        -- otherwise, we're running in lua terminal,
        -- and should load our example file.
        require('table_utils.table_utils')
        StaticExampleStacks = table.load(filePath)
    end
end

local function getStacksAgnostic()
    if Top then
        local stacks = {}
        local count = 0
        for slot, item in pairs(Top.getAllStacks()) do
            stacks[slot] = item.all()
            count = count + 1
        end
        return stacks, count
    else
        return StaticExampleStacks
    end
end

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

local function compareItems(a, b)
    return a["value"] < b["value"]
end

local function getSortedItems(stacks)
    local items = {}
    local count = 0
    for slot, item in pairs(stacks) do
        local value = ValueChart[item.name]
        --A random item would have `nil`
        if not value then value = -1 end
        local slotMeta = { ["slot"] = slot, ["value"] = value }
        table.insert(items, slotMeta)
        count = count + 1
    end
    table.sort(items, compareItems)
    return items, count
end

local function getBreedSlot(sortedItems, count)
    return sortedItems[count]["slot"]
end

local function moveBreed(slot)
    if not Top then
        print("Breed:", slot)
        return
    end

    -- Push an item from the main chest
    -- to the breeding dropper (direction)
    -- from chosen slot, and only move 1 item.
    -- Always uses first available slot in target
    Top.pushItem(Direction, slot, 1)
end

local function getTrashSlots(sortedItems, count)
    local trash = {}
    local trashLimit = count - 12
    if trashLimit <= 0 then return trash end

    for i = 1, trashLimit do
        table.insert(trash, sortedItems[i]["slot"])
    end
    return trash
end

local function moveTrash(slots)
    if not Top then
        local out = "trash slots: "
        for i, slot in ipairs(slots) do
            out = out .. slot .. ", "
        end
        print(out)
        return
    end
    for i, slot in ipairs(slots) do
        Top.pushItem("up", slot)
    end
end

local function doBreedCycle()
    local stacks = getStacksAgnostic()
    local sortedItems, count = getSortedItems(stacks)

    local slot = getBreedSlot(sortedItems, count)
    moveBreed(slot)
end

LastCount = 0

local function doTrashCycle()
    local stacks, count = getStacksAgnostic()
    if LastCount == count then
        return
    else
        LastCount = count
    end
    local sortedItems, count = getSortedItems(stacks)
    local slots = getTrashSlots(sortedItems, count)
    moveTrash(slots)
end

startup("vanilla_sort/vanilla_res.lua")

if Top then
    local function breedLoop()
        doBreedCycle()
        while true do
            os.pullEvent("redstone")
            sleep(0.5) --ignore double pulse
            doBreedCycle()
        end
    end
    local function trashLoop()
        while true do
            doTrashCycle()
            sleep(1) -- don't kill PC
        end
    end
    parallel.waitForAll(breedLoop, trashLoop)
else
    doBreedCycle()
    doTrashCycle()
end
