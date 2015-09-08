ipc.log("Starting...")

-- MUTE button ON

if ipc.readLvar("L:CapMuted") == 0 then
	ipc.writeLvar("L:CapMuteSwitch", 1)
	ipc.control(66587,8031)
	ipc.writeLvar("L:CapMuted", 1)
	ipc.sleep(200)
	ipc.writeLvar("L:CapMuteSwitch", 0)
	ipc.control(66587,8031)
end

-- LEFT Generator Switch OFF

if ipc.readLvar("L:LeftGenSwitch") == 2 then
	ipc.writeLvar("L:LeftGenSwitch", 1)
	ipc.control(66587, 8027)
end

-- RIGHT Generator Switch OFF

if ipc.readLvar("L:RightGenSwitch") == 2 then
	ipc.writeLvar("L:RightGenSwitch", 1)
	ipc.control(66587, 8027)
end

-- LEFT Battery Switch OFF

if ipc.readLvar("L:LeftBatSwitch") == 1 then
	ipc.writeLvar("L:LeftBatSwitch", 0)
	ipc.control(66587, 8028)
end

-- Right Battery Switch OFF

if ipc.readLvar("L:RightBatSwitch") == 1 then
	ipc.writeLvar("L:RightBatSwitch", 0)
	ipc.control(66587, 8028)
end

-- Left Avionics Switch OFF

if ipc.readLvar("L:LeftAvionicsMaster") == 1 then
	ipc.writeLvar("L:LeftAvionicsMasterGuard", 0)
	ipc.control(66587, 8026)
	ipc.sleep(500)
	ipc.writeLvar("L:LeftAvionicsMaster", 0)
	ipc.control(66587, 8027)
end

-- RIGHT Avionics Switch OFF

if ipc.readLvar("L:RightAvionicsMaster") == 1 then
	ipc.writeLvar("L:RightAvionicsMasterGuard", 0)
	ipc.control(66587, 8026)
	ipc.sleep(500)
	ipc.writeLvar("L:RightAvionicsMaster", 0)
	ipc.control(66587, 8027)
end

-- LEFT Fuel Pump Switch OFF

if ipc.readLvar("L:LeftStbyFuelPump") == 1 then
	ipc.writeLvar("L:LeftStbyFuelPump", 0)
	ipc.control(66587, 8027)
end

-- RIGHT Fuel Pump Switch OFF

if ipc.readLvar("L:RightStbyFuelPump") == 1 then
	ipc.writeLvar("L:RightStbyFuelPump", 0)
	ipc.control(66587, 8027)
end

-- DC Power Source Knob OFF

if ipc.readLvar("L:DCPowerSourceKnob") >= 1 then
	ipc.writeLvar("L:DCPowerSourceKnob", 0)
	ipc.control(66587, 8039)
end

-- Left Windshield Antiice OFF

LWS = ipc.readLvar("L:LeftWSAntice")
if (LWS == 2 or LWS == 0) then
	ipc.writeLvar("L:LeftWSAntice",1)
	ipc.control(66587,8027)
end

-- Right Windshield Antiice OFF

RWS = ipc.readLvar("L:RightWSAntice")
if RWS == 1 then
	ipc.writeLvar("L:RightWSAntice",0)
	ipc.control(66587,8027)
end

-- Left Air Data OFF

LAD = ipc.readLvar("L:LeftAirData")
if LAD == 1 then
	ipc.writeLvar("L:LeftAirData",0)
	ipc.control(66587,8027)
end

-- Right Air Data OFF

RAD = ipc.readLvar("L:RightAirData")
if RAD == 1 then
	ipc.writeLvar("L:RightAirData",0)
	ipc.control(66587,8027)
end

-- Gust Locks

ipc.writeLvar("L:GustLocks", 1)
ipc.control(66587, 141)

ipc.log("Done.")
