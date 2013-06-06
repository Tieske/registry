local registry = require('registry')

describe("tests the `registry` module", function()

  local testkey = "HKEY_CLASSES_ROOT\\...test"
  assert:set_parameter("TableFormatLevel", -1)  -- display all levels in table comparison
  
  setup(function()
    assert(registry.createkey(testkey))
    assert(registry.createkey(testkey.."\\testkey"))
    assert(registry.writevalue(testkey.."\\testkey", "name", "REG_SZ", "value"))
  end)
  
  teardown(function()
    assert(registry.deletekey(testkey))
  end)
  
  it("tests reading a key, recursive", function()
    local key = registry.getkey(testkey, true)
    assert.are_same({
        key = testkey, 
        keys = { 
          testkey = {
            key = testkey.."\\testkey",
            keys = { 
            },
            values = {
              name = {
                name = 'name',
                value = 'value',
                type = 'REG_SZ',
              },
              ["(Default)"] = {
                name = '(Default)',
                value = '',
                type = 'REG_SZ',
              },
            },
          },
        }, 
        values = {
          ["(Default)"] = {
            name = '(Default)',
            value = '',
            type = 'REG_SZ',
          },
        }
      }, 
      key)
  end)    
  
  it("tests reading a key, plain", function()
  
    local key = registry.getkey(testkey)
    assert.are_same({
        key = testkey, 
        keys = { 
          testkey = {
            key = testkey.."\\testkey",
          },
        }, 
        values = {
          ["(Default)"] = {
            name = '(Default)',
            value = '',
            type = 'REG_SZ',
          },
        }
      }, 
      key)
    
  end)

  it("tests creating a key", function()
    local before = registry.getkey(testkey)
    before.keys["newkey"] = { key = testkey.."\\newkey" }
    assert(registry.createkey(testkey.."\\newkey"))
    local after = registry.getkey(testkey)
    assert.are.same(before, after)
  end)

  it("tests creating a value", function()
    local before = registry.getkey(testkey)
    before.values["newvalue"] = { name = "newvalue", type = "REG_SZ", value = "value" }
    assert(registry.writevalue(testkey, "newvalue", "REG_SZ", "value"))
    local after = registry.getkey(testkey)
    assert.are.same(before, after)
  end)
  
  pending("tests creating a value with special characters", function()
    local val = "x`~!@#$%^&*()_+-=[]{};':"..'"'.."\\"  --"\\|,.<>/?x"
    val = val .. val
    assert(registry.writevalue(testkey, "newvalue", "REG_SZ", val))
    local after = registry.getkey(testkey)
    assert.are.same(val, after.values.newvalue.value)
  end)
  
end)
