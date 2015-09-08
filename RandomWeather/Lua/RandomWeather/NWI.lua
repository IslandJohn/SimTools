-- NWI struct tables
local NewWind = {
	UpperAlt = 0,
	Speed = 0,
	Gust = 0,
	Direction = 0,
	Turbulence = 0,
	Shear = 0,
	Variance = 0,
	SpeedFract = 0,
	Spare = 0,
}
local NewVis = {
	UpperAlt = 0,
	LowerAlt = 0,
	Range = 0,
	Spare = 0,
}
local NewCloud = {
	UpperAlt = 0,
	LowerAlt = 0,
	Deviation = 0,
	Coverage = 0,
	Type = 0,
	Turbulence = 0,
	Icing = 0,
	PrecipBase = 0,
	PrecipType = 0,
	PrecipRate = 0,
	TopShape = 0,
	Spare = 0,
}
local NewTemp = {
	Alt = 0,
	Day = 0,
	DayNightVar = 0,
	DewPoint = 0,
}
local NewPress = {
	Pressure = 0,
	Drift = 0,
}
local NewWeather = {
	uCommand = 0,
	uFlags = 0,
	ulSignature = 0,
	chICAO = "GLOB",
	uDynamics = 0,
	uSeconds = 0,
	dLatitude = 0.0,
	dLongitude = 0.0,
	nElevation = 0,
	ulTimeStamp = 0,
	Press = deepcopy(NewPress),
	Vis = deepcopy(NewVis),
	nTempCtr = 0,
	Temp = {
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
		deepcopy(NewTemp),
	},
	nWindsCtr = 0,
	Wind = {
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
		deepcopy(NewWind),
	},
	nCloudsCtr = 0,
	Cloud = {
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
		deepcopy(NewCloud),
	},
	uSpare1 = { 0, 0, 0, 0, 0, 0 },
	nUpperVisCtr = 0,
	UpperVis = {
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
		deepcopy(NewVis),
	},
	uSpare2 = { 0, 0, 0, 0, 0, 0, 0, 0 },
}
local NW_SET = 1
local NW_SETEXACT = 2
local NW_CLEAR = 3
local NW_DYNAMICS = 4
local NW_GLOBAL = 5
local NW_ACTIVATE = 256
local NW_SET_PENDING = 257
local NW_SETEXACT_PENDING = 258

-- NWI vstruct format
local NWIvFormat = [[
	uCommand:u2
	uFlags:u2
	ulSignature:u4
	chICAO:s4
	uDynamics:u2
	uSeconds:u2
	dLatitude:f8
	dLongitude:f8
	nElevation:i4
	ulTimeStamp:u4
	Press:{
		Pressure:u2
		Drift:i2
	}
	Vis:{
		UpperAlt:u2
		LowerAlt:i2
		Range:u2
		Spare:u2
	}
	nTempCtr:i4
	Temp:{
		24*{
			Alt:u2
			Day:i2
			DayNightVar:i2
			DewPoint:i2
		}
	}
	nWindsCtr:i4
	Wind:{
		24*{
			UpperAlt:u2
			Speed:u2
			Gust:u2
			Direction:u2
			Turbulence:u1
			Shear:u1
			Variance:u2
			SpeedFract:u2
			Spare:u2
		}
	}
	nCloudsCtr:i4
	Cloud:{
		16*{
			UpperAlt:u2
			LowerAlt:u2
			Deviation:u2
			Coverage:u1
			Type:u1
			Turbulence:u1
			Icing:u1
			PrecipBase:i2
			PrecipType:u1
			PrecipRate:u1
			TopShape:u1
			Spare:u1
		}
	}
	uSpare1:{ 6*u2 }
	nUpperVisCtr:i4
	UpperVis:{
		12*{
			UpperAlt:u2
			LowerAlt:i2
			Range:u2
			Spare:u2
		}
	}
	uSpare2:{ 8*u2 }
]]

-- NWI functions
function rwnew()
	return deepcopy(NewWeather)
end

function rwbin(s)
	return vstruct.pack(NWIvFormat, s)
end

function rwstruct(b)
	return vstruct.unpack(NWIvFormat, b) 
end

