function InverterOnAvionics(ofs, val)
	if (val == 0) then
		ipc.writeLvar("Duke_inverter_Switch", 1)
	else
		ipc.writeLvar("Duke_inverter_Switch", 0)
	end
end

function LogoOnLanding(ofs, val)
	if (logic.And(val, 4) == 0) then
		ipc.clearbitsUW(0x0d0c, 256)
	else
		ipc.setbitsUW(0x0d0c, 256)
	end
end

event.offset(0x2e80, "UD", "InverterOnAvionics")
event.offset(0x0d0c, "UW", "LogoOnLanding")
ipc.log("Loaded Duke")