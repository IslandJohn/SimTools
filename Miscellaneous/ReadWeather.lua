local m2f = 100/2.54/12
local nm2f = 2315000/381

function display_string(s, n) 
	ipc.lineDisplay(s, n)
	ipc.log(s)
end

function read_weather(flag)
	display_string("", 0)
	display_string("Nearby Airports: "
		..ipc.readSTR(0x0658, 4)..","
		..ipc.readSTR(0x066C, 4)..","
		..ipc.readSTR(0x0680, 4)..","
		..ipc.readSTR(0x0694, 4)..","
		..ipc.readSTR(0x06A8, 4)..","
		..ipc.readSTR(0x06BC, 4))
	display_string("Ground Altitude: "..ipc.readSD(0x0020)/256*m2f, -32)
	display_string("Aircraft Altitude: "..ipc.readDBL(0x6020)*m2f, -32)
	display_string("Aircraft VS0: "..ipc.readDBL(0x0538)*3600/nm2f, -32)
	display_string("Aircraft VS1: "..ipc.readDBL(0x0540)*3600/nm2f, -32)
	display_string("Aircraft GW: "..ipc.readDBL(0x30C0), -32)
	display_string("Aircraft MTOW: "..ipc.readUD(0x1334)/256, -32)
	display_string("Cloud Type: "..ipc.readUB(0x0E84), -32)
	display_string("Cloud Cover: "..ipc.readUB(0x0E85), -32)
	display_string("Cloud Icing: "..ipc.readUW(0x0E86), -32)
	display_string("Cloud Turbulence: "..ipc.readUW(0x0E88), -32)
	display_string("Precipitation Rate: "..ipc.readUB(0x04CB), -32)
	display_string("Precipitation Type: "..ipc.readUB(0x04CC), -32)
	display_string("Wind Speed: "..ipc.readUW(0x0E90).."+"..ipc.readUW(0x0E94), -32)
	display_string("Wind Direction: "..(ipc.readUW(0x0E92)*360/65536).."+"..(ipc.readUW(0x0E96)*360/65536), -32)
	display_string("Wind Turbulence: "..ipc.readUW(0x0E98), -32)
end

event.flag("read_weather")
