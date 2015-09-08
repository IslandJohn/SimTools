function ToggleFuel(short)
	if (ipc.readLvar("fuelPumpSwitchL") == 1 and ipc.readLvar("fuelPumpSwitchR") == 1) then
		if (short) then
			ipc.writeLvar("fuelPumpSwitchL", 2)
			ipc.writeLvar("fuelPumpSwitchR", 2)
		else
			ipc.writeLvar("fuelPumpSwitchL", 0)
			ipc.writeLvar("fuelPumpSwitchR", 0)
		end
	else
		ipc.writeLvar("fuelPumpSwitchL", 1)
		ipc.writeLvar("fuelPumpSwitchR", 1)
	end
end

function ToggleIgnition(short)
	if (ipc.readLvar("ignSwL") == 1 and ipc.readLvar("ignSwR") == 1) then
		if (short) then
			ipc.writeLvar("ignSwL", 2)
			ipc.writeLvar("ignSwR", 2)
		else
			ipc.writeLvar("ignSwL", 0)
			ipc.writeLvar("ignSwR", 0)
		end
	else
		ipc.writeLvar("ignSwL", 1)
		ipc.writeLvar("ignSwR", 1)
	end
	
--	if (PowerEngine == 0) then
--		ign = ipc.readLvar("ignSwL")
--		if (ign == 1) then
--			if (short) then
--				ipc.writeLvar("ignSwL", 2)
--			else
--				ipc.writeLvar("ignSwL", 0)
--			end
--		else
--			ipc.writeLvar("ignSwL", 1)
--		end
--	elseif (PowerEngine == 1) then
--		ign = ipc.readLvar("ignSwR")
--		if (ign == 1) then
--			if (short) then
--				ipc.writeLvar("ignSwR", 2)
--			else
--				ipc.writeLvar("ignSwR", 0)
--			end
--		else
--			ipc.writeLvar("ignSwR", 1)
--		end
--	end
end

function InverterOnAvionics(ofs, val)
	if (val == 0) then
		ipc.writeLvar("Duke_inverter_Switch", 1)
	else
		ipc.writeLvar("Duke_inverter_Switch", 0)
	end
end

event.offset(0x2e80, "UD", "InverterOnAvionics")
ipc.log("Loaded DukeT")