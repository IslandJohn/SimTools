ipc.log("Starting...")

local engines = {
	{ 0x208C, 0x3B00, 66300 },
	{ 0x218C, 0x3A40, 66301 },
	{ 0x228C, 0x3980, 66302 },
	{ 0x238C, 0x38C0, 66303 },
}

function ignition_off(i)
	if (ipc.readUD(engines[i][1]) ~= 0) then
		ipc.writeUD(engines[i][1], 0)
	end
end

function ignition_on(i)
	if (ipc.readUD(engines[i][1]) == 0) then
		ipc.writeUD(engines[i][1], 1)
	end
end

function starter_off(i)
	if (ipc.readUD(engines[i][2]) ~= 0) then
		ipc.control(engines[i][3])
	end
end

function starter_on(i)
	if (ipc.readUD(engines[i][2]) == 0) then
		ipc.control(engines[i][3])
	end
end

if (logic.And(ipcPARAM, 1) ~= 0) then
	for i=1,table.getn(engines) do
		ignition_off(i)
	end
end

if (logic.And(ipcPARAM, 2) ~= 0) then
	for i=1,table.getn(engines) do
		ignition_on(i)
	end
end

if (logic.And(ipcPARAM, 4) ~= 0) then
	for i=1,table.getn(engines) do
		starter_off(i)
	end
end

if (logic.And(ipcPARAM, 8) ~= 0) then
	for i=1,table.getn(engines) do
		starter_on(i)
	end
end

ipc.log("Done.")
