require "GoFlightRP48"

APUnit = 1
APDelay = 100

APLat = 1
APVert = 1

-- GFRP48_DefineRotary(APUnit, 0, "SetLatSelect", 1, 1, 3, 1);
-- GFRP48_DefineRotary(APUnit, 1, "SetLatValue");
-- GFRP48_DefineRotary(APUnit, 2, "SetVertSelect", 1, 1, 4, 1);
-- GFRP48_DefineRotary(APUnit, 3, "SetVertValue");
GFRP48_DefineRotary(APUnit, 0, "SetHDGValue");
GFRP48_DefineRotary(APUnit, 1, "SetCRSValue");
GFRP48_DefineRotary(APUnit, 2, "SetALTValue");
GFRP48_DefineRotary(APUnit, 3, "SetVSIValue");

GFRP48_DefinePush(APUnit, 0, "ToggleFDATH");
GFRP48_DefinePush(APUnit, 1, "ToggleAPYD");
GFRP48_DefinePush(APUnit, 2, "ToggleHDGROL");
GFRP48_DefinePush(APUnit, 3, "ToggleNAVGS");
GFRP48_DefinePush(APUnit, 4, "ToggleAPRREV");
GFRP48_DefinePush(APUnit, 5, "ToggleALTSELALT");
GFRP48_DefinePush(APUnit, 6, "ToggleVSPIT");
GFRP48_DefinePush(APUnit, 7, "ToggleIASMACH");

function APLimit(n, a, b)
	if (n < a) then
		n = a
	end
	if (n > b) then
		n = b
	end
	return n
end

function APNorm(n, a, b)
	while (n < a) do
		n = n + (b - a)
	end
	while (n >= b) do
		n = n - (b - a)
	end
	return n
end

function APNormDeg(d)
	return APNorm(d, 0, 360)
end

function APFeet2M(f)
	return f * 12 * 2.54 / 100
end

function SetLatSelect(vel, state)
	APLat = state
end

function SetLatValue(vel, state)
	if (APLat == 1) then
		hdg = ipc.readUW(0x07cc) * 360 / 65536
		if (vel < 0) then
			hdg = (hdg - vel*vel)
		else
			hdg = (hdg + vel*vel)
		end
		ipc.writeUW(0x07cc, APNormDeg(hdg) * 65536 / 360)
	elseif (APLat == 2) then
		crs = ipc.readUW(0x0c4e)
		if (vel < 0) then
			crs = crs - vel*vel
		else
			crs = crs + vel*vel
		end
		ipc.writeUW(0x0c4e, APNormDeg(crs))
	elseif (APLat == 3) then
		crs = ipc.readUW(0x0c5e)
		if (vel < 0) then
			crs = crs - vel*vel
		else
			crs = crs + vel*vel
		end
		ipc.writeUW(0x0c5e, APNormDeg(crs))
	end
end

function SetVertSelect(vel, state)
	APVert = state
end

function SetVertValue(vel, state)
	if (APVert == 1) then -- altitude
		alt = ipc.readSD(0x07d4) / 65536
		if (vel < 0) then
			alt = alt - APFeet2M(vel*vel*100)
		else
			alt = alt + APFeet2M(vel*vel*100)
		end
		ipc.writeSD(0x07d4, APLimit(alt, 0, APFeet2M(99999)) * 65536)
	elseif (APVert == 2) then -- vs
		vs = ipc.readSW(0x07f2)
		if (vel < 0) then
			vs = vs + vel*100
		else
			vs = vs + vel*100
		end
		ipc.writeSW(0x07f2, APLimit(vs, -10000, 10000))
	elseif (APVert == 3) then -- ias
		ias = ipc.readSW(0x07e2)
		if (vel < 0) then
			ias = ias - vel*vel
		else
			ias = ias + vel*vel
		end
		ipc.writeSW(0x07e2, APLimit(ias, 0, 999))
	elseif (APVert == 4) then -- pitch
		if (vel < 0) then
			for i=1,-vel,1 do
				ipc.control(66584)
			end
		else
			for i=1,vel,1 do
				ipc.control(66583)
			end
		end
	end
end

function SetHDGValue(vel, state)
	APLat = 1
	SetLatValue(vel, state)
end

function SetCRSValue(vel, state)
	APLat = 2
	SetLatValue(vel, state)
