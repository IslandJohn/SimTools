require "GoFlightRP48"

RadioUnit = 0
RadioDelay = 10
RadioStack = 0

GFRP48_DefineRotary(RadioUnit, 0, "SetMHZ");
GFRP48_DefineRotary(RadioUnit, 1, "SetKHZ");
GFRP48_DefineRotary(RadioUnit, 2, "SetOuter");
GFRP48_DefineRotary(RadioUnit, 3, "SetInner");

GFRP48_DefinePush(RadioUnit, 0, "ToggleSwapStack");
GFRP48_DefinePush(RadioUnit, 1, "ToggleCDIOBS");
GFRP48_DefinePush(RadioUnit, 2, "ToggleMSGVNAV");
GFRP48_DefinePush(RadioUnit, 3, "ToggleFPLPROC");
GFRP48_DefinePush(RadioUnit, 4, "ToggleDMENU");
GFRP48_DefinePush(RadioUnit, 5, "ToggleENTCLR");
GFRP48_DefinePush(RadioUnit, 6, "ToggleCRSRPWR");
GFRP48_DefinePush(RadioUnit, 7, "ToggleRange");

function SetMHZ(vel, state)
	if (RadioStack == 0) then
		freq = ipc.readUW(0x311a)
		khz = math.floor(freq % 256)
		mhz = string.format("%x", math.floor(freq / 256)) + 0
		mhz = mhz + vel
		if (mhz > 36) then
			mhz = 18
		elseif (mhz < 18) then
			mhz = 36
		end
		mhz = tonumber(mhz .. "", 16)
		freq = mhz * 256 + khz
		ipc.writeUW(0x311a, freq)
	elseif (RadioStack == 1) then
		freq = ipc.readUW(0x311e)
		khz = math.floor(freq % 256)
		mhz = string.format("%x", math.floor(freq / 256)) + 0
		mhz = mhz + vel
		if (mhz > 17) then
			mhz = 8
		elseif (mhz < 8) then
			mhz = 17
		end
		mhz = tonumber(mhz .. "", 16)
		freq = mhz * 256 + khz
		ipc.writeUW(0x311e, freq)
	end
end

function SetKHZ(vel, state)
	if (RadioStack == 0) then
		freq = ipc.readUW(0x311a)
		mhz = math.floor(freq / 256)
		khz = string.format("%x", math.floor(freq % 256)) + 0
		khz = math.floor(khz / 2.5 + 0.5)
		khz = khz + vel
		if (khz > 39) then
			khz = 0
		elseif (khz < 0) then
			khz = 39
		end
		khz = math.floor(khz * 2.5)
		khz = tonumber(khz .. "", 16)
		freq = mhz * 256 + khz
		ipc.writeUW(0x311a, freq)
	elseif (RadioStack == 1) then
		freq = ipc.readUW(0x311e)
		mhz = math.floor(freq / 256)
		khz = string.format("%x", math.floor(freq % 256)) + 0
		khz = math.floor(khz / 2.5 + 0.5)
		khz = khz + vel
		if (khz > 39) then
			khz = 0
		elseif (khz < 0) then
			khz = 39
		end
		khz = math.floor(khz * 2.5)
		khz = tonumber(khz .. "", 16)
		freq = mhz * 256 + khz
		ipc.writeUW(0x311e, freq)
	end
end

function SetOuter(vel, state)
	if (vel < 0) then
		for i=-1,vel,-1 do
			ipc.keypress(112, 11)
		end
		for i=-1,vel,-1 do
			ipc.keypress(65, 11)
		end
	else
		for i=1,vel,1 do
			ipc.keypress(113, 11)
		end
		for i=1,vel,1 do
			ipc.keypress(83, 11)
		end
	end
end

function SetInner(vel, state)
	if (vel < 0) then
		for i=-1,vel,-1 do
			ipc.keypress(114, 11)
		end
		for i=-1,vel,-1 do
			ipc.keypress(68, 11)
		end
	else
		for i=1,vel,1 do
			ipc.keypress(115, 11)
		end
		for i=1,vel,1 do
			ipc.keypress(70, 11)
		end
	end
end

function ToggleSwapStack(short)
	if (short) then
		if (RadioStack == 0) then
			ipc.writeUB(0x3123, 8)
		elseif (RadioStack == 1) then
			ipc.writeUB(0x3123, 2)
		end
	else
		RadioStack = RadioStack + 1
		if (RadioStack > 1) then
			RadioStack = 0
		end
		--ipc.keypress(120, 11)
	end
end

function ToggleCDIOBS(short)
	if (short) then
		if (ipc.readSD(0x132c) == 0) then
			ipc.writeSD(0x132c, 1) -- GPS
		else
			ipc.writeSD(0x132c, 0) -- VLOC
		end
		ipc.keypress(121, 11)
		ipc.keypress(81, 11)
	else
		ipc.keypress(122, 11)
		ipc.keypress(87, 11)
	end
end

function ToggleMSGVNAV(short)
	if (short) then
		ipc.keypress(123, 11)
		ipc.keypress(69, 11)
	else
		ipc.keypress(82, 11)
	end
end

function ToggleFPLPROC(short)
	if (short) then
		ipc.keypress(124, 11)
		ipc.keypress(84, 11)
	else
		ipc.keypress(125, 11)
		ipc.keypress(89, 11)
	end
end

function ToggleDMENU(short)
	if (short) then
		ipc.keypress(126, 11)
		ipc.keypress(85, 11)
	else
		ipc.keypress(127, 11)
		ipc.keypress(73, 11)
	end
end

function ToggleENTCLR(short)
	if (short) then
		ipc.keypress(128, 11)
		ipc.keypress(79, 11)
	else
		ipc.keypress(129, 11)
		ipc.keypress(80, 11)
	end
end

function ToggleCRSRPWR(short)
	if (short) then
		ipc.keypress(116, 11)
		ipc.keypress(71, 11)
	else
		ipc.keypress(117, 11)
		ipc.keypress(72, 11)
	end
end

function ToggleRange(short)
	if (short) then
		ipc.keypress(118, 11)
		ipc.keypress(74, 11)
	else
		ipc.keypress(119, 11)
		ipc.keypress(75, 11)
	end
end
