--[[
    Filename: MiningProgram.lua
    Author: Adi Banerjee
    Description: This program enables automatic mining in Minecraft through the CC:Tweaked mod for v1.12.2
                 To use it, run the program on a Mining Turtle's prompt as "MiningProgram <X> <Y> <Z>" and replace X, Y and Z with
                 how big of an area you want it to mine. <Z> is used to tell the turtle how deep to mine.

                 Some other useful features:
                  - The turtle will automatically come back up once it is done
                  - It throws out junk like cobblestone, stone (diorite, andesite and granite) and dirt automatically so they dont waste space
                  - If it runs into bedrock it will automatically come back up
                  - It refuels on its own and the fuel can be placed into any slot in the turtle. The turtle needs 12 fuel to start (coal/charcoal)
]]


-- Stuff we want to throw away while mining
junk_table = {
    ["minecraft:cobblestone"] = true,
    ["minecraft:dirt"] = true,
    ["minecraft:stone"] = true,
}

--[[
    This function loops through all the slots of the turtle and removes the stuff we 
    don't want to keep while mining. It uses the junk_table for reference
]]
function clear_junk()
    for i=1,16,1 do            
        turtle.select(i)
        local data = turtle.getItemDetail()

        -- Check data because it can be nil
        if data and junk_table[data.name] then
            turtle.dropUp()
        end
    end
end

--[[
    Moves the turtle up by the indicates z value. 
]]
function return_to_top(z)
    for i=1,z,1 do
        turtle.up()
    end
end

--[[]
    Digs down before moving down. If there's nothing to dig, it'll just move down
]]
function mine_and_down()
    turtle.digDown()
    turtle.down()
end

--[[]
    Digs forward before moving forward. If there's nothing to dig, it'll just move forward
]]
function mine_and_forward()
    turtle.dig()
    turtle.forward()
end

--[[
    Loops through all the slots of the turtle to find fuel and refuel by the amount specified
    To make sure there's not too much of a performance hit, it will only refuel if the current amount
    is below 240
]]
function auto_fuel(amt)    
    cur_fuel = turtle.getFuelLevel()
    
    if cur_fuel < 240 then
        for i=1,16,1 do            
            turtle.select(i)
            if turtle.refuel(0) then
                turtle.refuel(amt)
                break
            end
        end
    end
end


--[[
    When there are an even number of X, then this function returns the turtle back to the starting X,Y value. Since
    it should already be at the right Y value, we only move it's X. 

    If, however, the X specified is odd, it will just turn around to fave the right position and pretend it started from
    the opposite corner of the rectangle. The symmetry helps reduce unnecessary work when dealing with odd sizes
]]
function back_to_plane_start(x)
    turtle.turnRight()
    for i=2,x,1 do
        turtle.forward()
    end   
    turtle.turnRight()
end

--[[
    Digs a plane of size X, Y. This function auto refuels internally, but DOES NOT clear junk
]]
function dig_plane(x,y)
    
    -- We'll use a variable alt to know which way to turn
    local alt = 0  
    for i=1,x,1 do  
        
        auto_fuel(12)
        for j=2,y,1 do
            mine_and_forward()
            auto_fuel(12)
        end
        
        -- If i==x we don't have to turn to avoid breaking an extra block on the X line
        if i ~= x then
            if alt == 0 then
                turtle.turnRight()
                mine_and_forward()
                turtle.turnRight()
                alt = 1
            else
                turtle.turnLeft()
                mine_and_forward()
                turtle.turnLeft()      
                alt = 0
            end
        end
    end  
end

--[[
    Directive function that calls all the other necessary functions to run the program
]]
function main()

    x = tonumber(arg[1])
    y = tonumber(arg[2])
    z = tonumber(arg[3])

    
    for i=1,z,1 do
        dig_plane(x,y)
        clear_junk()     
        auto_fuel(12)

        back_to_plane_start(x)

        local success, data = turtle.inspectDown()    
        if data.name == "minecraft:bedrock" then -- Handle a case where we hit bedrock and can't go down
            z = i-1 -- We do this so the turtle only goes back up as far as it came down
            break
        else
            mine_and_down()
        end
    end  
    
    return_to_top(z)
    clear_junk()
end

main()
