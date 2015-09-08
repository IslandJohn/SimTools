require "GoFlightRP48"

PowerUnit = 2
PowerDelay = 100
PowerEngine = 1
PowerStates = { 1, 1, 1, 1 }

GFRP48_DefineRotary(PowerUnit, 0, "SetMain", 1, 1, 3, 1);
-- GFRP48_DefineRotary(PowerUnit, 1, "SetEngineSelectNO", 1, 1, 4, 1);
-- GFRP48_DefineRotary(PowerUnit, 2, "SetEngineModeNO", 1, 1, 3, 1);
GFRP48_DefineRotary(PowerUnit, 1, "SetEngine1", 1, 1, 3, 1);
GFRP48_DefineRotary(PowerUnit, 2, "SetEngine2", 1, 1, 3, 1);
GFRP48_DefineRotary(PowerUnit, 3, "SetBaro");

GFRP48_DefinePush(PowerUnit, 0, "ToggleLightsInstrumentCabin");
GFRP48_DefinePush(PowerUnit, 1, "ToggleLightsBeaconLogo");
GFRP48_DefinePush(PowerUnit, 2, "ToggleLightsNavLogo");
GFRP48_DefinePush(PowerUnit, 3, "ToggleLightsTaxiWing");
GFRP48_DefinePush(PowerUnit, 4, "ToggleLightsLandRecog");
GFRP48_DefinePush(PowerUnit, 5, "ToggleLightsStrobeRecog");
GFRP48_DefinePush(PowerUnit, 6, "ToggleFuel");
GFRP48_DefinePush(PowerUnit, 7, "ToggleIgnition");

function SetMain(vel, state)
	if (state == 1) then
		ipc.writeSD(0x281c, 0) -- battery
		ipc.writeSD(0x2e80, 0) -- avionics
		LightsOff()
	elseif (state == 2) then
		ipc.writeSD(0x281c, 1)
		ipc.writeSD(0x2e80, 0)
		LightsOn()
	elseif (state == 3) then
		ipc.writeSD(0x281c, 1)
		ipc.writeSD(0x2e80, 1)
	end
end

function SetEngineSelectNO(vel, state) -- no override
	SetEngineSelect(vel, state)
	GFRP48_Map[PowerUnit][2+GFRP48_RotaryOffset][GFRP48_RotaryState] = PowerStates[PowerEngine] -- swap to the right state for "Mode"
end

function SetEngineSelect(vel, state)
	PowerEngine = state
end

function SetEngineModeNO(vel, state) -- no override
	SetEngineMode(vel, state)
	PowerStates[PowerEngine] = state
end

function SetEngineMode(vel, state)
	engine = ipc.readSB(0x0609)
	if (PowerEngine == 1) then
		if (engine == 0) then -- piston
			if (state == 1) then
				ipc.writeSW(0x0892, 0) -- starter 1
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 0) -- generator 1
			elseif (state == 2) then
				ipc.writeSW(0x0892, 3)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 1)
			elseif (state == 3) then
				ipc.writeSW(0x0892, 4)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 0)
			end
		elseif (engine == 1) then -- jet
			if (state == 1) then
				ipc.writeSW(0x0892, 0)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 0)
			elseif (state == 2) then
				ipc.writeSW(0x0892, 2)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 1)
			elseif (state == 3) then
				ipc.writeSW(0x0892, 1)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 0)
			end
		elseif (engine == 3 or engine == 5) then
			if (state == 1) then
				ipc.writeSW(0x0892, 0)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 0)
			elseif (state == 2) then
				ipc.writeSW(0x0892, 2)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 1)
			elseif (state == 3) then
				ipc.writeSW(0x0892, 1)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3b78, 0)
			end
		end
	elseif (PowerEngine == 2) then
		if (engine == 0) then -- piston
			if (state == 1) then
				ipc.writeSW(0x092a, 0) -- starter 2
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 0) -- generator 2
			elseif (state == 2) then
				ipc.writeSW(0x092a, 3)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 1)
			elseif (state == 3) then
				ipc.writeSW(0x092a, 4)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 0)
			end
		elseif (engine == 1) then -- jet
			if (state == 1) then
				ipc.writeSW(0x092a, 0)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 0)
			elseif (state == 2) then
				ipc.writeSW(0x092a, 2)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 1)
			elseif (state == 3) then
				ipc.writeSW(0x092a, 1)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 0)
			end
		elseif (engine == 3 or engine == 5) then -- turboprop
			if (state == 1) then
				ipc.writeSW(0x092a, 0)
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 0)
			elseif (state == 2) then
				ipc.writeSW(0x092a, 2)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 1)
			elseif (state == 3) then
				ipc.writeSW(0x092a, 1)	
				ipc.sleep(PowerDelay)
				ipc.writeSW(0x3ab8, 0)
			end
		end
	end
