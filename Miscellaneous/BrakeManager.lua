-- provide a more balanced brake application

local left = ipc.readSW(0x0BC4);
local right = ipc.readSW(0x0BC6);

function brake_disconnect(t)
	ipc.setbitsUB(0x341A, 3)
end

function brake_set(l, r)
	local d, d2
	if (l < r) then
		d = r - l;
		d2 = d*d / 16384;
		ipc.writeSW(0x0BC4, l)
		ipc.writeSW(0x0BC6, l + d2)
		--ipc.display("Right was "..(left+d)..", now "..(left+d2), 1);
	else
		d = l - r;
		d2 = d*d / 16384;
		ipc.writeSW(0x0BC4, r + d2)
		ipc.writeSW(0x0BC6, r)
		--ipc.display("Left was "..(right+d)..", now "..(right+d2), 1);
	end
end

function brake_left(o, v)
	left = v;
	brake_set(left, right);
end

function brake_right(o, v)
	right = v;
	brake_set(left, right);
end

brake_disconnect(0)
event.timer(3000, "brake_disconnect")
event.offset(0x3416, "SW", "brake_left")
event.offset(0x3418, "SW", "brake_right")
