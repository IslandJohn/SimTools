-- Payload Manager 1.0.0
-- E-mail: pilotjohn at gearsdown.com
--
-- Script to automatically load an aircraft to a random payload level,
-- and to provide a simple mechanism to change payload quantity.
-- Setup:
--
-- 1. Edit "FSUIPC.ini" and add (substitute X for 1 or next # if exists):
--     [Auto]
--     X=Lua PayloadManager
--
-- 2. In FSUIPC "Buttons + Switches",
--     "PRESS" "BUTTON",
--     check "Select for FS control",
--     choose "Lua PayloadManager",
--     and enter "1" for "Paramater"
--
-- 3. Configure below as desired.

ipc.log("Starting...")

local PROMPT = false -- prompt for payload level on start?

math.randomseed(os.time())
math.random()
math.random()
math.random()

local uload = (ipc.readUD(0x1334)-ipc.readUD(0x1330)) / 256
local plevel = math.random(25, 75) -- payload weight level as a % of useful load
local pweight = uload*plevel/100
local pcount = ipc.readUD(0x13FC)
if (pcount > 61) then
	pcount = 61
end
local poffset = 0x1400

ipc.lineDisplay(string.format("Useful Load: %dlbs", uload))
for i = 1,pcount do
	local sweight = ipc.readDBL(poffset+0)
	local sname = ipc.readSTR(poffset+32, 16)
	
	ipc.lineDisplay(string.format("  %s: %dlbs", sname, sweight), -32)
	
	poffset = poffset + 48
end

ipc.log("Done.")