function rwdynamics(rate)
	local w = rwnew()
	
	w.uCommand = NW_DYNAMICS
	w.uDynamics = rate
	ipc.writeSTR(0xC800, rwbin(w), 1024)
end

function rwclear()
	local w = rwnew()
	
	w.uCommand = NW_CLEAR
	ipc.writeSTR(0xC800, rwbin(w), 1024)
end

function rwset(w)
	w.uCommand = NW_SETEXACT
	ipc.writeSTR(0xC800, rwbin(w), 1024)
	--ipc.writeSTR(0xB000, "GLOB 000000Z 36010KT&D0500NG 27060KT&A0500NG 09030KT&A1000NG 8CU050&CU010FNVN000N 15/10&A0")
end

function rwget(icao)
	local w = rwstruct(ipc.readSTR(0xCC00, 1024))
	local t = w.ulTimeStamp
	
	w.chICAO = icao
	ipc.writeSTR(0xCC00, rwbin(w), 1024)
	
	local try = 5
	while (try > 0 and t == w.ulTimeStamp) do
		ipc.sleep(1000)
		w = rwstruct(ipc.readSTR(0xCC00, 1024))
		try = try - 1
	end
	
	if (t == w.ulTimeStamp and try == 0) then
		return nil
	end

	return w
end

function rwdump(weather)
	return DataDumper(rwstruct(rwbin(weather)), "weather = ")
end

function rwmetar(w)
	local s = ""
	
	if (w.chICAO ~= nil) then
		s = s..w.chICAO.." "
	end
	s = s..os.date("%d%H%ML")
	
	s = s.." "..string.format("%03.0f", rwround(w.Wind[1].Direction*360/65535/10)*10)
	if (w.Wind[1].Gust >= 3) then
		s = s..string.format("%02.0f", w.Wind[1].Speed)
		s = s..string.format("G%02.0f", w.Wind[1].Speed+w.Wind[1].Gust)
	else
		s = s..string.format("%02.0f", w.Wind[1].Speed+w.Wind[1].Gust/2)
	end
	s = s.."KT"
	if (w.Wind[1].Variance > 1000) then
		local d = rwround(w.Wind[1].Direction*360/65535/10)*10
		local v = rwround(w.Wind[1].Variance*360/65535/5)*5
		s = s.." "..string.format("%03.0fV%03.0f", d-v, d+v)
	end
	
	if (w.UpperVis[1].Range < 25) then
		s = s.." 1/8SM"
	elseif (w.UpperVis[1].Range < 50) then
		s = s.." 1/4SM"
	elseif (w.UpperVis[1].Range < 75) then
		s = s.." 1/2SM"
	elseif (w.UpperVis[1].Range < 100) then
		s = s.." 3/4SM"
	elseif (w.UpperVis[1].Range > 3000) then
		s = s..string.format(" %.0fSM", rwround(w.UpperVis[1].Range/1000)*10)
	elseif (w.UpperVis[1].Range > 1000) then
		s = s..string.format(" %.0fSM", rwround(w.UpperVis[1].Range/500)*5)
	else
		s = s..string.format(" %.0fSM", w.UpperVis[1].Range/100)
	end
	
	local ptyp = 0
	local prat = 0
	local thun = 0
	local covg = 0
	local clds = ""
	for i = 1,w.nCloudsCtr do
		if (covg < 9 and w.UpperVis[1].Range < 100 and w.Cloud[i].Coverage > 4 and w.Cloud[i].LowerAlt/2.54/12 < 200) then
			clds = clds.." VV001"
			covg = 9
		else
			if (w.Cloud[i].Coverage > covg) then
				if (w.Cloud[i].Coverage <= 2) then
					clds = clds.." FEW"
				elseif (w.Cloud[i].Coverage <= 4) then
					clds = clds.." SCT"
				elseif (w.Cloud[i].Coverage <= 4) then
					clds = clds.." BKN"
				else
					clds = clds.." OVC"
				end
				if (w.Cloud[i].LowerAlt/2.54/12 > 100) then
					clds = clds..string.format("%03.0f", rwround(w.Cloud[i].LowerAlt/2.54/12/10)*10)
				else
					clds = clds..string.format("%03.0f", w.Cloud[i].LowerAlt/2.54/12)
				end
				covg = w.Cloud[i].Coverage
			end
		end
		if (w.Cloud[i].Type == 10) then
			local t = rwround(w.Cloud[i].Coverage/3.333)
			if (t > thun) then
				thun = t
			end
		end
		if (ptyp == 0) then
			ptyp = w.Cloud[i].PrecipType
		end
		if (prat == 0) then
			prat = w.Cloud[i].PrecipRate
		end
	end
	if (w.nCloudsCtr == 0) then
		clds = clds.." CLR"
	end
	
	if (ptyp > 0) then
		if (prat < 2) then
			s = s.." -"
		elseif (prat > 3) then
			s = s.." +"
		else
			s = s.." "
		end
	end
	if (thun == 2) then
		if (ptyp == 1) then
			s = s.."TSRA"
		elseif (ptyp == 2) then
			s = s.."TSSN"
		else
			s = s.." TS"
		end
	else
		if (ptyp == 1) then
			s = s.."RA"
		elseif (ptyp == 2) then
			s = s.."SN"
		end
		if (thun == 1) then
			s = s.." VCTS"
		end
	end
	
	s = s..clds

	if (w.Temp[1].Day < 0) then
		s = s..string.format(" M%.0f", math.abs(w.Temp[1].Day))
	else
		s = s..string.format(" %.0f", w.Temp[1].Day)
	end
	s = s.."/"
	if (w.Temp[1].DewPoint < 0) then
		s = s..string.format("M%.0f", math.abs(w.Temp[1].DewPoint))
	else
		s = s..string.format("%.0f", w.Temp[1].DewPoint)
	end
	
	s = s..string.format(" A%.0f", w.Press.Pressure*2992/1013.25/16)
	
	return s
