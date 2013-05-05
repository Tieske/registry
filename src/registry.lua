local registry = {}
local lua51 = rawget(_G,'setfenv')

--- execute a shell command.
-- This is a compatibility function that returns the same for Lua 5.1 and Lua 5.2
-- @param cmd a shell command
-- @return true if successful
-- @return actual return code
local function execute (cmd)
    local res1,res2,res2 = os.execute(cmd)
    if lua51 then
        return res1==0,res1
    else
        return res1,res2
    end
end

--- execute a shell command and return the output.
-- This function redirects the output to tempfiles and returns the content of those files.
-- @param cmd a shell command
-- @return true if successful
-- @return actual return code
-- @return stdout output (string)
-- @return errout output (string)
local function executeex(cmd)
  local outfile = os.tmpname()
  local errfile = os.tmpname()
	os.remove(outfile)
	os.remove(errfile)
  
  outfile = os.getenv('TEMP')..outfile
  errfile = os.getenv('TEMP')..errfile
  cmd = cmd .. [[ >"]]..outfile..[[" 2>"]]..errfile..[["]]
  
	local success, retcode = execute(cmd)

  local outcontent, errcontent, fh
  
  fh = io.open(outfile)
  if fh then
    outcontent = fh:read("*a")
    fh:close()
  end
  os.remove(outfile)
  
  fh = io.open(errfile)
  if fh then
    errcontent = fh:read("*a")
    fh:close()
  end
  os.remove(errfile)

  return success, retcode, (outcontent or ""), (errcontent or "")
end

-- Splits a string using a pattern
local split = function(str, pat)
  local t = {}
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(t,cap)
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end

local function parsequery(output)
  local lines = split(output, "\n")
  local i = 1
  local result = { values = {}, keys = {} }
  while i <= #lines do
    if lines[i] ~= "" then
      if result.key then 
        -- key already set, so this is content
        if lines[i]:find(result.key,1,true) == 1 then
          -- the line starts with the same sequnce as our key, so it is a sub-key
          table.insert(result.keys, lines[i])
          result.keys[lines[i]] = #result.keys
        else
          -- not a sub key, so it is a value
          local n, t, v = lines[i]:match("^%s%s%s%s(.+)%s%s%s%s(REG_.+)%s%(%d%d?%)%s%s%s%s(.*)$")
if not n then print("fialed: '"..lines[i].."'"          ) end
          result.values[n] = { ["type"] = t, value = v, name = n}
          table.insert(result.values, result.values[n])
        end
      else
        -- key not set, so this is the key
        result.key = lines[i]
      end
    end    
    i = i + 1
  end
  if result.key then
    return result
  else
    return nil
  end
end

--- returns all values of a key.
-- @param key full key eg. "HKLM\SOFTWARE\xPL"
function registry.getvalues(key)
  assert(type(key)=="string", "Expected string, got "..type(key))
  local ok, ec, out, err = executeex([[reg.exe query "]]..key..[[" /z]])
  if not ok then 
    return nil, err
  else
    return parsequery(out)
  end
end

local o = registry.getvalues([[hkcr\..test]],"dword32")
print("key = ", o.key)
for k,v in ipairs(o.values) do
  print("name       :", v.name)
  print("    type   :", v.type)
  print("    value  :", v.value)
end
print("sub keys:")
for k,v in ipairs(o.keys) do
  print("    "..k.." :", v)
end

return registry