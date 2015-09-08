ThrottleOffsetControl = {}
ThrottleOffsetControl[0x3330] = 65820
ThrottleOffsetControl[0x3332] = 65821

function ThrottleDisconnect()
    ipc.setbitsUB(0x310A, 0x40)
    ipc.setbitsUB(0x310A, 0x80)
end

function ThrottleUpdate(ofs, val)
	if (val < 0) then
		val = val * 4
	end
	ipc.control(ThrottleOffsetControl[ofs], val)
end

event.timer(1000, "ThrottleDisconnect")
event.offset(0x3330, "SW", "ThrottleUpdate")
event.offset(0x3332, "SW", "ThrottleUpdate")
ipc.log("Ready.")