local lu = require('luaunit')

local function load_everything()
    local lines = io.popen([[find . -name "*.test.lua"]]):lines()
    for testPath in lines do
        dofile(testPath)
    end
end

load_everything()

os.exit(lu.LuaUnit.run())
