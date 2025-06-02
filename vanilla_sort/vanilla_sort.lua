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
        for slot, item in pairs(Top.getAllStacks()) do
            stacks[slot] = item.all()
        end
        return stacks
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

local function getBreedSlot(stacks)
    local bestSlot = -1
    local bestValue = -1
    for slot, item in pairs(stacks) do
        local value = ValueChart[item.name]
        if value and value > bestValue then
            bestSlot = slot
            bestValue = value
        end
    end
    return bestSlot
end

local function moveBreed(slot)
    if not Top then
        print(slot)
        return
    end

    --There's no way to know if there's already an
    --item in the dropper, so we'll just empty it
    Top.pullItem(Direction, 1)

    -- Push an item from the main chest
    -- to the breeding dropper (direction)
    -- from chosen slot, and only move 1 item.
    -- Always uses first available slot
    Top.pushItem(Direction, slot, 1)
end

local function doTasks()
    local stacks = getStacksAgnostic()

    local slot = getBreedSlot(stacks)
    moveBreed(slot)
end

startup("vanilla_sort/vanilla_res.lua")

if Top then
    doTasks()
    while true do
        os.pullEvent("redstone")
        sleep(0.5) --ignore double pulse
        doTasks()
    end
else
    doTasks()
end
