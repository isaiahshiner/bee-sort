require('table_utils.table_utils')

local function test()
    local TEST_FILE_PATH = "test_table.lua"
    print("Serialise Test ...")

    local t = {}
    t.a = 1
    t.b = 2
    t.c = {}
    -- self reference
    t.c.a = t
    t.inass = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
    t.inasst = { { 1 }, { 2 }, { 3 }, { 4 }, { 5 }, { 6 }, { 7 }, { 8 }, { 9 }, { 10 } }
    -- random
    t.f = { [{ a = 5, b = 7, }] = "hello", [{ 1, 2, 3, m = 5, 5, 6, 7 }] = "A Table", }

    t.func = function(x, y)
        print("Hello\nWorld")
        local sum = x + y
        return sum
    end

    -- get test string, not string.char(26)
    local str = ""
    for i = 0, 255 do
        str = str .. string.char(i)
    end
    t.lstri = { [str] = 1 }
    t.lstrv = str

    local function test() print("Hello") end

    t[test] = 1


    print("\n## BEFORE SAVE ##")

    table.print(t)

    --// test save to file
    assert(table.save(t, TEST_FILE_PATH) == nil)

    -- load table from file
    local t2, err = table.load(TEST_FILE_PATH)

    assert(err == nil)


    print("\n## AFTER SAVE ##")

    print("\n## LOAD FROM FILE ##")

    table.print(t2)

    print("\n//Test References")

    assert(t2.c.a == t2)

    print("\n//Test Long string")

    assert(t.lstrv == t2.lstrv)

    print("\n//Test Function\n\n")

    assert(t2.func == nil)

    print("\n*** Test SUCCESSFUL ***")

    assert(os.remove(TEST_FILE_PATH))
end

test()
