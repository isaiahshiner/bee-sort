dofile("table_utils.lua")

local function dump()
    local top = peripheral.wrap("top");
    local slots = {}
    for k, v in pairs(top.getAllStacks()) do
        slots[k] = v.all()
    end
    return slots
end

local t = dump();
local err = table.save(t, "dump_table.lua")
print(err)
