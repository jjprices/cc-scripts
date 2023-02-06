-----------------------------------
--                               --
--           automine            --
--             v1.0              --
-----------------------------------
-- Authors: jjprices, ep9630 --
-----------------------------------
--
-- What is this?
--   Lua program for Minecraft with ComputerCraft mod (and CC Tweaked).  This works only with mining turtles!
--
-- How do I get it?
--   Easy!  Just enter the following command into your mining turtle:
--     wget https://github.com/jjprices/cc-scripts/raw/master/src/automine.lua
--
-- parameters (note: the long or short version can be used)
--      --distance | -d <integer>
--          Specifies the number of blocks from it's starting position the turtle should mine forward
--      --placeTorches | -t
--          Tells the turtle to place torches as it mines.  You have to put the torches in the fist
--          slot of the turtle.  It will place it on the right every 15 blocks, starting on the 5th block
--      --mineAbove | -ma
--          Turtle will mine the block above it as well as in front of it resulting in a 2 block high tunnel.
--      --mineBack | -mb
--          Once the turtle reaches the distance specified with the -d option, it will mine 3 blocks to the right
--          and mine all the way back to the starting position in a new tunnel 3 blocks over.
--      --checkAround | -ca
--          This is a somewhat experimental feature.  When the turtle is mining, it will look one block above, below,
--          to the left, and to the right of it's current position.  If it identifies the block as something
--          that isn't throw away, it will mine that block.  Note that this severely slows down mining as the
--          turtle has to physically turn left and right to identify the block.
--      --quiet | -q
--          When the --mineback option is not used, normally the turtle will stop once --distance is reached
--          and will prompt the user if it should continue forward more blocks, and if not if it should return home.quiet
--          with the --quiet option specified, users is not prompted and it just will return straight home.
--
--
-- Example: automine -d 150 -t -ma -mb
--
-- Notes:
--   * If it stops, just right click on the turtle, it'll tell you why and what to do.
--   * To pause the turtle, place ONE (1) item of your choosing in inventory spot 16 (lower right)
--   * To stop the turtle, place TWO (2) or more items in inventory spot 16 (still the lower right)

local tArgs = { ... }

local function appendArray(sourceArray, destinationArray)
    for key, value in ipairs(sourceArray) do
        destinationArray[key] = value
    end
end

local lightDistance = 15
local totalSpaces = 0
local lightSpaces = 10
local bridgeBlocks = { "dirt", "cobblestone", "tuff", "deepslate", "diorite", "andesite", "granite", ":stone" }
local throwAwayBlocks = { "sand", "gravel" }  -- Note, bridgeBlocks get added to throwAwayBlocks
appendArray(bridgeBlocks, throwAwayBlocks)
local quietMode = false
local mineAbove = false
local checkAround = false
local placeTorches = false
local mineBack = false
local headingBack = false

local function exitProgram(message)
    message = message or ""
    if string.len(message) > 0 then
        print(message)
    end
    error()
end

local function stringHasArrayMatch(value, array)
    for _, arrayValue in ipairs(array) do
        if string.find(value, arrayValue) then
            return true
        end
    end
    return false
end

local function isThrowAwayBlock(blockInfo)
    return stringHasArrayMatch(blockInfo.name, throwAwayBlocks)
end

local function isBridgeBlock(blockInfo)
    return stringHasArrayMatch(blockInfo.name, bridgeBlocks)
end

local function digUp()
    while turtle.detectUp() do
        turtle.digUp()
        --this sleep is necessary to allow time for sand or gravel to fall from above
        sleep(0.5)
    end
end

local function turnAround()
    turtle.turnLeft()
    turtle.turnLeft()
end

local function throwAway()
    turnAround()
    for i = 1,15 do
        turtle.select(i)
        local blockInfo = turtle.getItemDetail(i)
        if blockInfo and isThrowAwayBlock(blockInfo) then
            turtle.drop()
        else
            for j = 2, i-1 do
                if turtle.getItemCount(j) == 0 then
                    turtle.transferTo(j)
                    break
                else
                    if turtle.compareTo(j) then
                        turtle.transferTo(j)
                        if turtle.getItemCount(i) == 0 then
                            break;
                        end
                    end
                end
            end
        end
    end
    turnAround()
    turtle.select(2)
end

