-- Random Failure 1.1.1
-- E-mail: pilotjohn at gearsdown.com
--
-- Simulates aircraft failures through standard FSX failure controls,
-- FSUIPC failure offsets, or forced manipulation (e.g. alternator, gear).
-- Failures can be restricted to occur on ground, in air or both.
-- Setup:
--
-- 1. Edit "FSUIPC.ini" and add (substitute X for 1 or next # if exists):
--     [Auto]
--     X=Lua RandomFailure
--
-- 2. In FSUIPC "Buttons + Switches",
--     "PRESS" "BUTTON",
--     check "Select for FS control",
--     choose "LuaToggle RandomFailure",
--     and enter "1" for "Paramater" to display current failures,
--     or enter "2" for "Parameter" to reset all failures.
--
-- 3. Configure below as desired.
 
ipc.log("Starting...")

--------------------------------------------------------------------------------
-- Configuration

-- Display start-up banner for a duration, uncomment to enable
-- ipc.display("Random Failure", 3)

rate = 60000 -- Failure run rate in miliseconds (default is once every 60 seconds)
show = false -- Display the list of failures when something fails
failures = {
    -- Probability, Action, Control/Offset, Mask/Parameter/Value, Reset M/P/V, Type, Force, Location, Description
    --
    -- Probability: Likelyhood of failure in hours
    -- Action: "W" for write, "T" for toggle, "S"/"C" for set/clear
    -- Control/Offset: Control or offset address
    -- Mask/Parameter/Value: Mask or value (nil to keep current) for offset, parameter for control
    -- Reset M/P/V: Mask, value or parameter for reset (nil to do nothing)
    -- Type: Offset size (UB, UW, UD, SB, SW, SD, DD, DBL, FLT)
    -- Force: Watch control/offset and re-fail on change (use nil to keep current)
    -- Location: Both/Air/Ground (-1/0/1)
    -- Description: Text to display for the failure
    --
    -- Engines
    { 300, "T", 66313, nil, nil, nil, false, -1, "Engine 1 completely" },
    { 300, "T", 66314, nil, nil, nil, false, -1, "Engine 2 completely" },
    { 300, "T", 66315, nil, nil, nil, false, -1, "Engine 3 completely" },
    { 300, "T", 66316, nil, nil, nil, false, -1, "Engine 4 completely" },
    { 200, "W", 0x088C, nil, nil, "SW", true, 0, "Engine 1 throttle" }, -- Stuck throttle
    { 200, "W", 0x0924, nil, nil, "SW", true, 0, "Engine 2 throttle" },
    { 200, "W", 0x09BC, nil, nil, "SW", true, 0, "Engine 3 throttle" },
    { 200, "W", 0x0A54, nil, nil, "SW", true, 0, "Engine 4 throttle" },
    { 200, "W", 0x088E, nil, nil, "SW", true, 0, "Engine 1 propeller" }, -- Stuck propeller
    { 200, "W", 0x0926, nil, nil, "SW", true, 0, "Engine 2 propeller" },
    { 200, "W", 0x09BE, nil, nil, "SW", true, 0, "Engine 3 propeller" },
    { 200, "W", 0x0A56, nil, nil, "SW", true, 0, "Engine 4 propeller" },
    { 200, "W", 0x0890, nil, nil, "UW", true, 0, "Engine 1 mixture" }, -- Stuck mixture
    { 200, "W", 0x0928, nil, nil, "UW", true, 0, "Engine 2 mixture" },
    { 200, "W", 0x09C0, nil, nil, "UW", true, 0, "Engine 3 mixture" },
    { 200, "W", 0x0A58, nil, nil, "UW", true, 0, "Engine 4 mixture" },
    { 100, "W", 0x3838, 1, 0, "UB", false, -1, "Engine 1 turbo" },
    { 100, "W", 0x3778, 1, 0, "UB", false, -1, "Engine 2 turbo" },
    { 100, "W", 0x36B8, 1, 0, "UB", false, -1, "Engine 3 turbo" },
    { 100, "W", 0x35F0, 1, 0, "UB", false, -1, "Engine 4 turbo" },
    { 100, "S", 0x32F8, 16, 16, "UB", false, -1, "Engine 1 reverser" }, -- May not work (depends on setup, ThrottleManager works)
    { 100, "S", 0x32F8, 32, 32, "UB", false, -1, "Engine 2 reverser" },
    { 100, "S", 0x32F8, 64, 64, "UB", false, -1, "Engine 3 reverser" },
    { 100, "S", 0x32F8, 128, 128, "UB", false, -1, "Engine 4 reverser" },
    { 300, "S", 0x3366, 1, 1, "UB", false, 0, "Engine 1 on fire" }, -- May not cause engine failure
    { 300, "S", 0x3366, 2, 2, "UB", false, 0, "Engine 2 on fire" },
    { 300, "S", 0x3366, 4, 4, "UB", false, 0, "Engine 3 on fire" },
    { 300, "S", 0x3366, 8, 8, "UB", false, 0, "Engine 4 on fire" },
    --
    -- Systems
    { 100, "T", 66305, nil, nil, nil, false, 0, "Vacuum system" },
    { 100, "W", 0x3101, 0, nil, "UB", true, 0, "Alternator" }, -- Same as Generator 1?
    --{ 100, "W", 0x3B78, 0, nil, "UD", true, 0, "Generator 1" }, -- Mechanical (switch, turns off), either/or
    --{ 100, "W", 0x3AB8, 0, nil, "UD", true, 0, "Generator 2" },
    --{ 100, "W", 0x39F8, 0, nil, "UD", true, 0, "Generator 3" },
    --{ 100, "W", 0x3938, 0, nil, "UD", true, 0, "Generator 4" },
    { 100, "W", 0x3B7C, 0, nil, "UD", true, 0, "Generator 1" }, -- Operational (functionality, not generating)
    { 100, "W", 0x3ABC, 0, nil, "UD", true, 0, "Generator 2" },
    { 100, "W", 0x39FC, 0, nil, "UD", true, 0, "Generator 3" },
    { 100, "W", 0x393C, 0, nil, "UD", true, 0, "Generator 4" },
    { 200, "T", 66306, nil, nil, nil, false, 0, "Electrical system" },
    { 200, "T", 66309, nil, nil, nil, false, 0, "Hydraulic system" },
    { 100, "W", 0x29C, 0, nil, "UB", true, 0, "Pitot heat" },
    { 100, "T", 66307, nil, nil, nil, false, -1, "Pitot system" },
    { 100, "T", 66308, nil, nil, nil, false, -1, "Static system" },
    { 100, "T", 66311, nil, nil, nil, false, -1, "Left brake" },
    { 100, "T", 66312, nil, nil, nil, false, -1, "Right brake" },
    { 200, "T", 66310, nil, nil, nil, false, -1, "All brakes" },
    { 100, "W", 0x0BC4, 8192, nil, "UW", true, 0, "Left brake" }, -- Partially stuck left brake (or blown tire?)
    { 100, "W", 0x0BC6, 8192, nil, "UW", true, 0, "Right brake" }, -- Partially stuck right brake (or blown tire?)
    { 100, "W", 0x0BC8, nil, nil, "UW", true, 0, "Parking brake" },
    { 200, "S", 0x32F8, 4, 4, "UB", false, -1, "Gears" }, -- Gear lever stuck in position (FSUIPC disconnect), pick one
    --{ 200, "W", 0x0BE8, nil, nil, "UD", true, -1, "Gears" }, -- Gear lever stuck in position (force simulated)
    { 100, "W", 0x0BEC, nil, nil, "UD", true, -1, "Nose gear" }, -- Gear stuck in position (including in transit)
    { 100, "W", 0x0BF0, nil, nil, "UD", true, -1, "Right gear" },
    { 100, "W", 0x0BF4, nil, nil, "UD", true, -1, "Left gear" },
    --
    -- Instruments
    { 300, "W", 0x0B65, 1, 0, "UB", false, -1, "Airspeed indicator" },
    { 100, "W", 0x0B67, 1, 0, "UB", false, -1, "Attitude indicator" },
    { 300, "W", 0x0B66, 1, 0, "UB", false, -1, "Altimeter" },
    --{ 100, "W", 0x0B72, 1, 0, "UB", false, -1, "Turn coordinator" }, -- Doesn't work
    { 100, "W", 0x0B6D, 1, 0, "UB", false, -1, "Directional gyro" },
    { 300, "W", 0x0B69, 1, 0, "UB", false, -1, "Magnetic compass" },
    { 200, "W", 0x0B6E, 1, 0, "UB", false, -1, "Vertical speed indicator" },
    --{ 100, "W", 0x0B6C, 1, 0, "UB", false, -1, "Fuel gauges" }, -- Doesn't work
    --{ 100, "W", 0x0B73, 1, 0, "UB", false, -1, "Vacuum gauges" }, -- Doesn't work
    --{ 100, "W", 0x0B6A, 1, 0, "UB", false, -1, "Electrical gauges" }, -- Doesn't work
    --
    -- Avionics
    --{ 100, "W", 0x0B68, 1, 0, "UB", false, -1, "COM radios" }, -- Doesn't work
    --{ 100, "W", 0x0B70, 1, 0, "UB", false, -1, "NAV radios" }, -- Doesn't work
    { 200, "W", 0x034E, nil, nil, "UW", true, -1, "COM1 radio" }, -- Won't tune
    { 300, "W", 0x3118, nil, nil, "UW", true, -1, "COM2 radio" },
    { 100, "W", 0x0350, nil, nil, "UW", true, -1, "NAV1 radio" },
    { 200, "W", 0x0352, nil, nil, "UW", true, -1, "NAV2 radio" },
    { 100, "W", 0x0B64, 1, 0, "UB", false, -1, "ADF radios" },
    { 100, "W", 0x0B6F, 1, 0, "UB", false, -1, "Transponder" },
    --
    -- Surfaces
    { 100, "S", 0x32F8, 1, 1, "UB", false, -1, "Flaps" }, -- Flap lever stuck in position (FSUIPC disconnect), pick one
    --{ 100, "W", 0x0BDC, nil, nil, "UD", true, -1, "Flaps" }, -- Flap lever stuck in position (force simulated)
    { 300, "W", 0x30E0, nil, nil, "UW", true, -1, "Left inboard flap" }, -- Flap stuck in position (asymetric extension)
    { 300, "W", 0x30E2, nil, nil, "UW", true, -1, "Left outboard flap" },
    { 300, "W", 0x30E4, nil, nil, "UW", true, -1, "Right inboard flap" },
    { 300, "W", 0x30E6, nil, nil, "UW", true, -1, "Right outboard flap" },
    { 200, "W", 0x2EA0, nil, nil, "DBL", true, -1, "Elevator trim" },
    { 200, "W", 0x2EB0, nil, nil, "DBL", true, -1, "Aileron trim" },
    { 200, "W", 0x2EC0, nil, nil, "DBL", true, -1, "Rudder trim" },
    { 100, "S", 0x32F8, 2, 2, "UB", false, -1, "Spoilers" },
    { 100, "W", 0x0BD0, nil, nil, "UD", true, -1, "Spoilers" }, -- Spoiler stuck in position
    --{ 300, "W", 0x2EA0, 4096, nil, "DBL", true, -1, "Runaway elevator trim" },
    --{ 300, "W", 0x2EB0, 4096, nil, "DBL", true, -1, "Runaway aileron trim" },
    --{ 300, "W", 0x2EC0, 4096, nil, "DBL", true, -1, "Runaway rudder trim" },
}

failures_co = {}

--------------------------------------------------------------------------------
-- Helpers

function fail_on(act, co, pm, sz)
    if (act == "W") then
        if (pm == nil) then
            if (co <= 65535) then
                if (sz == "UB") then
                    pm = ipc.readUB(co)
                elseif (sz == "UW") then
                    pm = ipc.readUW(co)
                elseif (sz == "UD") then
                    pm = ipc.readUD(co)
                elseif (sz == "SB") then
                    pm = ipc.readSB(co)
                elseif (sz == "SW") then
                    pm = ipc.readSW(co)
                elseif (sz == "SD") then
                    pm = ipc.readSD(co)
                elseif (sz == "DD") then
                    pm = ipc.readDD(co)
                elseif (sz == "DBL") then
                    pm = ipc.readDBL(co)
                elseif (sz == "FLT") then
                    pm = ipc.readFLT(co)
                end
            end
        end
        if (pm == nil) then
            return nil
        end
        if (co <= 65535) then
            if (sz == "UB") then
                ipc.writeUB(co, pm)
            elseif (sz == "UW") then
                ipc.writeUW(co, pm)
            elseif (sz == "UD") then
                ipc.writeUD(co, pm)
            elseif (sz == "SB") then
                ipc.writeSB(co, pm)
            elseif (sz == "SW") then
                ipc.writeSW(co, pm)
            elseif (sz == "SD") then
                ipc.writeSD(co, pm)
            elseif (sz == "DD") then
                ipc.writeDD(co, pm)
            elseif (sz == "DBL") then
                ipc.writeDBL(co, pm)
            elseif (sz == "FLT") then
                ipc.writeFLT(co, pm)
            end
        else
            ipc.control(co, pm)
        end
    elseif (act == "T") then
        if (co > 65535) then
            pm = true
            ipc.control(co)
        end
    elseif (act == "S") then
        if (pm == nil) then
            return nil
        end
        if (co <= 65535) then
            if (sz == "UB") then
                ipc.setbitsUB(co, pm)
            elseif (sz == "UW") then
                ipc.setbitsUW(co, pm)
            elseif (sz == "UD") then
                ipc.setbitsUD(co, pm)
            end
        end
    elseif (act == "C") then
        if (pm == nil) then
            return nil
        end
        if (co <= 65535) then
            if (sz == "UB") then
                ipc.clearbitsUB(co, pm)
            elseif (sz == "UW") then
                ipc.clearbitsUW(co, pm)
            elseif (sz == "UD") then
                ipc.clearbitsUD(co, pm)
            end
        end
    end
    return pm
end

function fail_off(act, co, pm, sz)
    if (act == "W") then
        if (pm == nil) then
            return nil
        end
        if (co <= 65535) then
            if (sz == "UB") then
                ipc.writeUB(co, pm)
            elseif (sz == "UW") then
                ipc.writeUW(co, pm)
            elseif (sz == "UD") then
                ipc.writeUD(co, pm)
            elseif (sz == "SB") then
                ipc.writeSB(co, pm)
            elseif (sz == "SW") then
                ipc.writeSW(co, pm)
            elseif (sz == "SD") then
                ipc.writeSD(co, pm)
            elseif (sz == "DD") then
                ipc.writeDD(co, pm)
            elseif (sz == "DBL") then
                ipc.writeDBL(co, pm)
            elseif (sz == "FLT") then
                ipc.writeFLT(co, pm)
            end
        else
            ipc.control(co, pm)
        end
    elseif (act == "T") then
        if (co > 65535) then
            pm = false
            ipc.control(co)
        end
    elseif (act == "S") then
        if (pm == nil) then
            return nil
        end
        if (co <= 65535) then
            if (sz == "UB") then
                ipc.clearbitsUB(co, pm)
            elseif (sz == "UW") then
                ipc.clearbitsUW(co, pm)
            elseif (sz == "UD") then
                ipc.clearbitsUD(co, pm)
            end
        end
    elseif (act == "C") then
        if (pm == nil) then
            return nil
        end
        if (co <= 65535) then
            if (sz == "UB") then
                ipc.setbitsUB(co, pm)
            elseif (sz == "UW") then
                ipc.setbitsUW(co, pm)
            elseif (sz == "UD") then
                ipc.setbitsUD(co, pm)
            end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Callbacks

function fail_display(flag)
    local str = ""
    
    for i=1,table.getn(failures) do
        local co = failures[i][3]
        
        if (failures_co[co][i] ~= nil) then
            if (str ~= "") then
                str = str..", "
            end
            str = str..failures[i][9]
        end
    end
    
    if (str == "") then
        str = "None"
    end
    
    ipc.writeSTR(0x3380, "Failed: "..str)
    ipc.writeUW(0x32FA, -1)
end

function fail_force(co, pm)
    for k,v in pairs(failures_co[co]) do
        if (failures_co[co][k] ~= nil) then
            local act = failures[k][2]
            local pm = failures[k][4]
            local sz = failures[k][6]
            
            if (pm == nil) then -- keep option has kept value in failures_co
                pm = failures_co[co][k]
            end
            
            fail_on(act, co, pm, sz)
        end
    end
end

function fail_something(t)
	ipc.log("Fail...")
    if (ipc.readUW(0x0262) == 1 or ipc.readUW(0x05DC) == 1) then -- paused or slew mode, don't fail
        return
    end
	
    for i=1,table.getn(failures) do
        local prob = failures[i][1]
        local act = failures[i][2]
        local co = failures[i][3]
        local p = math.ceil(prob*3600/rate*1000)
		local p2 = math.ceil(p/2)
		
        if (failures_co[co] == nil) then
            failures_co[co] = {}
        end
        if (failures_co[co][i] == nil and math.random(1, p) == p2) then
            local pm = failures[i][4]
            local sz = failures[i][6]
            local force = failures[i][7]
            local loc = failures[i][8]
            
            if (loc < 0 or loc == ipc.readUW(0x0366)) then -- air, ground or both
				ipc.log("Failing "..failures[i][9])
				
                failures_co[co][i] = fail_on(act, co, pm, sz)
				
                if (failures_co[co][i] ~= nil) then
                    if (force == true) then
                        if (co <= 65535) then -- offset
                            event.offset(co, sz, "fail_force")
                        else -- control
                            event.control(co, "fail_force")
                        end
                    end
                    if (show == true) then
                        fail_display(0)
                    end
                end
            end
        end
    end

	ipc.log("Done.")
end

function fail_reset(flag)
	ipc.log("Reset...")
    event.cancel("fail_force")

    for i=1,table.getn(failures) do
        local act = failures[i][2]
        local co = failures[i][3]
        local pm = failures[i][5]
        local sz = failures[i][6]
        
        if (failures_co[co][i] ~= nil) then
			ipc.log("Clearing "..failures[i][9])

			fail_off(act, co, pm, sz)
            
			failures_co[co][i] = nil
        end
    end
	
	ipc.log("Done.")
end

--------------------------------------------------------------------------------
-- Main

math.randomseed(os.time())

event.timer(rate, "fail_something")
event.flag(1, "fail_display")
event.flag(2, "fail_reset")

ipc.log("Done.")
