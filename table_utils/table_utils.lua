do
    --[[
    by ChillCode
    edits by isaiahshiner
    http://lua-users.org/wiki/SaveTableToFile
	Save Table to File
	Load Table from File
	v 1.0
	
	Lua 5.2 compatible
	
	Only Saves Tables, Numbers and Strings (edit: and booleans)
	Insides Table References are saved
	Does not save Userdata, Metatables, Functions and indices of these
	----------------------------------------------------
	table.save( table , filename )
	
	on failure: returns an error msg
	
	----------------------------------------------------
	table.load( filename or stringtable )
	
	Loads a table that has been saved via the table.save function
	
	on success: returns a previously saved table
	on failure: returns as second argument an error msg
	----------------------------------------------------
	
	Licensed under the same terms as Lua itself.
    ]] --

    --// export_string( string )
    --// returns a "Lua" portable version of the string
    local function export_string(s)
        return string.format("%q", s)
    end

    --// The Save Function
    function table.save(tbl, filename)
        local charS, charE = "   ", "\n"
        local file, err = io.open(filename, "wb")
        if err then return err end
        if not file then return "unknown err" end

        -- initiate variables for save procedure
        local tables, lookup = { tbl }, { [tbl] = 1 }
        file:write("return {" .. charE)

        for idx, t in ipairs(tables) do
            file:write("-- Table: {" .. idx .. "}" .. charE)
            file:write("{" .. charE)
            local thandled = {}

            for i, v in ipairs(t) do
                thandled[i] = true
                local stype = type(v)
                -- only handle value
                if stype == "table" then
                    if not lookup[v] then
                        table.insert(tables, v)
                        lookup[v] = #tables
                    end
                    file:write(charS .. "{" .. lookup[v] .. "}," .. charE)
                elseif stype == "string" then
                    file:write(charS .. export_string(v) .. "," .. charE)
                elseif stype == "number" or stype == "boolean" then
                    file:write(charS .. tostring(v) .. "," .. charE)
                end
            end

            for i, v in pairs(t) do
                -- escape handled values
                if (not thandled[i]) then
                    local str = ""
                    local stype = type(i)
                    -- handle index
                    if stype == "table" then
                        if not lookup[i] then
                            table.insert(tables, i)
                            lookup[i] = #tables
                        end
                        str = charS .. "[{" .. lookup[i] .. "}]="
                    elseif stype == "string" then
                        str = charS .. "[" .. export_string(i) .. "]="
                    elseif stype == "number" or stype == "boolean" then
                        str = charS .. "[" .. tostring(i) .. "]="
                    end

                    if str ~= "" then
                        stype = type(v)
                        -- handle value
                        if stype == "table" then
                            if not lookup[v] then
                                table.insert(tables, v)
                                lookup[v] = #tables
                            end
                            file:write(str .. "{" .. lookup[v] .. "}," .. charE)
                        elseif stype == "string" then
                            file:write(str .. export_string(v) .. "," .. charE)
                        elseif stype == "number" or stype == "boolean" then
                            file:write(str .. tostring(v) .. "," .. charE)
                        end
                    end
                end
            end
            file:write("}," .. charE)
        end
        file:write("}")
        file:close()
    end

    --// The Load Function
    function table.load(sfile)
        local ftables, err = loadfile(sfile)
        if err then return _, err end
        local tables = ftables()
        for idx = 1, #tables do
            local tolinki = {}
            for i, v in pairs(tables[idx]) do
                if type(v) == "table" then
                    tables[idx][i] = tables[v[1]]
                end
                if type(i) == "table" and tables[i[1]] then
                    table.insert(tolinki, { i, tables[i[1]] })
                end
            end
            -- link indices
            for _, v in ipairs(tolinki) do
                tables[idx][v[2]], tables[idx][v[1]] = tables[idx][v[1]], nil
            end
        end
        return tables[1]
    end

    function table.print(t, tab, lookup)
        local lookup = lookup or { [t] = 1 }
        local tab = tab or ""
        for i, v in pairs(t) do
            print(tab .. tostring(i), v)
            if type(i) == "table" and not lookup[i] then
                lookup[i] = 1
                print(tab .. "Table: i")
                table.print(i, tab .. "\t", lookup)
            end
            if type(v) == "table" and not lookup[v] then
                lookup[v] = 1
                print(tab .. "Table: v")
                table.print(v, tab .. "\t", lookup)
            end
        end
    end

    function table.length(t)
        local count = 0
        for _ in pairs(t) do
            count = count + 1
        end
        return count
    end

    function table.shallow_copy(t)
        local t2 = {}
        for k, v in pairs(t) do
            t2[k] = v
        end
        return t2
    end

    -- https://gist.github.com/sapphyrus/fd9aeb871e3ce966cc4b0b969f62f539?permalink_comment_id=4563041#gistcomment-4563041
    function table.isEqual(o1, o2)
        -- same object
        if o1 == o2 then return true end

        local o1Type = type(o1)
        local o2Type = type(o2)
        --- different type
        if o1Type ~= o2Type then return false end
        --- same type but not table, already compared above
        if o1Type ~= 'table' then return false end

        -- iterate over o1
        for key1, value1 in pairs(o1) do
            local value2 = o2[key1]
            if value2 == nil or table.isEqual(value1, value2) == false then
                return false
            end
        end

        --- check keys in o2 but missing from o1
        for key2, _ in pairs(o2) do
            if o1[key2] == nil then return false end
        end
        return true
    end
end