local function digCorridor()
    while turtle.forward() == false do
        turtle.dig()
    end
    if mineAbove then
        digUp()
    else
        if checkAround then
            local exists, blockInfo = turtle.inspectUp()
            if exists and not isThrowAwayBlock(blockInfo) then
                digUp()
            end
        end
    end

    if checkAround then
        exists, blockInfo = turtle.inspectDown()
        if exists and isThrowAwayBlock(blockInfo) == false then
            turtle.digDown()
        end

        turtle.turnLeft()
        exists, blockInfo = turtle.inspect()
        if exists and not isThrowAwayBlock(blockInfo) then
            turtle.dig()
        end

        turnAround()
        exists, blockInfo = turtle.inspect()
        if exists and not isThrowAwayBlock(blockInfo) then
            turtle.dig()
        end

        turtle.turnLeft()
    end

    if turtle.detectDown() == false then
        for i = 2,15 do
            local blockInfo = turtle.getItemDetail(i)
            if blockInfo and isBridgeBlock(blockInfo) then
                turtle.select(i)
                turtle.placeDown()
                turtle.select(2)
                break
            end
        end
    end
end

local function reFuel()
    for i = 2,15 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            if turtle.refuel(1) then
                break
            end
        end
    end
    turtle.select(2)
end

local function checkFuel()
    if turtle.getFuelLevel() < 3 then
        reFuel()
        if turtle.getFuelLevel() < 3 then
            print "Out of fuel, please add fuel to inventory so I can continue..."
            while turtle.getFuelLevel() < 3 do
                sleep(1)
                reFuel()
            end
            print "Ahhh... some fuel.  Let's continue!"
        end
    end
end

local function returnHome()
    local answer
    if quietMode then
        answer = "y"
    else
        repeat
            print("Return to where")
            io.write("I last started (y/n)? ")
            io.flush()
            answer=io.read()
        until answer == "y" or answer == "n"
    end
    if answer == "y" then
        print "Returning home"
        turtle.turnRight()
        turtle.turnRight()
        for i=1, totalSpaces do
            while turtle.forward() == false do
                turtle.dig()
                checkFuel()
            end
        end
    end
end

local function placeLight()
    turtle.select(1)
    turtle.turnRight()
    while turtle.detect() do
        turtle.dig()
    end
    turtle.place()
    turtle.select(2)
    turtle.turnLeft()
    lightSpaces = 0
end

local distanceLimit = 0

--Main execution starts here

local i = 1
while i <= #tArgs do
    local parameterName = string.lower(tArgs[i])
    if parameterName == "--distance" or parameterName == "-d" then
        if #tArgs > i then
            i = i + 1
            distanceLimit = tonumber(tArgs[i])
        else
            exitProgram("no distance value supplied")
        end
    elseif parameterName == "--quiet" or parameterName == "-q" then
        quietMode = true
    elseif parameterName == "--mineabove" or parameterName == "-ma" then
        mineAbove = true
    elseif parameterName == "--checkaround" or parameterName == "-ca" then
        checkAround = true
    elseif parameterName == "--placetorches" or parameterName == "-t" then
        placeTorches = true
    elseif parameterName == "--mineBack" or parameterName == "-mb" then
        mineBack = true
    else
        exitProgram("Unknown parameter: "..parameterName)
    end
    i = i + 1
end

turtle.select(2)
while turtle.getItemCount(16) <= 1 do
    if turtle.getItemCount(15) > 0 then
        print "Attempting to discard unwanted items..."
        throwAway()
        if turtle.getItemCount(14) > 0 then
            print "Inventory full enough..."
            break
        end
    end
    checkFuel()
    digCorridor()
    totalSpaces = totalSpaces + 1
    lightSpaces = lightSpaces + 1
    if lightSpaces >= lightDistance and placeTorches then
        placeLight()
    end
    if turtle.getItemCount(16) == 1 then
        print("1 item placed in slot 16.")
        print("I'll pause until you remove it.")
        while turtle.getItemCount(16) == 1 do
            sleep(1)
        end
        if turtle.getItemCount(16) == 0 then
            print("Ok!  Let's continue!")
        end
    end
    if distanceLimit > 0 and totalSpaces >= distanceLimit then
        print("Reached distance of " .. distanceLimit .. "...")
        if mineBack and not headingBack then
            print("Mining on the way back too :)")
            headingBack = true
            turtle.turnRight()
            for i = 1, 3 do
                digCorridor()
            end
            turtle.turnRight()
            totalSpaces = 0
            lightSpaces = 10
        elseif mineBack then
            break
        else
            if quietMode then
                break
            end
            local answer
            repeat
                print("Should we keep")
                io.write("going forward (y/n)? ")
                io.flush()
                answer = io.read()
            until answer == "y" or answer == "n"
            if answer == "y" then
                io.write("What additional distance? ")
                io.flush()
                local moreDistance
                moreDistance = io.read()
                distanceLimit = distanceLimit + tonumber(moreDistance)
                else
                break
            end
        end
    end
end

if turtle.getItemCount(16) > 0 then
    print "Something is in last slot..."
end

if headingBack then
    turtle.turnRight()
    for i = 1, 3 do
        digCorridor()
    end
else
    returnHome()
end