end

function rwtemp(w, alt)
	if (alt <= w.Temp[1].Alt) then
		return w.Temp[1].Day
	end
	if (alt >= w.Temp[w.nTempCtr].Alt) then
		return w.Temp[w.nTempCtr].Day
	end
	
	for i = 1,w.nTempCtr-1 do
		if (alt <= w.Temp[i+1].Alt) then
			local a1 = w.Temp[i].Alt
			local a2 = w.Temp[i+1].Alt 
			local ad = a2 - a1
			local t1 = w.Temp[i].Day
			local t2 = w.Temp[i+1].Day
			local td = t2 - t1
			local t = t1 + td * (alt-a1) / ad

			return t
		end
	end
	
	return 15 - 6.5 * alt / 1000 -- shouldn't happen, ISA
end

function rwwinds(w)
	local s = ""
	
	for i = 3,w.nWindsCtr do
		if (s ~= "") then
			s = s.." "
		end
		
		local alt = w.Wind[i].UpperAlt - w.Wind[2].UpperAlt
		local dir = w.Wind[i].Direction * 360 / 65535
		local spd = w.Wind[i].Speed + w.Wind[i].Gust/2
		local tmp = rwtemp(w, alt)
		
		s = s..string.format("%03.0f/", rwround(alt/2.54/12/5)*5)
		if (spd >= 99.5) then
			s = s..string.format("%02.0f%02.0f", dir/10+50, spd-100)
		else
			s = s..string.format("%02.0f%02.0f", dir/10, spd)
		end
		s = s..string.format("%+03.0f", tmp)
	end
	
	return s
end

function rwsetmetar(metar)
	ipc.writeSTR(0xB000, metar)
end

function rwgetmetar(icao)
	local w = rwstruct(ipc.readSTR(0xCC00, 1024))
	local t = w.ulTimeStamp
	
	w.chICAO = icao
	ipc.writeSTR(0xCC00, rwbin(w), 1024)
	
	local try = 5
	while (try > 0 and t == w.ulTimeStamp) do
		ipc.sleep(1000)
		w = rwstruct(ipc.readSTR(0xCC00, 1024))
		try = try - 1
	end
	
	if (t == w.ulTimeStamp and try == 0) then
		return "Failed to retrieve METAR."
	end
	
	return ipc.readSTR(0xB800, 2048)
end
