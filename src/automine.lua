-----------------------------------
--                               --
--           automine            --
--             v1.0              --
-----------------------------------
-- Authors: jjprices, ep9630 --
-----------------------------------
--
-- What is this?
--   Lua program for Minecraft with ComputerCraft mod.  This works only with mining turtles!
--
-- What does it do?
--   It mines a tunnel 1 block wide, 2 high and places an item from inventory spot 1 (top left)
--   15 blocks apart.  This is intended for torches, so place a stack of torches in the turtle's
--   first inventory spot.  Place fuel in any other spot (coal works well, or lava bucket for epic).
--   This isn't the most efficient way to mine, but it's fun and this was a good first exercise
--   in trying out Lua and controlling a turtle.  You follow the turtle and use your
--   pick axe to mine the items you want on the floor, walls, or ceiling of the tunnel that weren't in the
--   direct path of your turtle.  You must stay relatively close to your turtle or it will go outside of
--   loaded chunks and just shut down.
--
-- How do I get it?
--   Easy!  Just enter the following command into your mining turtle:
--     pastebin get HXVWzXDg automine
--
-- Usage: automine <distance>
--                  ^-- Number of blocks to mine forward before stopping
--                      (Optional, mines until inventory full if left blank)
--
-- Example: automine 500 <- Mines for 500 blocks before stopping, but it'll
--                          ask if you want to go more.  It's polite like that.
--
-- Notes:
--   * If it stops, just right click on the turtle, it'll tell you why and what to do.
--   * To pause the turtle, place ONE (1) item of your choosing in inventory spot 16 (lower right)
--   * To stop the turtle, place TWO (2) or more items in inventory spot 16 (still the lower right)

local tArgs = { ... }

local lightDistance = 15
local totalSpaces = 0
local lightSpaces = 10
local throwAwayBlocks = { "dirt", "cobblestone", "sand", "gravel"}
local bridgeBlock = "cobblestone"
local quietMode = false

local function exitProgram(message)
    message = message or ""
    if string.len(message) > 0 then
        print(message)
    end
    error()
end

local function throwAway()
    turtle.turnLeft()
    turtle.turnLeft()
    for i = 1,15 do
        turtle.select(i)
        local blockInfo = turtle.getItemDetail(i)
        if blockInfo then
            local matchFound = false
            for block in throwAwayBlocks do
                if string.find(blockInfo.name, block) then
                    matchFound = true
                    turtle.drop()
                    break
                end
            end
            if matchFound == false then
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
    end
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.select(2)
end

local function digCorridor()
    while turtle.forward() == false do
        turtle.dig()
    end
    while turtle.detectUp() do
        turtle.digUp()
        --this sleep is necessary to allow time for sand or gravel to fall from above
        sleep(0.5)
    end
    if turtle.detectDown() == false then
        for i = 2,15 do
            local blockInfo = turtle.getItemDetail(i)
            if blockInfo then
                if string.find(blockInfo.name, bridgeBlock) then
                    turtle.select(i)
                    turtle.placeDown()
                    turtle.select(2)
                    break
                end
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

for i = 1, #tArgs do
    local parameterName = string.lower(tArgs[i])
    if parameterName == "--distance" then
        if #tArgs > i then
            i = i + 1
            distanceLimit = tonumber(tArgs[i])
        else
            exitProgram("no distance value supplied")
        end
    elseif parameterName == "--quiet" then
        quietMode = true
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
    if lightSpaces >= lightDistance then
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

if turtle.getItemCount(16) > 0 then
    print "Something is in last slot..."
end

returnHome()