end

function SetEngine1(vel, state)
	PowerEngine = 1
	SetEngineMode(vel, state)
end

function SetEngine2(vel, state)
	PowerEngine = 2
	SetEngineMode(vel, state)
end

function SetBaro(vel, state)
	baro = ipc.readSW(0x0330) -- pressure
	if (vel < 0) then
		ipc.writeSW(0x0330, baro - vel*vel*4)
	else
		ipc.writeSW(0x0330, baro + vel*vel*4)
	end
end

function ToggleLightsInstrumentCabin(short)
	if (short) then
		ipc.togglebitsUW(0x0d0c, 32)
	else
		ipc.togglebitsUW(0x0d0c, 512)
	end
end

function ToggleLightsBeaconLogo(short)
	if (short) then
		ipc.togglebitsUW(0x0d0c, 2)
	else
		ipc.togglebitsUW(0x0d0c, 256)
	end
end

function ToggleLightsNavLogo(short)
	if (short) then
		ipc.togglebitsUW(0x0d0c, 1)
	else
		ipc.togglebitsUW(0x0d0c, 256)
	end
end

function ToggleLightsTaxiWing(short)
	if (short) then
		ipc.togglebitsUW(0x0d0c, 8)
	else
		ipc.togglebitsUW(0x0d0c, 128)
	end
end

function ToggleLightsLandRecog(short)
	if (short) then
		ipc.togglebitsUW(0x0d0c, 4)
	else
		ipc.togglebitsUW(0x0d0c, 64)
	end
end

function ToggleLightsStrobeRecog(short)
	if (short) then
		ipc.togglebitsUW(0x0d0c, 16)
	else
		ipc.togglebitsUW(0x0d0c, 64)
	end
end

function ToggleFuel(short)
	if (ipc.readUB(0x3125) == 0) then
		ipc.writeUB(0x3125, 3)
	else
		ipc.writeUB(0x3125, 0)
	end
	
--	if (PowerEngine == 1) then
--		ipc.togglebitsUB(0x3125, 1) -- pump 1
--	elseif (PowerEngine == 2) then
--		ipc.togglebitsUB(0x3125, 2) -- pump 2
--	end
end

function ToggleIgnition(short)
	if (ipc.readSW(0x208c) == 0 and ipc.readSW(0x218c) == 0) then
		ipc.writeSW(0x208c, 1)
		ipc.writeSW(0x218c, 1)
	else
		ipc.writeSW(0x218c, 0)
		ipc.writeSW(0x208c, 0)
	end
	
--	if (PowerEngine == 1) then
--		if (ipc.readSW(0x208c) == 0) then
--			ipc.writeSW(0x208c, 1) -- ignition 1
--		else
--			ipc.writeSW(0x208c, 0)
--		end
--	elseif (PowerEngine == 2) then
--		if (ipc.readSW(0x218c) == 0) then
--			ipc.writeSW(0x218c, 1) -- ignition 2
--		else
--			ipc.writeSW(0x218c, 0)
--		end
--	end
end
