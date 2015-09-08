-- PMDG JetStream 4100 Saitek Multi-Panel Synchronizer 1.2.1
-- E-mail: pilotjohn at gearsdown.com
--
-- Synchronizes the JS41 autopilot functionality with the default FSX
-- behavior. This allows standard FSX compatible equipment (Saitek Multi-Panel)
-- to be used for some, if not most, auto-pilot functions.
-- Developed along SPAD, untested otherwise.
-- Setup:
--
-- 1. Edit "FSUIPC.ini" and add (substitute X for 1 or next # if exists):
--     [General]
--     UseProfiles=No
--     ShortAircraftNameOk=Substring
--     [Auto.Jetstream]
--     X=Lua JS41SaitekMP

ipc.log("Starting...")

--------------------------------------------------------------------------------
-- Helpers

meters2feet = 100/2.54/12
feet2meters = 12*2.54/100

--------------------------------------------------------------------------------
-- Callbacks

local lalt=-1
local latm=-1
function altitude_set(ofs, val)
	local nalt = math.floor(val*meters2feet/65536 + 0.5)
	if (lalt == nalt) then -- eliminate double calls
		return
	elseif (lalt >= 0 and math.abs(lalt - nalt) > 10000) then -- if VS is pressed altitude is set 60000, ignore and reset
		ipc.writeUD(0x07D4, math.floor(lalt*feet2meters*65536 + 0.5))
		return
	else
		lalt = nalt
	end
	local jalt = ipc.readLvar("AltSelAlt")
	local diff = math.abs(nalt - jalt) / 100
	
--	ipc.writeLvar("IrcAltSelKnob", 1)
	if (jalt < nalt) then
		for i=1,diff do
			ipc.control(66587, 3921)
		end
	elseif (nalt < jalt) then
		for i=1,diff do
			ipc.control(66587, 3920)
		end
	end
	ipc.control(66587, 8031)
	
	
	latm = ipc.elapsedtime()
end

-- Fix for +/-100FPM VS selection during ALT HLD new ALT selection
-- Fix for rate based GA and IAS dive as a result of large VS and VSI difference
function vertical_set(ofs, val)
	local alt = ipc.readLvar("CoamingAPALT")
	if (alt == 1) then
		ipc.writeSW(0x07F2, 0)
	else
		local vs = ipc.readSD(0x02C8) * meters2feet * 60 / 256
		vs = math.floor(vs/100 + 0.5) * 100

		if (math.abs(val - vs) > 1500) then -- max difference 1500 FPM
			if (val < vs) then
				ipc.writeSW(0x07F2,  vs - 1500)
			else
				ipc.writeSW(0x07F2, vs + 1500)
			end
		end
	end
end

local lspd = -1
local lstm = -1
function airspeed_set(ofs, val)
	local nspd = val
	if (lspd == nspd) then -- eliminate double calls
		return
	else
		lspd = nspd
	end
	local jspd = ipc.readLvar("VSIASTarget")
	if (jspd < 0) then
		ipc.writeUW(0x07E2, 0)
		
		return
	end
	local diff = math.abs(nspd - jspd)
	
	if (jspd < nspd) then
		for i=1,diff do
			ipc.control(66587, 1500)
		end
	elseif (nspd < jspd) then
		for i=1,diff do
			ipc.control(66587, 1501)
		end
	end
	ipc.control(66587, 8031)
	
	lstm = ipc.elapsedtime()
end

local lhdg = -1
local lhtm = -1
function heading_set(ofs, val)
	local nhdg = math.floor(val*360/65536 + 0.5)
	if (lhdg == nhdg) then -- eliminate double calls
		return
	else
		lhdg = nhdg
	end
	local jhdg = ipc.readLvar("HDGBug")
	local diff = math.abs(nhdg - jhdg)

	if (jhdg < nhdg) then
		for i=1,diff do
			ipc.control(66587, 26902)
		end
	elseif (nhdg < jhdg) then
		for i=1,diff do
			ipc.control(66587, 26901)
		end
	end
	ipc.control(66587, 8031)
	
	lhtm = ipc.elapsedtime()
end

function apm_toggle(ctrl, param)
	local yaw = ipc.readUD(0x0808)
	
	if (param ~= 0 and yaw ~= 0) then -- asked to turn on AP, but yaw damper is on, so turn it off
		ipc.writeLvar("L:APYDEngageSwitchSelect", 1)
		ipc.control(65793)
		ipc.control(66587,8038)
		ipc.sleep(100)
		ipc.writeLvar("L:APYDEngageSwitchSelect", 0)
		ipc.control(66587,8038)
	else
		ipc.writeLvar("L:APEngageSwitchSelect", 1)
		ipc.control(65580)
		ipc.control(66587,8038)
		ipc.sleep(100)
		ipc.writeLvar("L:APEngageSwitchSelect", 0)
		ipc.control(66587,8038)
	end
end

function hdg_toggle(ctrl, param)
	ipc.writeLvar("L:FdModeselHdgSwitch", 1)
	ipc.control(66587,277)
	ipc.control(66587,8031)
	ipc.sleep(100)
	ipc.writeLvar("L:FdModeselHdgSwitch", 0)
	ipc.control(66587,8031)
end

function nav_toggle(ofs, val)
	ipc.writeLvar("L:FdModeselNavSwitch", 1)
	ipc.control(66587,278)
	ipc.control(66587,8031)
	ipc.sleep(100)
	ipc.writeLvar("L:FdModeselNavSwitch", 0)
	ipc.control(66587,8031)
end

function apr_toggle(ofs, val)
	ipc.writeLvar("L:FdModeselAprSwitch", 1)
	ipc.control(66587,279)
	ipc.control(66587,8031)
	ipc.sleep(100)
	ipc.writeLvar("L:FdModeselAprSwitch", 0)
	ipc.control(66587,8031)
end

function bcr_toggle(ofs, val)
	ipc.writeLvar("L:FdModeselBcSwitch", 1)
	ipc.control(66587,280)
	ipc.control(66587,8031)
	ipc.sleep(100)
	ipc.writeLvar("L:FdModeselBcSwitch", 0)
	ipc.control(66587,8031)
end

function alt_toggle(ofs, val)
	ipc.writeLvar("L:FdModeselAltselSwitch", 1)
	ipc.control(66587,282)
	ipc.control(66587,8031)
	ipc.sleep(100)
	ipc.writeLvar("L:FdModeselAltselSwitch", 0)
	ipc.control(66587,8031)
end

function vsi_toggle(ofs, val)
	ipc.writeLvar("L:FdModeselVsSwitch", 1)
	ipc.control(66587,283)
	ipc.control(66587,8031)
	ipc.sleep(100)
	ipc.writeLvar("L:FdModeselVsSwitch", 0)
	ipc.control(66587,8031)
end

function ias_toggle(ofs, val)
	ipc.writeLvar("L:FdModeselIasSwitch", 1)
	ipc.control(66587,284)
	ipc.control(66587,8031)
	ipc.sleep(100)
	ipc.writeLvar("L:FdModeselIasSwitch", 0)
	ipc.control(66587,8031)
end

function altitude_update()
	if (ipc.elapsedtime() - latm < 1000) then -- give the gauge time to update
		return
	end
	
	-- update bug
	local jalt = ipc.readLvar("AltSelAlt")
	local oalt = math.floor(ipc.readUD(0x07D4)*meters2feet/65536 + 0.5)
	
	if (jalt ~= oalt) then
		ipc.writeUD(0x07D4, math.floor(jalt*feet2meters*65536 + 0.5))
	end
end

local lvsi = nil
function vertical_update()
	local jvsi = 0
	local ovsi = ipc.readSW(0x07F2)

	-- fix IAS to VS swap going to -9900 FPM
	if (lvsi ~= nil and math.abs(lvsi - ovsi) > 1000) then
		ipc.writeSW(0x07F2, lvsi)
	else
		lvsi = ovsi
	end
	
	jvsi = ipc.readLvar("CoamingAPVS")
	ovsi = ipc.readUD(0x07EC)
	
	if (jvsi ~= ovsi) then
		ipc.writeUD(0x07EC, jvsi)
	end
end

function airspeed_update()
	if (ipc.elapsedtime() - lstm < 1000) then -- give the gauge time to update
		return
	end
	
	-- update bug
	local jspd = ipc.readLvar("VSIASTarget")
	if (jspd < 0) then
		jspd = 0
	end
	local ospd = ipc.readUW(0x07E2)

	if (jspd ~= ospd) then
		ipc.writeUW(0x07E2, jspd)
	end
	
	jspd = ipc.readLvar("CoamingAPIAS")
	ospd = ipc.readUD(0x07DC)
	
	if (jspd ~= ospd) then
		ipc.writeUD(0x07DC, jspd)
	end
end

function heading_update()
	if (ipc.elapsedtime() - lhtm < 1000) then -- give the gauge time to update
		return
	end
	
	-- update bug
	local jhdg = ipc.readLvar("HDGBug")
	local ohdg = math.floor(ipc.readUW(0x07CC)*360/65536 + 0.5)

	if (jhdg ~= ohdg) then
		ipc.writeUW(0x07CC, math.floor(jhdg*65536/360 + 0.5))
	end
	
	-- update switch
	-- jhdg = ipc.readLvar("CoamingAPHDG")
	-- ohdg = ipc.readUD(0x07C8)
	
	-- if (jdgs ~= ohdg) then
		-- ipc.writeUD(0x07C8, jhdg)
	-- end
end

function ias_update()
end

function vs_update()
end

function no_op(ofs, val)
end

function run_update(t)
	altitude_update()
	vertical_update()
	airspeed_update()
	heading_update()
end

--------------------------------------------------------------------------------
-- Main

event.offset(0x07D4, "UD", "altitude_set")
event.offset(0x07F2, "SW", "vertical_set")
event.offset(0x07E2, "UW", "airspeed_set")
event.offset(0x07CC, "UW", "heading_set")

event.intercept(0x07BC, "UD", "apm_toggle")
event.intercept(0x07C8, "UD", "hdg_toggle")
event.intercept(0x07C4, "UD", "nav_toggle")
event.intercept(0x07FC, "UD", "no_op")
event.intercept(0x0800, "UD", "apr_toggle")
event.intercept(0x0804, "UD", "bcr_toggle")
event.intercept(0x07D0, "UD", "alt_toggle")
event.intercept(0x07EC, "UD", "vsi_toggle")
event.intercept(0x07DC, "UD", "ias_toggle")

event.timer(1000, "run_update")

ipc.log("Done.")
