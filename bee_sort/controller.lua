-- Sort forestry drones
require("bee_sort.sort")
require('table_utils.table_utils')

STATIC_RES_FILEPATH = "example_tables/bees_e2e.lua"
MAX_SPACE = 72

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

local function startRandom()
    -- Make sure the random start is
    -- actually different, even if program is
    -- run in quick succession.
    local t = os.time()
    local m = os.clock() * 6000000
    local p = t + m
    math.randomseed(p)
    local s = 0
    for _ = 1, 3 do
        s = s + math.random()
    end
end

Top = nil -- OpenPeripheral chest object on "top" of this computer
StaticExampleStacks = {}
StaticExampleStacksCount = 0
local function startup(filePath)
    startRandom()
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
        StaticExampleStacks = table.load(filePath)
        StaticExampleStacksCount = table.length(StaticExampleStacks)
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
        return StaticExampleStacks, StaticExampleStacksCount
    end
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
    local trashLimit = count - MAX_SPACE
    if trashLimit <= 0 then return trash end

    for i = 1, trashLimit do
        table.insert(trash, sortedItems[i]["slot"])
    end
    return trash
end

local function moveTrash(slots)
    if not Top then
        local out = "trash slots:"
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
    local stacks, count = getStacksAgnostic()
    local sortedItems = GetSortedItems(stacks, count)

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
    local sortedItems = GetSortedItems(stacks, count)
    local slots = getTrashSlots(sortedItems, count)
    moveTrash(slots)
end

startup(STATIC_RES_FILEPATH)

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
