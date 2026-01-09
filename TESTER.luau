--------------------------------------------------------
---- TESTER.luau (1/7/2026-Now)                     ----
--------------------------------------------------------
---- ROBLOX @D0omspire                              ----
----      X @doomscripts                            ----
--------------------------------------------------------
---- TESTER is a testing framework for testing      ----
---- certain functions in your code similar to      ----
---- Google's GTest.                                ----
--------------------------------------------------------
---- Run tests in safe locations or isoloated       ----
---- scripts                                        ----
--------------------------------------------------------

local TESTER = { TOTAL = 0 }
local TESTS = {}

local HttpService = game:GetService("HttpService")

if getfenv == nil then
    return warn("ROBLOX has removed getfenv")
end

local function convertArgsToString( TABLE ): { string }
    for index, value in TABLE do
        TABLE[index] = tostring(value)
    end
    
    return TABLE
end

function TESTER.INITIALIZE( ...: ModuleScript )
    local context = getfenv( debug.info(2, 'f') )
    if context.TEST_NAME == nil then
        return warn("CANNOT INITIALIZE WITHOUT TEST CONTEXT")
    end
    
    local modules = {...}
    
    local folder = Instance.new("Folder")
    folder.Name = context.TEST_NAME
    folder.Parent = script
    
    for _, module: ModuleScript in modules do
        if not module:IsA("ModuleScript") then
            return warn("INVALID TESTER.INITIALIZE ARGUMENTS, MODULESCRIPTS ONLY")
        end
        
        local newModule = module:Clone()
        newModule.Parent = folder
    end
end

function TESTER.REQUIRE( module: string )
    local context = getfenv( debug.info(2, 'f') )
    
    local folder = script:FindFirstChild( context.TEST_NAME )
    local module = folder:FindFirstChild(module)
    if not module then
        return warn(`COULD NOT FIND MODULE "{module}"`)
    end
    
    context[module.Name] = require(module)
end

function TESTER.CREATE_TEST( TEST_NAME: string ): ((self:{}) -> ()) -> ()
    local context = getfenv( debug.info(2, 'f') )
    context.TEST_NAME = TEST_NAME
    
    if TESTS[TEST_NAME] ~= nil then
        return warn(`{TEST_NAME} ALREADY EXISTS`)
    end
    
    TESTS[TEST_NAME] = {
        NEED_TO_PASS = 0,
        FUNCTIONS = {},
        
        DESTROY = function()
            local folder = script:FindFirstChild( TEST_NAME )
            if folder then
                folder:Destroy()
            end
            
            folder = nil
        end,
    }
    
    TESTER.TOTAL += 1
    
    return function( TEST_FUNCTION: (self:{}) -> () )
        TEST_FUNCTION()
    end
end

function TESTER.VALUE_EQ( TARGET: any, EXPECTED: any )
    local context = getfenv( debug.info(2, 'f') )
    local testContext = TESTS[context.TEST_NAME]
    
    testContext.NEED_TO_PASS += 1
    
    testContext.FUNCTIONS[`{testContext.NEED_TO_PASS}_VALUE_EQ`] = {{ EXPECTED, TARGET }, function(A, B)
        return B == A
    end, "EXPECTED %s GOT %s"}
end

function TESTER.VALUE_ZERO( TARGET: any )
    local context = getfenv( debug.info(2, 'f') )
    local testContext = TESTS[context.TEST_NAME]

    testContext.NEED_TO_PASS += 1

    testContext.FUNCTIONS[`{testContext.NEED_TO_PASS}_VALUE_ZERO`] = {{ TARGET }, function(A)
        return A == 0
    end, "EXPECTED 0 GOT %d"}
end

function TESTER.VALUE_POS( TARGET: any )
    local context = getfenv( debug.info(2, 'f') )
    local testContext = TESTS[context.TEST_NAME]

    testContext.NEED_TO_PASS += 1

    testContext.FUNCTIONS[`{testContext.NEED_TO_PASS}_VALUE_POS`] = {{ TARGET }, function(A)
        return A >= 0
    end, `EXPECTED POS ({-TARGET}) GOT %s`}
end

function TESTER.VALUE_NEG( TARGET: any )
    local context = getfenv( debug.info(2, 'f') )
    local testContext = TESTS[context.TEST_NAME]

    testContext.NEED_TO_PASS += 1

    testContext.FUNCTIONS[`{testContext.NEED_TO_PASS}_VALUE_NEG`] = {{ TARGET }, function(A)
        return A < 0
    end, `EXPECTED NEG ({-TARGET}) GOT %s`}
end

function TESTER.VALUE_FALSE( TARGET: any )
    local context = getfenv( debug.info(2, 'f') )
    local testContext = TESTS[context.TEST_NAME]

    testContext.NEED_TO_PASS += 1
    
    testContext.FUNCTIONS[`{testContext.NEED_TO_PASS}_VALUE_FALSE`] = {{ TARGET }, function(A)
        return A == false
    end, "EXPECTED FALSE GOT %s"}
end

function TESTER.VALUE_TRUE( TARGET: any )
    local context = getfenv( debug.info(2, 'f') )
    local testContext = TESTS[context.TEST_NAME]

    testContext.NEED_TO_PASS += 1
    
    testContext.FUNCTIONS[`{testContext.NEED_TO_PASS}_VALUE_TRUE`] = {{ TARGET }, function(A)
        return A == true
    end, "EXPECTED TRUE GOT %s"}
end

function TESTER.RUN_TESTS( PRINT_FAILURES_ONLY: boolean? )
    local TOTAL_PASSED = 0
    local TOTAL_FAILED = 0
    local START = os.clock()
    
    for TEST_NAME, TEST_ENVIRONMENT in TESTS do
        local passed = 0
        local failed_indexes = {}
        
        for test_index, test_struct: {} in TEST_ENVIRONMENT.FUNCTIONS do
            local arguments = test_struct[1]
            local wrapper = test_struct[2]
            
            if wrapper( unpack(arguments) ) then
                passed += 1
                continue
            end
            
            local issue = test_struct[3]
            issue = string.format( issue, unpack(convertArgsToString(arguments)) )
            
            failed_indexes[#failed_indexes + 1] = `"{test_index}={issue}"`
        end
        
        table.sort(failed_indexes, function(A, B)
            return A < B
        end)
        
        local PASSED = (passed == TEST_ENVIRONMENT.NEED_TO_PASS)
        TOTAL_PASSED += (PASSED and 1) or 0
        TOTAL_FAILED += (not PASSED and 1) or 0
        
        if PASSED and not PRINT_FAILURES_ONLY then
            print(`PASSED "{TEST_NAME}"`)
        elseif not PASSED then
            warn(`FAILED "{TEST_NAME}" [{table.concat(failed_indexes, ',')}]`)
        end
        
        TEST_ENVIRONMENT.DESTROY()
    end
    
    print(`{TOTAL_PASSED} PASSED, {TOTAL_FAILED} FAILED`)
    print(`EXECUTED IN {("%.5f"):format(os.clock() - START)}s`)
    
    local context = getfenv( debug.info(2, 'f') )
    for key, value in context do
        if key == "_G" then continue end
        if key == "script" then continue end
        if key == "shared" then continue end
        context[key] = nil
    end
end

return TESTER
