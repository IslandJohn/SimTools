-- Weather restrictions etc.
local cloud_type_restriction = { -- Allowed cloud types above another
	[0] = {
		[1] = true,
		[8] = true,
		[9] = true,
		[10] = true,
	},
	[1] = {
	},
	[8] = {
		[8] = true,
		[9] = true,
		[10] = true,
	},
	[9] = { 
		[9] = true,
		[10] = true,
	},
	[10] = {
		[9] = true,
		[10] = true,
	},
}
local cloud_height_restriction = { -- Minimum and maximum height of layer per type (M)
	[1] = { 100, 300 },
	[8] = { 300, 1500 },
	[9] = { 300, 3000 },
	[10] = { 5000, 10000 },
}
local prevailing_wind_direction = { -- Latitude and direction
	{ -90,  090 },
	{ -75,  090 },
	{ -60, -090 }, -- Shift winds from the north
	{ -30, -090 },
	{ -15, -270 }, -- Shift winds from the south
	{  15, -270 },
	{  30, -450 }, -- Shift winds from the north
	{  60, -450 },
	{  75, -630 }, -- Shift winds from the south
	{  90, -630 },
}
local winds_aloft_increase = { -- Latitude, minimum and maximum speed increase per 1000M (plus square root of 1KT/1000M)
	{ -90, -3, 12 },
	{ -45, -3, 15 },
	{ 0, -3, 9 },
	{ 45, -3, 15 },
	{ 90, -3, 12 },
}
local temperature_restriction = {
	-50, -3, -- Minimum at surface (C) with minimum at altitude based on lapse rate (C/1000M)
	 50, -9, -- Maximum at surface (C) with maximum at altitude based on lapse rate (C/1000M)
}
local temperature_adjustment = { -- Latitude, temperature delta per month
	{ -90, -15, -40, -60, -75, -85, -90, -90, -85, -75, -60, -40, -15, },
	{ -45, 15, 11, 5, -5, -11, -15, -15, -11, -5, 5, 11, 15, },
	{ 0, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, },
	{ 45, -15, -11, -5, 5, 11, 15, 15, 11, 5, -5, -11, -15, },
	{ 90, -90, -85, -75, -60, -40, -15, -15, -40, -60, -75, -85, -90, },
}
local month_days = {
	31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
}
local icing_maximum = rwrand(-3, 3) -- a little randomness to the icing level
local icing_minimum = rwrand(-15, -25) -- no icing below this temperature in cloud
local icing_altitude = 6000 -- no icing above this altitude

local DYNAMICS = "Dynamics"
local PRESSURE = "Pressure"
local TEMPERATURE = "Temperature"
local VISIBILITY = "Visibility"
local CLOUDS = "Clouds"
local WINDS = "Winds"

