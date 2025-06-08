-- Interface with the the 3 inventories:
-- 1. Main chest (top/above the computer)
--  * Diamond chest, 108 slots, limited to 72 slots
-- 2. Breeding dropper (east or west of main chest)
--  * Vanilla dropper, 9 slots, only 1 item should be in here at a time
--  * Could do north/south, I just didn't need it.
-- 3. "Trash" chest (above the main chest)
--  * Ender chest, 27 slots, but items are piped out, so basically infinite.

-- A single bee (drone) is moved to the dropper when the program starts, and
-- each time a redstone signal is received.
-- Trash is checked/moved for once every second.
-- I don't think there's a way to detect inventory changes.

require("bee_sort.sort")
require('table_utils.table_utils')

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
function Startup()
    startRandom()
    GenerateComparators()
    Top = peripheral.wrap("top");
    findDirection()

    --There might be an item already in the dropper,
    -- we should remove it, add it back later.
    Top.pullItem(Direction, 1)
end

local function getStacks()
    local stacks = {}
    local count = 0
    -- `getAllStacks` returns a table of item objects
    -- `all` gets all the details of an item stack
    for slot, item in pairs(Top.getAllStacks()) do
        stacks[slot] = item.all()
        count = count + 1
    end
    return stacks, count
end

local function moveBreed(slot)
    -- Push an item from the main chest
    -- to the breeding dropper (direction)
    -- from chosen slot, and only move 1 item.
    -- Always uses first available slot in target
    Top.pushItem(Direction, slot, 1)
end

local function moveTrash(slots)
    for i, slot in ipairs(slots) do
        Top.pushItem("up", slot)
    end
end

function DoBreedCycle()
    local stacks, count = getStacks()
    local sortedItems = GetSortedItems(stacks, count)

    local slot = GetBreedSlot(sortedItems, count)
    moveBreed(slot)
end

LastCount = 0

function DoTrashCycle()
    local stacks, count = getStacks()
    if LastCount == count then
        return
    else
        LastCount = count
    end
    local sortedItems = GetSortedItems(stacks, count)
    local slots = GetTrashSlots(sortedItems, count)
    moveTrash(slots)
end

function MainLoop()
    local function breedLoop()
        DoBreedCycle()
        while true do
            -- When the dropper is powered, this computer also gets powered.
            -- We should add another drone when that happens.
            os.pullEvent("redstone")
            -- the redstone event triggers whenever redstone *changes*,
            -- so we also get the off signal. We wait a bit to ignore that.
            sleep(0.5)
            DoBreedCycle()
        end
    end
    local function trashLoop()
        while true do
            DoTrashCycle()
            -- don't kill PC. I haven't carefully benchmarked this, but
            -- it doesn't seem to be remotely laggy and trashes items very fast.
            sleep(1)
        end
    end
    -- parallel is a ComputerCraft API that
    -- runs multiple functions at the same time.
    parallel.waitForAll(breedLoop, trashLoop)
end
