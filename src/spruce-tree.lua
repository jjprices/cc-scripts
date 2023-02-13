print("how many trees do I need to cut down?")
numTrees = io.read()
for x = 1, numTrees, 1
do
    repeat
        sleep(30)
        turtle.dig()
        turtle.forward()
        has_block, data = turtle.inspect()
        turtle.back()
    until data.name == "minecraft:spruce_log"

    turtle.forward()
    turtle.dig()
    turtle.forward()
    n = 0
    repeat
        for x = 1, 4, 1
        do
            turtle.dig()
            turtle.forward()
            turtle.turnLeft()
        end
        turtle.digUp()
        turtle.up()
        n = n + 1
    until not turtle.detectUp()
    for x = 1, n - 1, 1
    do
        turtle.down()
    end

    turtle.select(1)
    for x = 1, 4, 1
    do
        turtle.placeDown()
        turtle.forward()
        turtle.turnLeft()
    end

    turtle.turnLeft()
    turtle.turnLeft()
    turtle.dig()
    turtle.forward()
    turtle.dig()
    turtle.forward()
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.down()
end