end

function SetALTValue(vel, state)
	APVert = 1
	SetVertValue(vel, state)
end

function SetVSIValue(vel, state)
	APVert = 2
	SetVertValue(vel, state)
	APVert = 3
	SetVertValue(vel, state)
	APVert = 4
	SetVertValue(vel, state)
end

function ToggleFDATH(short)
	if (short) then
		if (ipc.readSD(0x2ee0) == 0) then
			ipc.writeSD(0x2ee0, 1)
		else
			ipc.writeSD(0x2ee0, 0)
		end
	else
		if (ipc.readSD(0x0810) == 0) then
			ipc.writeSD(0x0810, 1)
		else
			ipc.writeSD(0x0810, 0)
		end
	end
end

function ToggleAPYD(short)
	if (short) then
		if (ipc.readSD(0x07bc) == 0) then
			ipc.writeSD(0x07bc, 1)
		else
			ipc.writeSD(0x07bc, 0)
		end
	else
		if (ipc.readSD(0x0808) == 0) then
			ipc.writeSD(0x0808, 1)
		else
			ipc.writeSD(0x0808, 0)
		end
	end
end

function ToggleHDGROL(short)
	if (short) then
		if (ipc.readSD(0x07c8) == 0) then
			ipc.writeSD(0x07c8, 1)
		else
			ipc.writeSD(0x07c8, 0)
		end
	else
		if (ipc.readSD(0x07c0) == 0) then
			ipc.writeSD(0x07c0, 1)
		else
			ipc.writeSD(0x07c0, 0)
		end
	end
end

function ToggleNAVGS(short)
	if (short) then
		if (ipc.readSD(0x07c4) == 0) then
			ipc.writeSD(0x07c4, 1)
		else
			ipc.writeSD(0x07c4, 0)
		end
	else
		if (ipc.readSD(0x07fc) == 0) then
			ipc.writeSD(0x07fc, 1)
		else
			ipc.writeSD(0x07fc, 0)
		end
	end
end

function ToggleAPRREV(short)
	if (short) then
		if (ipc.readSD(0x0800) == 0) then
			ipc.control(65806)
			--ipc.writeSD(0x0800, 1)
			--ipc.writeSD(0x07fc, 1)
		else
			ipc.control(65814)			
			--ipc.writeSD(0x0800, 0)
			--ipc.writeSD(0x07fc, 0)
		end
	else
		if (ipc.readSD(0x0804) == 0) then
			ipc.writeSD(0x0804, 1)
		else
			ipc.writeSD(0x0804, 0)
		end
	end
end

function ToggleALTSELALT(short)
	if (short) then
		if (ipc.readSD(0x07d0) == 0) then
			ipc.writeSD(0x07d0, 1)
		else
			ipc.writeSD(0x07d0, 0)
		end
	else
		--alt1 = ipc.readSD(0x0574) + ipc.readUD(0x0570)/4294967296
		alt1 = APFeet2M(ipc.readSD(0x3324))
		alt2 = ipc.readSD(0x07d4)/65536
		
		if (ipc.readSD(0x07d0) == 0) then
			ipc.writeSD(0x07d4, alt1 * 65536)
			ipc.writeSD(0x07d0, 1)
		else
			if (math.abs(alt1-alt2) > 10) then
				ipc.writeSD(0x07d4, alt1 * 65536)
			else
				ipc.writeSD(0x07d0, 0)
			end
		end
	end
end

function ToggleVSPIT(short)
	if (short) then
		if (ipc.readSD(0x07ec) == 0) then
			ipc.writeSD(0x07ec, 1)
		else
			ipc.writeSD(0x07ec, 0)
		end
	else
		if (ipc.readSD(0x07d8) == 0) then
			ipc.writeSD(0x07d8, 1)
		else
			ipc.writeSD(0x07d8, 0)
		end
	end
end

function ToggleIASMACH(short)
	if (short) then
		if (ipc.readSD(0x07dc) == 0) then
			ipc.writeSD(0x07dc, 1)
		else
			ipc.writeSD(0x07dc, 0)
		end
	else
		if (ipc.readSD(0x07e4) == 0) then
			ipc.writeSD(0x07e4, 1)
		else
			ipc.writeSD(0x07e4, 0)
		end
	end
end
