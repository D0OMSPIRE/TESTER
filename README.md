## TESTER.luau

TESTER is a testing framework for testing your code, similar to Google's GTest.
https://google.github.io/googletest/

### Usage
Create and run tests using `TESTER.CREATE_TEST()` and `TESTER.RUN_TESTS()`

```lua
local TESTER = require(path.to.TESTER)

TESTER.CREATE_TEST "10 + 3 = 13" (function()
    local RESULT = 10 + 3
    TESTER.VALUE_EQ(RESULT, 13)
end)

TESTER.RUN_TESTS()
```

Implement isolated modules and require them
```lua
local TESTER = require(path.to.TESTER)

local m_IsolatedModuleScript = path.to.IsolatedModuleScript

TESTER.CREATE_TEST "ISOLATED MODULE HAS PROPERTY test = true" (function()
    TESTER.INITIALIZE( m_IsolatedModuleScript )
	TESTER.REQUIRE("IsolatedModuleScript")
	
	TESTER.VALUE_TRUE( IsolatedModuleScript.test ) --> is IsolatedModuleScript.test == true?
end)

TESTER.RUN_TESTS()
```

Why are we initializing a static module, and then calling require?
In TESTER it uses context based function environments to store values inside
the scope of the `CREATE_TEST` function. It stores things like initialize modules,
which allow us to just call the module's name as a global within scope of our test.
We also want to "isolate" our modules from interfering with actual game code,
we are running tests on modules that have not been initialized, then suddenly if a value
changes from outside the test environment, it can break the test.

If your module scripts have dependencies, make sure to initialize them inside `TESTER.INITIALIZE`.
```lua
TESTER.INITIALIZE( m_IsolatedDependency, m_IsolatedModuleScript )
```

Your dependencies may need to go first in order, due to how roblox handles requiring modules.

Final note about these test environments. Run your tests in a separate script, the TESTER module
messes with function environments through `getfenv` which disables script optimizations.
Read more: https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#getfenv

### Use different value checking modes:
```lua
TESTER.VALUE_EQ(INPUT, RESULT)    --> INPUT == RESULT
TESTER.VALUE_ZERO(INPUT)          --> INPUT == 0
TESTER.VALUE_POS(INPUT)           --> INPUT >= 0
TESTER.VALUE_NEG(INPUT)           --> INPUT < 0
TESTER.VALUE_TRUE(INPUT)          --> INPUT == true (not truthy statements, workpace.Part ~= true)
TESTER.VALUE_FALSE(INPUT)         --> INPUT = false (not falsey statements, nil ~= false)
```

### Extra debugging information

Print only failed tests into output
```lua
TESTER.RUN_TESTS( true )
```

### Example use

I am currently programming a 6502 emulator in luau, and I
needed a solid way to test instructions.

```lua
local ServerStorage = game:GetService("ServerStorage")

local Processor = ServerStorage["6502"]
local m_CPU, m_BUS, m_MEM = Processor.CPU, Processor.BUS, Processor.MEM

local TESTER = require("@self/TESTER")

local function CREATE_STX_TESTS()
    TESTER.CREATE_TEST "STX_ZPG MOVE REG-X INTO $0003" (function()
        TESTER.INITIALIZE( m_MEM, m_BUS, m_CPU )
        TESTER.REQUIRE( "CPU" )
        TESTER.REQUIRE( "BUS" )

        CPU.init( nil, nil )

        CPU.REGISTERS.X = 0x1F

        BUS.write(0x0600, 0x86)
        BUS.write(0x0601, 0x03)

        CPU.execute( 3 )

        TESTER.VALUE_EQ( BUS.read(0x0003), 0x1F )
        TESTER.VALUE_ZERO( CPU.CYCLES )
    end)
    
    TESTER.CREATE_TEST "STX_ZPG_Y MOVE REG-X INTO $0003+Y" (function()
        TESTER.INITIALIZE( m_MEM, m_BUS, m_CPU )
        TESTER.REQUIRE( "CPU" )
        TESTER.REQUIRE( "BUS" )

        CPU.init( nil, nil )

        CPU.REGISTERS.Y = 0x10
        CPU.REGISTERS.X = 0x2D

        BUS.write(0x0600, 0x96)
        BUS.write(0x0601, 0x03)

        CPU.execute( 4 )

        TESTER.VALUE_EQ( BUS.read(0x0013), 0x2D )
        TESTER.VALUE_ZERO( CPU.CYCLES )
    end)
    
    TESTER.CREATE_TEST "STX_ABS MOVE REG-X INTO $85AB" (function()
        TESTER.INITIALIZE( m_MEM, m_BUS, m_CPU )
        TESTER.REQUIRE( "CPU" )
        TESTER.REQUIRE( "BUS" )

        CPU.init( nil, nil )

        CPU.REGISTERS.X = 0x41

        BUS.write(0x0600, 0x8E)
        BUS.write(0x0601, 0xAB)
        BUS.write(0x0602, 0x85)

        CPU.execute( 4 )

        TESTER.VALUE_EQ( BUS.read(0x85AB), 0x41 )
        TESTER.VALUE_ZERO( CPU.CYCLES )
    end)
end

CREATE_STX_TESTS()

TESTER.RUN_TESTS( true )
```
