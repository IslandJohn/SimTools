function ToggleFDATH(short)
	if (short) then
		ipc.macro("GoFlightERJ: FD")
	else
	end
end

function ToggleAPYD(short)
	if (short) then
		ipc.macro("GoFlightERJ: AP")
	else
		ipc.macro("GoFlightERJ: YD")
	end
end

function ToggleHDGROL(short)
	if (short) then
		ipc.macro("GoFlightERJ: HDG")
	else
	end
end

function ToggleNAVGS(short)
	if (short) then
		ipc.macro("GoFlightERJ: NAV")
	else
	end
end

function ToggleAPRREV(short)
	if (short) then
		ipc.macro("GoFlightERJ: APR")
	else
	end
end

function ToggleALTSELALT(short)
	if (short) then
	else
		ipc.macro("GoFlightERJ: ALT")
	end
end

function ToggleVSPIT(short)
	if (short) then
		ipc.macro("GoFlightERJ: VS")
	else
	end
end

function ToggleIASMACH(short)
	if (short) then
		ipc.macro("GoFlightERJ: SPD")
	else
		ipc.macro("GoFlightERJ: FLC")
	end
end

ipc.log("Loaded ERJ")