function rwgenerate(theme)
	local alt = 0
	local lat = 0
	local lon = 0
	local day = 1
	local mon = 4
	if (ipc ~= nil) then
		day = ipc.readUB(0x023D)
		mon = ipc.readUB(0x0242)
		alt = ipc.readSD(0x0020)/256
		lat = ipc.readDBL(0x6010)
		lon = ipc.readDBL(0x6018)
	end
	local w = rwnew()

	-- Dynamics
	w.uDynamics = rwround(rwrand(theme[DYNAMICS][1], theme[DYNAMICS][2]))
	
	-- Generate new pressure
	w.Press.Pressure = rwround(rwrand(theme[PRESSURE][1], theme[PRESSURE][2]) * 16)

	-- Generate new temperature (always from MSL)
	local t1 = 1
	while (t1+1 < table.getn(temperature_adjustment) and lat > temperature_adjustment[t1+1][1]) do
		t1 = t1 + 1
	end
	local t1latd = lat - temperature_adjustment[t1][1]
	local t1latr = temperature_adjustment[t1+1][1] - temperature_adjustment[t1][1]
	local t1a = temperature_adjustment[t1][mon+1]
	local t1b = temperature_adjustment[t1][(mon%12)+2]
	local t2a = temperature_adjustment[t1+1][mon+1]
	local t2b = temperature_adjustment[t1+1][(mon%12)+2]
	local tr = (day-1) / (month_days[t1]-1)
	local t1t = t1a + tr * (t1b-t1a)
	local t2t = t2a + tr * (t2b-t2a)
	local tadj = t1t + t1latd * (t2t-t1t) / t1latr
	
	w.nTempCtr = theme[TEMPERATURE][10] + 1
	
	-- Surface temperature
	local talt = 0
	local tmin = temperature_restriction[1]
	local tmax = temperature_restriction[3]
	local tday = rwrand(theme[TEMPERATURE][1], theme[TEMPERATURE][2]) + tadj
	if (tday < tmin) then
		tday = tmin
	elseif (tday > tmax) then
		tday = tmax
	end
	local tdew = tday - rwrand(theme[TEMPERATURE][3], theme[TEMPERATURE][4])
	local tlap = rwrand(theme[TEMPERATURE][6], theme[TEMPERATURE][7])
	w.Temp[1].Alt = rwround(talt)
	w.Temp[1].Day = rwround(tday)
	w.Temp[1].DewPoint = rwround(tdew)

	-- Temperature layers
	for i = 2,w.nTempCtr do
		talt = (i-1) * theme[TEMPERATURE][9] / (w.nTempCtr - 1)
		tmin = temperature_restriction[1] + talt * temperature_restriction[2] / 1000
		tmax = temperature_restriction[3] + talt * temperature_restriction[4] / 1000
		tday = w.Temp[i-1].Day + tlap * (talt - w.Temp[i-1].Alt) / 1000
		while (tday < tmin or tday > tmax) do -- get a new lapse rate is we're below/above min/max
			tlap = rwrand(theme[TEMPERATURE][6], theme[TEMPERATURE][7])
			tday = w.Temp[i-1].Day + tlap * (talt - w.Temp[i-1].Alt) / 1000
		end
		if (theme[TEMPERATURE][5] == true) then
			tdew = tday - rwrand(theme[TEMPERATURE][3], theme[TEMPERATURE][4])
		else
			tdew = tday - (w.Temp[i-1].Day - w.Temp[i-1].DewPoint)
		end
		if (false and theme[TEMPERATURE][8] == true) then
			tlap = rwrand(theme[TEMPERATURE][6], theme[TEMPERATURE][7])
		end	
		
		w.Temp[i].Alt = rwround(talt)
		w.Temp[i].Day = rwround(tday)
		w.Temp[i].DewPoint = rwround(tdew)
	end

	-- Generate new visibility
	w.nUpperVisCtr = theme[VISIBILITY][6]

	-- Surface visibility (N/A: fake because it didn't appear to "stick")
	local vlalt = -theme[VISIBILITY][5] / w.nUpperVisCtr
	local vualt = theme[VISIBILITY][5] / w.nUpperVisCtr / 2
	local vlrng = rwrand(theme[VISIBILITY][1], theme[VISIBILITY][2])
	local vurng = rwrand(theme[VISIBILITY][3], theme[VISIBILITY][4])
	if (theme[VISIBILITY][7] ~= true) then
		while (vurng < vlrng) do -- Upper visibility should not be greather than lower
			vurng = rwrand(theme[VISIBILITY][3], theme[VISIBILITY][4])
		end
	end
	local vnrng = vlrng

	w.Vis.LowerAlt = rwround(vlalt)
	w.Vis.UpperAlt = rwround(vualt)
	w.Vis.Range = rwround(vnrng * 100)

	-- Visibility layers (N/A: including real surface)
	for i = 1,w.nUpperVisCtr do
		if (i == 1) then
			vlalt = theme[VISIBILITY][5] / w.nUpperVisCtr / 2 -- N/A: can't over lap fake surface
		else
			vlalt = alt + (i-1) * (theme[VISIBILITY][5]-alt) / w.nUpperVisCtr
		end
		vualt = alt + i * (theme[VISIBILITY][5]-alt) / w.nUpperVisCtr
		vnrng = vlrng + (i-1) * (vurng - vlrng) / (w.nUpperVisCtr - 1)
		
		w.UpperVis[i].LowerAlt = rwround(vlalt)
		w.UpperVis[i].UpperAlt = rwround(vualt)
		while (rwround(vnrng * 20) % 100 == 0) do -- to avoid random METAR visibility extension
			vnrng = vnrng + rwrand(-0.5, 0.5)
		end
		w.UpperVis[i].Range = rwround(vnrng * 100)
	end

	-- Generate new clouds
	w.nCloudsCtr = table.getn(theme[CLOUDS])

	-- Cloud layers
	local cstemp = rwtemp(w, 0)
	local ccov = 0
	local calt = alt
	local chgt = 0
	local ctyp = 0
	local j = 0
	for i = 1,w.nCloudsCtr do
		local ctyn = 0
		while (cloud_type_restriction[ctyp][ctyn] == nil) do
			ctyn = theme[CLOUDS][i][1][rwround(rwrand(1, table.getn(theme[CLOUDS][i][1])))]
		end
		ctyp = ctyn
		ccov = rwround(rwrand(theme[CLOUDS][i][6], theme[CLOUDS][i][7]))
		local calo = theme[CLOUDS][i][2]
		local cahi = theme[CLOUDS][i][3]
		local cbdif = ccov - theme[CLOUDS][i][15]
		if (cbdif ~= 0 and theme[CLOUDS][i][16] ~= 0) then -- adjust cloud bases based on coverage
			if (cbdif < 0 and theme[CLOUDS][i][16] < 0) then
				calo = calo - cbdif * theme[CLOUDS][i][16]
			elseif (cbdif > 0 and theme[CLOUDS][i][16] > 0) then
				calo = calo + cbdif * theme[CLOUDS][i][16]
			end
			if (calo < 0) then
				cahi = cahi + calo
				calo = 0
			end
			if (cahi < 0) then
				cahi = 0
			end
		end
		calt = calt + rwrand(calo, cahi)
		chgt = rwrand(theme[CLOUDS][i][4], theme[CLOUDS][i][5])
		if (chgt < cloud_height_restriction[ctyp][1]) then
			chgt = cloud_height_restriction[ctyp][1]
		elseif (chgt > cloud_height_restriction[ctyp][2]) then
			chgt = cloud_height_restriction[ctyp][2]
		end
		local cbtemp = rwtemp(w, calt)
		local cttemp = rwtemp(w, calt + chgt)

		w.Cloud[i-j].Type = ctyp
		w.Cloud[i-j].LowerAlt = rwround(calt)
		w.Cloud[i-j].UpperAlt = rwround(calt + chgt)
		w.Cloud[i-j].Coverage = ccov
		w.Cloud[i-j].Turbulence = rwround(rwrand(theme[CLOUDS][i][8], theme[CLOUDS][i][9]))
		if (rwrand(1, 100) <= theme[CLOUDS][i][10]) then -- precipitation
			if (cstemp > icing_maximum or (cbtemp > icing_maximum and cttemp > icing_maximum)) then
				w.Cloud[i-j].PrecipType = 1 -- rain
			else
				w.Cloud[i-j].PrecipType = 2 -- snow
			end
			w.Cloud[i-j].PrecipRate = rwround(rwrand(theme[CLOUDS][i][11], theme[CLOUDS][i][12]) * w.Cloud[i-j].Coverage / 8)
		end
		local cbice = (cbtemp <= icing_maximum and cbtemp >= icing_minimum)
		local ctice = (cttemp <= icing_maximum and cttemp >= icing_minimum)
		if (calt < icing_altitude and (cbice or ctice)) then
			local cice = 50
			if (cbice and ctice) then
				cice = 100
			end
			if (rwrand(1, 100) <= cice) then
				w.Cloud[i-j].Icing = rwround(rwrand(theme[CLOUDS][i][13], theme[CLOUDS][i][14]) * w.Cloud[i-j].Coverage / 8)
			end
		end

		calt = calt + chgt
		if (w.Cloud[i-j].Coverage == 0) then
			w.nCloudsCtr = w.nCloudsCtr - 1;
			j = j + 1
		end
	end

	-- Generate new wind
	local w1 = 1
	while (w1+1 < table.getn(prevailing_wind_direction) and lat > prevailing_wind_direction[w1+1][1]) do
		w1 = w1 + 1
	end
	local w1latd = lat - prevailing_wind_direction[w1][1]
	local w1latr = prevailing_wind_direction[w1+1][1] - prevailing_wind_direction[w1][1]
	local w1dirl = prevailing_wind_direction[w1][2]
	local w1dird = prevailing_wind_direction[w1+1][2] - w1dirl
	local w1dirp = w1dirl + w1dird * w1latd / w1latr -- prevailing wind direction

	local w2 = 1
	while (w2+1 < table.getn(winds_aloft_increase) and lat > winds_aloft_increase[w2+1][1]) do
		w2 = w2 + 1
	end
	local w2latd = lat - winds_aloft_increase[w2][1]
	local w2latr = winds_aloft_increase[w2+1][1] - winds_aloft_increase[w2][1]
	local w2spddl = winds_aloft_increase[w2+1][2] - winds_aloft_increase[w2][2]
	local w2spddh = winds_aloft_increase[w2+1][3] - winds_aloft_increase[w2][3]
	local w2spdil = winds_aloft_increase[w2][2] + w2spddl * w2latd / w2latr -- speed change low per 1000M
	local w2spdih = winds_aloft_increase[w2][3] + w2spddh * w2latd / w2latr -- speed change high per 1000M

	-- Wind layers
	local wspdl = theme[WINDS][1]
	local wspdh = theme[WINDS][2]
	local wspd = rwrand(wspdl, wspdh)
	local wspdg = rwrand(theme[WINDS][3], theme[WINDS][4])
	if (wspd + wspdg > wspdh) then
		wspdg = wspdh - wspd
	end
	if (wspd + wspdg < wspdl) then
		wspdg = wspdl - wspd
	end
	local wspdi = rwrand(w2spdil, w2spdih)
	local wdirl = rwdeg(rwrand(w1dirp - theme[WINDS][5], w1dirp + theme[WINDS][5]))
	local wvarl = theme[WINDS][6]
	local wdirh = rwdeg(rwrand(w1dirp - theme[WINDS][7], w1dirp + theme[WINDS][7]))
	local wvarh = theme[WINDS][8]
	local wdird = rwdeg(wdirh - wdirl)
	if (wdird > 180) then
		wdird = wdird - 360
	end

	w.nWindsCtr = theme[WINDS][15] + 1
	local j = 0
	for i = 1,w.nWindsCtr do
		local wr = (i-1) / (w.nWindsCtr - 1)
		local walt = alt + wr * (theme[WINDS][14]-alt)
		if (theme[WINDS][13] == true) then
			wspdi = rwrand(w2spdil, w2spdih)
		end
		local wualt = alt + i * (theme[WINDS][14]-alt) / w.nWindsCtr
		local wualtp = wualt
		local wspdp = wspd
		if (i > 1) then
			wualtp = w.Wind[i+j-1].UpperAlt
			wspdp = w.Wind[i+j-1].Speed
		end
		local wspdn = wspdp + (wualt-wualtp)/1000 * (wspdi+math.sqrt(walt/1000))
		if (wspdn < 0) then
			wspdn = 0
		end
		local wdir = wdirl + wr * wdird
		local wvar = rwrand(0, wvarl + wr * (wvarh - wvarl))

		w.Wind[i+j].UpperAlt = rwround(wualt)
		w.Wind[i+j].Speed = rwround(wspdn)
		w.Wind[i+j].Gust = rwround(wspdg * (w.nWindsCtr - i) / (w.nWindsCtr - 1))
		w.Wind[i+j].Direction = rwround(rwdeg(wdir) * 65535 / 360)
		w.Wind[i+j].Variance = rwround(wvar * 65535 / 360)
		w.Wind[i+j].Turbulence = rwround(rwrand(theme[WINDS][9], theme[WINDS][10]))
		w.Wind[i+j].Shear = rwround(rwrand(theme[WINDS][11], theme[WINDS][12]))

		-- hack to create a gap between top of surface and next winds aloft with an ignored layer
		if (i == 1) then
			w.Wind[i+1] = deepcopy(w.Wind[i])
			w.Wind[i].UpperAlt = rwround(wualt/2)
			j = 1
		end
	end
	w.nWindsCtr = w.nWindsCtr + 1
	
	return w
end
