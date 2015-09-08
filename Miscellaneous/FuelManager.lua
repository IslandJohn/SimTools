-- Fuel Manager 1.1.0
-- E-mail: pilotjohn at gearsdown.com
--
-- Script to automatically fuel an aircraft to a preselected tank level,
-- and to provide a simple mechanism to refuel or change fuel quantity.
-- Setup:
--
-- 1. Edit "FSUIPC.ini" and add (substitute X for 1 or next # if exists):
--     [Auto]
--     X=Lua FuelManager
--
-- 2. In FSUIPC "Buttons + Switches",
--     "PRESS" "BUTTON",
--     check "Select for FS control",
--     choose "Lua FuelManager",
--     and enter "1" for "Paramater"
--
-- 3. Configure below as desired.

ipc.log("Starting...")

local PROMPT = false -- prompt for fuel level on start?

math.randomseed(os.time())
math.random()
local level = math.random(33, 66) -- default fuel level % of total
local delta = 1 -- global fuel level variation +/- % of total
local tanks = {
	{ 0x0B7C, 0x0B80, "Left Main", },
	{ 0x0B84, 0x0B88, "Left Aux.", },
	{ 0x0B8C, 0x0B90, "Left Tip", },
	{ 0x0B94, 0x0B98, "Right Main", },
	{ 0x0B9C, 0x0BA0, "Right Aux.", },
	{ 0x0BA4, 0x0BA8, "Right Tip", },
	{ 0x0B74, 0x0B78, "Center 1", },
	{ 0x1244, 0x1248, "Center 2", },
	{ 0x124C, 0x1250, "Center 3", },
	{ 0x1254, 0x1258, "External 1", },
	{ 0x125C, 0x1260, "External 2", },
}
local scale = 128 * 65536 -- FSX units

math.randomseed(os.time())
math.random()

function fill(p)
	ipc.log("Filling to "..p.."%...")
	for i = 1,table.getn(tanks) do
		local l = -1
		while (l < 0 or l > scale) do
			l = (p*scale + math.random(-delta*scale, delta*scale)) / 100
		end
		ipc.writeUD(tanks[i][1], l)
	end
	ipc.log("Done.")
end

function change(p)
	ipc.log("Changing by "..p.."%...")
	for i = 1,table.getn(tanks) do
		local l = ipc.readUD(tanks[i][1])
		l = l + p*scale/100
		if (l < 0) then
			l = 0
		end
		if (l > scale) then
			l = scale
		end
		ipc.writeUD(tanks[i][1], l)
	end
	ipc.log("Done.")
end

if (PROMPT == true or ipcPARAM == 1) then
	local s = "Fuel Manager\n"
	local t = 0
	for i=1,table.getn(tanks) do
		local p = ipc.readUD(tanks[i][1])
		local c = ipc.readUD(tanks[i][2])
		if (c > 0) then
			s = s..string.format(" %s: %.1f gal. (%d%%)\n", tanks[i][3], p*c/scale, p*100/scale)
			t = t + p*c/scale
		end
	end
	s = s..string.format(" Total: %.1f gal. (%d lbs.)\n", t, ipc.readUD(0x126C))
	
	local l = ipc.ask(s.." Enter the fuel level, or +/- change, as a % of capacity:")
	if (l ~= nil) then
		if (l == "") then
			fill(level)
		else
			if (string.sub(l, 1, 1) == "-" or string.sub(l, 1, 1) == "+") then
				change(l)
			else
				l = tonumber(l)
				if (l == nil) then
					return
				end
				if (l < 0) then
					l = 0
				end
				if (l > 100) then
					l = 100
				end
				fill(l)
			end
		end
	end
else
	fill(level)
end

ipc.log("Done.")
