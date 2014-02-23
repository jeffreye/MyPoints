function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

    -- This function copies values from one table into another:
function DeepCopy(src, dst)
    -- If no source (defaults) is specified, return an empty table:
    if type(src) ~= "table" then
        dst = src
        return dst
    end
    -- If no target (saved variable) is specified, create a new table:
    if type(dst) then dst = {} end
    -- Loop through the source (defaults):
    for k, v in pairs(src) do
        -- If the value is a sub-table:
        if type(v) == "table" then
            -- Recursively call the function:
            dst[k] = DeepCopy(v, dst[k])
        -- Or if the default value type doesn't match the existing value type:
        elseif type(v) ~= type(dst[k]) then
            -- Overwrite the existing value with the default one:
            dst[k] = v
        end
    end
    -- Return the destination table:
    return dst
end

function StartsWith( str , other )
    local s,e = strfind(str,other)
    return s == 1
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function GetUnitNameWithoutServer( name )
    local s = strfind(name,"-")
    if not s then 
        return name
    end

    local unit = strsub(name,1,s-1)
    return unit
end