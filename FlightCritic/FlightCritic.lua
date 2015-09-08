-- Flight Critic 1.3.0
-- E-mail: pilotjohn at gearsdown.com
--
-- Script to automatically record and analyze a flight with scoring.
-- Raw data is saved in a CSV file for re-analysis through the command line.
-- Setup:
--
-- 1. Edit "FSUIPC.ini" and add (substitute X for 1 or next # if exists):
--     [Auto]
--     X=Lua FlightCritic
--
-- 2. Edit "FSUIPC.ini" and change "GetNearestAirport" to "Yes".
--
-- 3. Set "DEBUG" below to "true" if start/stop message are desired.

local DEBUG = false

local m2f = 100/2.54/12
local nm2f = 2315000/381
local r2d = 180/math.pi

local FDR = nil -- Flight Data Recorder
local FRR = 0.1 -- Flight Recording Rate (seconds)

local HWM = 0
local LWM = 0

local ONG = 1
local ELEV = 2
local GS = 3
local TAS = 4
local IAS = 5
local VS = 6
local ALT = 7
local HDG = 8
local TRK = 9
local TURN = 10
local SKID = 11
local ACX = 12
local ACY = 13
local ACZ = 14
local GW = 15
local MTOW = 16
local FLAP = 17
local VS0 = 18
local VS1 = 19
local TEXT = 20

-- ----------------------------------------------------------------------------
-- Generic helper functions

function pack(...)
	local a = {}
	for i,v in ipairs(arg) do
		table.insert(a, v)
	end
	return a
end

function mult(a, m)
	local b = {}
	for i,v in ipairs(a) do
		b[i] = v*m
	end
	return b
end

function get_limit(x, a, b)
	if (a ~= nil and x < a) then
		x = a
	end
	if (b ~= nil and x > b) then
		x = b
	end
	
	return x
end

function get_total(a, b, c)
	if (b == nil) then
		b = 1
	end
	if (c == nil) then
		c = table.getn(a)
	end
	
	local v = 0
	for i = b,c do
		v = v + a[i]
	end
	
	return v
end

function get_average(a, b, c)
	if (b == nil) then
		b = 1
	end
	if (c == nil) then
		c = table.getn(a)
	end
	
	local v = 0
	for i = b,c do
		v = v + (a[i]-v) / (i-b+1)
	end
	
	return v
end

function get_deviation(a, b, c, x)
	if (b == nil) then
		b = 1
	end
	if (c == nil) then
		c = table.getn(a)
	end
	if (x == nil) then
		x = get_average(a, b, c)
	end
	
	local v = 0
	for i = b,c do
		v = v + ((a[i]-x)^2 - v) / (i-b+1)
	end
	
	return math.sqrt(v)
end

function get_minmax_index(a, b, c)
	if (b == nil) then
		b = 1
	end
	if (c == nil) then
		c = table.getn(a)
	end
	
	local j = nil
	local k = nil
	for i = b,c do
		if (j == nil or a[i] < a[j]) then
			j = i
		end
		if (k == nil or a[i] > a[k]) then
			k = i
		end
	end
	
	return j,k
end

function get_minmax(a, b, c)
	local j,k = get_minmax_index(a, b, c)
	if (j ~= nil) then
		j = a[j]
	end
	if (k ~= nil) then
		k = a[k]
	end
	
	return j,k
end

function get_norm_deg(d)
	while (d < 0.5) do
		d = d + 360
	end
	while (d >= 360.5) do
		d = d - 360
	end
	
	return d
end

function get_diff_deg(d)
	while (d < -180) do
		d = d + 360
	end
	while (d > 180) do
		d = d - 360
	end
	
	return d
end

function get_average_deg(a, b, c)
	if (b == nil) then
		b = 1
	end
	if (c == nil) then
		c = table.getn(a)
	end
	
	local v = get_norm_deg(0)
	for i = b,c do
		v = get_norm_deg(v + get_diff_deg(get_norm_deg(a[i])-v) / (i-b+1))
	end
	
	return v
end

function get_deviation_deg(a, b, c, x)
	if (b == nil) then
		b = 1
	end
	if (c == nil) then
		c = table.getn(a)
	end
	if (x == nil) then
		x = get_average_deg(a, b, c)
	end
	x = get_norm_deg(x)
	
	local v = 0
	for i = b,c do
		v = v + (get_diff_deg(get_norm_deg(a[i])-x)^2 - v) / (i-b+1)
	end

	return math.sqrt(v)
end

function get_minmax_deg(a, z, b, c)
	if (b == nil) then
		b = 1
	end
	if (c == nil) then
		c = table.getn(a)
	end
	if (z == nil) then
		z = get_average_deg(a, b, c)
	end
	z = get_norm_deg(z)
	
	local j = 0
	local k = 0
	for i = b,c do
		local d = get_diff_deg(get_norm_deg(a[i])-z)
		if (d < j)  then
			j = d
		end
		if (d > k) then
			k = d
		end
	end
	
	return get_norm_deg(j+z), get_norm_deg(k+z)
end

-- ----------------------------------------------------------------------------
-- Specific helper functions

-- Return a value from the FDR
function get_fdr_value(i, j, fdr)
	if (fdr == nil) then
		fdr = FDR
	end
	if (i == nil) then
		i = table.getn(fdr)
	end
	
	return FDR[i][j]
end

-- Return a column from the FDR
function get_fdr_column(j, fdr)
	if (fdr == nil) then
		fdr = FDR
	end
	
	local a = {}
	for i = 1,table.getn(fdr) do
		a[i] = fdr[i][j]
	end
	
	return a
end

-- Return all rows of a given criteria
function get_fdr_rows(c, d, e, f, g, fdr)
	if (fdr == nil) then
		fdr = FDR
	end
	if (c == nil) then
		c = 1
	end
	if (d == nil) then
		d = table.getn(fdr)
	end
	
	local a = get_fdr_column(e, fdr)
	local b = {}
	for i = c,d do
		if (f <= g) then
			if (a[i] >= f and a[i] <= g) then
				table.insert(b, fdr[i])
			end
		else
			if (a[i] >= f or a[i] <= g) then
				table.insert(b, fdr[i])
			end
		end
	end
	
	return b
end

-- Return flight time between indices in seconds
function get_flight_time(i, j, fdr)
	if (fdr == nil) then
		fdr = FDR
	end
	if (i == nil) then
		i = 1
	end
	if (j == nil) then
		j = table.getn(fdr)
	end
	if (i > j) then
		return 0
	end
	
	return (j-i+1) * FRR
end

-- Return an index some seconds before or after the given index
function get_flight_index(i, t, fdr)
	if (fdr == nil) then
		fdr = FDR
	end
	if (i == nil) then
		return nil
	end
	if (t == nil or math.abs(t) < FRR) then
		return i
	end
	
	i = i + math.floor(t/FRR - (t/math.abs(t)))
	
	if (i < 1) then
		i = 1
	elseif (i > table.getn(fdr)) then
		i = table.getn(fdr)
	end
	
	return i
end

-- Return takeoff ground roll end index
function get_takeoff_index(fdr)
	local a = get_fdr_column(ONG, fdr)
	local n = table.getn(a)
	local i = 1
	local t = 1/FRR -- assume at least 1 second of ground time before recording start
	
	-- find the first index where there's twice the air time than ground time
	while (t >= 0 and i <= n) do
		if (a[i] == 0) then
			t = t - 1
		else
			t = t + 2
		end
		i = i + 1
	end
	
	if (i > n) then
		return nil
	end
	
	-- find the last ground contact index before the index from above
	while (a[i] == 0 and i > 0) do
		i = i - 1
	end
	
	if (i < 1) then
		return nil
	end
	
	return i
end

-- Return takeoff to feet end index given ground roll end index
function get_takeoff_to_index(x, i, fdr)
	if (i == nil) then
		i = get_takeoff_index(fdr)
	end
	if (i == nil) then
		return nil
	end
	if (x == nil or x <= 0) then
		return i
	end
	
	local a = get_fdr_column(ALT, fdr)
	local n = table.getn(a)
	local j = i
	while (j < n and a[j+1] <= a[i]+x) do
		j = j + 1
	end
	
	if (j >= n) then
		return nil
	end
	
	return j
end

-- Return landing ground roll begin index
function get_landing_index(fdr)
	local a = get_fdr_column(ONG, fdr)
	local n = table.getn(a)
	local i = n
	local t = 1/FRR -- assume at least 1 second of ground time after recording stop
	
	-- find the last index where there's twice the air time than ground time
	while (t >= 0 and i >= 1) do
		if (a[i] == 0) then
			t = t - 1
		else
			t = t + 2
		end
		i = i - 1
	end
	
	if (i < 1) then
		return nil
	end
	
	-- find the first ground contact index after the index from above
	while (a[i] == 0 and i <= n) do
		i = i + 1
	end
	
	if (i > n) then
		return nil
	end
	
	return i
end

-- Return landing from feet begin index given ground roll begin index
function get_landing_from_index(x, i, fdr)
	if (i == nil) then
		i = get_landing_index(fdr)
	end
	if (i == nil) then
		return nil
	end
	if (x == nil or x <= 0) then
		return i
	end
	
	local a = get_fdr_column(ALT, fdr)
	local j = i
	while (j > 1 and a[j-1] <= a[i]+x) do
		j = j - 1
	end
	
	if (j <= 1) then
		return nil
	end
	
	return j
end

-- ----------------------------------------------------------------------------
-- Flight recording functions

function start()
	if (ipc ~= nil) then
		if (DEBUG == true) then
			ipc.lineDisplay("")
			ipc.display("Flight Critic\nStarting...", 3)
		else
			ipc.lineDisplay("")
			ipc.display("")
		end
	end
	
	FDR = {}
end

function record(ong, gs, vs, extra)
	local data = {
		ong, -- on ground
		ipc.readSD(0x0020)/256 * m2f, -- elevation
		gs, -- gs
		ipc.readSD(0x02B8)/128, -- tas
		ipc.readSD(0x02BC)/128, -- ias
		vs,
		(ipc.readSD(0x0574) + ipc.readUD(0x0570)/4294967296) * m2f, -- altitude
		ipc.readSD(0x0580)*360/4294967296 - ipc.readSW(0x02A0)*360/65536, -- heading
		ipc.readDBL(0x6040)*r2d, -- track
		ipc.readFLT(0x0384), -- turn
		ipc.readFLT(0x0380), -- skid
		ipc.readDBL(0x31C0), -- wxa
		ipc.readDBL(0x31C8), -- wya
		ipc.readDBL(0x31D0), -- wza
	}
	if (extra ~= nil) then	
		for i = 1,#extra do
			data[#data+1] = extra[i]
		end
	end
	
	for i = 1,math.floor(ipc.readUW(0x0C1A)/256+0.5) do -- rate
		table.insert(FDR, data)
	end
end

function stop()
	if (ipc ~= nil) then
		local vs0 = ipc.readDBL(0x0538)*3600/nm2f
		local vs1 = ipc.readDBL(0x0540)*3600/nm2f
		local vno = ipc.readDBL(0x0548)*3600/nm2f
		local vld = ipc.readDBL(0x0550)*3600/nm2f
		
		if (vs1 > 15 and vs1 < 60) then
			HWM = vs1*0.5
		else
			HWM = 30
		end
		LWM = HWM*0.5

		if (DEBUG == true) then
			ipc.lineDisplay(string.format("Stopped, LWM/HWM = %.0f/%.0f.", LWM, HWM), -32)
		end
	end

	FDR = nil
end

-- ----------------------------------------------------------------------------
-- Flight analysis function

function format_time(t)
	local s = "n/a"
	if (t ~= nil) then
		s = string.format("%02d:%02d:%02d", t/3600, t%3600/60, t%60)
	end
	return s
end

function format_speed(v, u)
	local s = "n/a"
	if (string.sub(u, 1, 1) == "k") then
		s = string.format("%.0f%s", v, u)
	elseif (string.sub(u, 1, 1) == "f") then
		s = string.format("%+.0f%s", v, u)
	end
	return s
end

function format_distance(d)
	local s = "n/a"
	if (d ~= nil) then
		if (d >= 999.95*nm2f) then
			s = string.format("%.0fnm", d/nm2f)
		elseif (d >= 9999.5) then
			s = string.format("%.1fnm", d/nm2f)
		else
			s = string.format("%.0fft", d)
		end
	end
	return s
end

function format_altitude(a)
	local s = "n/a"
	if (a ~= nil) then
		s = string.format("%.0fft", a)
	end
	return s
end

function format_output(o)
	if (ipc ~= nil) then
		if (DEBUG == true) then
			ipc.lineDisplay("Analyzing... "..table.getn(FDR).." records.", -32)
		else
			ipc.lineDisplay("")
		end
		
		for i,v in ipairs(o) do
			ipc.lineDisplay(v, -32)
		end
	else
		for i,v in ipairs(o) do
			print(v)
		end
	end
end

function dist_score(x) -- modify score distribution (pseudo Gaussian looking curve using x^2)
	if (x == nil) then
		return nil
	end
	
	local y = 2 * get_limit(x, 0, 1) - 1
	if (y == 0) then
		y = 0.5
	else
		y = y/math.abs(y) * (y^2)/2 + 0.5
	end

	return y
end

function dist_score_maybe(x) -- modify score distribution (pseudo Gaussian looking curve using cos)
	if (x == nil) then
		return nil
	end
	
	local y = math.cos(math.pi * (get_limit(x, 0, 1)-0.5))/2
	if (x > 0.5) then
		y = 1-y
	end

	return y
end

function make_score(x)
	--local y = dist_score(1 - get_limit(x, 0, 1))
	local y = 1 - get_limit(x, 0, 1)
	return y
end

-- average scores weighted by significance, and return it and it's offsets 
function substract_scores(a)
	-- map values to indices
	local b = {}
	for i = 1,table.getn(a) do
		if (a[i] ~= nil and tostring(a[i]) ~= "nan") then
			if (b[a[i]] == nil) then
				b[a[i]] = {}
			end
			table.insert(b[a[i]], i)
		end
	end
	
	-- sort data for significance
	table.sort(a, function(x,y)
		if ((x == nil or tostring(x) == "nan") and (y == nil or tostring(y) == "nan")) then
			return false
		elseif (x == nil or tostring(x) == "nan") then
			return true
		elseif (y == nil or tostring(y) == "nan") then
			return false
		else
			return x<y
		end
	end)

	-- calculate weight distribution
	local j = 0
	local n = 0
	for i = 1,table.getn(a) do
		if (a[i] ~= nil and tostring(a[i]) ~= "nan") then
			--n = n + 1/(i-j)
			n = n + 1--/(2^(i-j-1))
		else
			j = j + 1
		end
	end
	
	local j = 0
	local v = 1 -- average
	local c = {} -- deductions
	local w = 1;
	for i = 1,table.getn(a) do
		if (a[i] ~= nil and tostring(a[i]) ~= "nan") then
			--local w = 1 / n / (i-j) -- weight
			--local w = 1-- / n / (2^(i-j-1)) -- weight
			local k = table.remove(b[a[i]], 1) -- value index for deductions
			local x = get_limit(a[i], 0, 1)

			v = v - w*(1-x)
			c[k] = w*(1-x)
			w = w / 2;
		else
			j = j + 1
		end
	end

	if (v < 0) then
		v = 0
	end
	return v, unpack(c)
end

function skid_adjust(s)
	--return get_limit(s, -1, 1)
	return 1 - math.cos(get_limit(s, -1, 1) * math.pi/2)
end

function get_stall(i)
	local gw = get_fdr_value(i, GW)
	local mtow = get_fdr_value(i, MTOW)
	local flap = get_fdr_value(i, FLAP)
	local vs0 = get_fdr_value(i, VS0)
	local vs1 = get_fdr_value(i, VS1)
	
	return math.sqrt(gw/mtow) * (vs1 - math.sqrt(flap)*(vs1-vs0))
end

function analyze()
	local output = {}
	
	if (FDR == nil) then
		return
	end
	
	if (ipc ~= nil) then
		local f = assert(io.open("FlightCritic_"..os.date("%Y%m%d_%H%M%S")..".csv", "w"))
		local t = f:write("ong,elev,gs,tas,ias,vs,alt,hdg,trk,turn,skid,acx,acy,acz,gw,mtow,flap,vs0,vs1,text\n")
		for i=1,table.getn(FDR) do
			local s = ""
			for j=1,table.getn(FDR[i]) do
				if (j > 1) then
					s = s..","
				end
				if (FDR[i][j] ~= nil) then
					s = s..FDR[i][j]
				end
			end
			t = f:write(s.."\n")
		end
		f:close()
	end
	
	if (DEBUG == true) then
		print("Analyzing... "..table.getn(FDR).." records.")
	end

	local air = get_fdr_rows(nil, nil, ONG, 0, 0)
	local gnd = get_fdr_rows(nil, nil, ONG, 1, 1)
	local ftime = get_flight_time(nil, nil, air)
	local fdist = get_total(get_fdr_column(GS, air))*FRR
	local fspd = 0
	if (ftime > 0) then
		fspd = fdist/ftime
	end
	
	table.insert(output, "In Flight: "
	  ..format_time(ftime)..", "
	  ..format_distance(fdist/3600*nm2f)..", "
	  ..format_speed(fspd, "kts"))
	table.insert(output, " ")

	local to = get_takeoff_index()
	local to35 = get_takeoff_to_index(35, to)
	local to50 = get_takeoff_to_index(50, to)
	
	local ldg = get_landing_index()
	local ldg35 = get_landing_from_index(35, ldg)
	local ldg50 = get_landing_from_index(50, ldg)

	local apr = nil
	if (ldg50 ~= nil) then
		apr = get_flight_index(ldg50-1, -60)
		if ((to ~= nil and apr <= to) or (to35 ~= nil and apr <= to35) or (to50 ~= nil and apr <= to50)) then
			apr = nil
		end
	end

	local fdrong = get_fdr_column(ONG)
	local fdrelev = get_fdr_column(ELEV)
	local fdrgs = get_fdr_column(GS)
	local fdrtas = get_fdr_column(TAS)
	local fdrias = get_fdr_column(IAS)
	local fdrvs = get_fdr_column(VS)
	local fdralt = get_fdr_column(ALT)
	local fdrhdg = get_fdr_column(HDG)
	local fdrtrk = get_fdr_column(TRK)
	local fdrskid = get_fdr_column(SKID)
	local fdrrate = get_fdr_column(TURN)
	local fdracx = get_fdr_column(ACX)
	local fdracy = get_fdr_column(ACY)
	local fdracz = get_fdr_column(ACZ)
	local fdragl = {}
	for i = 1,table.getn(fdrelev) do
		fdragl[i] = fdralt[i] - fdrelev[i]
	end

	-- Takeoff/Rotation
	local tc, ts = {}, {}
	if (to ~= nil) then
		local tleave = 1.25*get_stall(1)
		local ttext = get_fdr_value(1, TEXT)
		if (ttext == nil) then
			ttext = ""
		else
			ttext = ttext..", "
		end
		ttext = ttext
		  ..string.format("%.0flbs", get_fdr_value(1, GW))..", "
		  ..string.format("%.0f%%", get_fdr_value(1, FLAP)*100)..", "
		  ..format_speed(get_stall(1), "kias")
		  
		table.insert(output, "    Takeoff/Rotation ("..ttext..")")
		
		local to1 = get_fdr_value(1, GS)
		local to2 = get_fdr_value(to, GS)
		local toa = (to2-to1) / get_flight_time(1, to)
		local tot = to1/toa -- projected takeoff time before recording start
		local tod = 0.5*toa*tot*tot/3600*nm2f -- projected takeoff distance before recording start
		
		table.insert(output, "        Ground Roll: "
		  ..format_time(get_flight_time(1, to) + tot)..", "
		  ..format_distance(get_total(fdrgs, 1, to)/3600*nm2f*FRR + tod)..", "
		  ..string.format("%.0f(%+.0f)kias", fdrias[to], fdrias[to]-tleave))
		
		if (to35 ~= nil) then
			table.insert(output, "        To 35 Feet: "
			  ..format_time(get_flight_time(1, to35) + tot)..", "
			  ..format_distance(get_total(fdrgs, 1, to35)/3600*nm2f*FRR + tod)..", "
			  ..format_speed(fdrias[to35], "kias"))
		end
		
		if (to50 ~= nil) then
			table.insert(output, "        To 50 Feet: "
			  ..format_time(get_flight_time(1, to50) + tot)..", "
			  ..format_distance(get_total(fdrgs, 1, to50)/3600*nm2f*FRR + tod)..", "
			  ..format_speed(fdrias[to50], "kias"))
		end
		
		if (to50 ~= nil) then
			-- Score components
			local tvstime = 0
			local tvssink = 0
			for i = 2,to50 do
				if (fdrong[i] == 0) then
					tvstime = tvstime + 1
					if (fdralt[i] <= fdralt[i-1]) then
						tvssink = tvssink + 1
					end
				end
			end
			local thdgnow = get_norm_deg(fdrhdg[to])
			local ttrknow = get_norm_deg(fdrtrk[to])
			local thdgavg = get_average_deg(fdrhdg, 1, to)
			local ttrkavg = get_average_deg(fdrtrk, 1, to)
			local ttrkdev = get_limit(get_deviation_deg(fdrtrk, 1, to, ttrkavg), 0, 45)
			
			local tongavg = get_average(fdrong, 1, to)
			local tskdavg = get_average(fdrskid, 1, to)
			local tskddev = get_deviation(fdrskid, 1, to, tskdavg)
			local tacxavg = get_average(fdracx, 1, to)
			local tacxdev = get_deviation(fdracx, 1, to, tacxavg)
			local tacyavg = get_average(fdracy, 1, to)
			local tacydev = get_deviation(fdracy, 1, to, tacyavg)
			local taczavg = get_average(fdracz, 1, to)
			local taczdev = get_deviation(fdracz, 1, to, taczavg)
			
			to1 = 1
			to2 = to
			if (to50 ~= nil) then
				to1 = to + 1
				to2 = to50
			elseif (to35 ~= nil) then
				to1 = to + 1
				to2 = to35
			end

			local t2trkavg = get_average_deg(fdrtrk, to1, to2)
			local t2trkdev = get_limit(get_deviation_deg(fdrhdg, to1, to2, t2trkavg), 0, 45)
			
			local t2skdavg = get_average(fdrskid, to1, to2)
			local t2skddev = get_deviation(fdrskid, to1, to2, t2skdavg)
			local t2acxavg = get_average(fdracx, to1, to2)
			local t2acxdev = get_deviation(fdracx, to1, to2, t2acxavg)
			local t2acyavg = get_average(fdracy, to1, to2)
			local t2acydev = get_deviation(fdracy, to1, to2, t2acyavg)
			local t2aczavg = get_average(fdracz, to1, to2)
			local t2aczdev = get_deviation(fdracz, to1, to2, t2aczavg)
			
			-- Comfort scores
			local tcong = get_average{make_score(1-tongavg)}
			local tcskd = get_average{make_score(skid_adjust(tskdavg)), make_score(skid_adjust(tskddev)), make_score(skid_adjust(t2skdavg)), make_score(skid_adjust(t2skddev))}
			local tcacx = get_average{make_score(math.abs(tacxavg)/32), make_score(tacxdev/32), make_score(math.abs(t2acxavg)/32), make_score(t2acxdev/32)}
			local tcacy = get_average{make_score(math.abs(tacyavg)/32), make_score(tacydev/32), make_score(math.abs(t2acyavg)/32), make_score(t2acydev/32)}
			local tcacz = get_average{make_score(math.abs(taczavg)/32), make_score(taczdev/32), make_score(math.abs(t2aczavg)/32), make_score(t2aczdev/32)}

			-- Skill scores
			local thtnow = get_limit(get_diff_deg(math.abs(thdgnow-ttrknow)), -45, 45)
			local thtavg = get_limit(get_diff_deg(math.abs(thdgavg-ttrkavg)), -45, 45)
			local tttavg = get_limit(get_diff_deg(math.abs(ttrkavg-t2trkavg)), -45, 45)
			--print(get_stall(1))
			--print(tleave)
			
			local tsias = get_average{make_score(math.abs(fdrias[to]-tleave)/math.max(tleave, fdrias[to]))}
			local tssnk = get_average{make_score(tvssink/tvstime)}
			local tshtd = get_average{make_score(math.sin(thtnow*2/r2d)), make_score(math.sin(thtavg*2/r2d))}
			local tstrk = get_average{make_score(math.sin(ttrkdev*2/r2d)), make_score(math.sin(t2trkdev*2/r2d)), make_score(math.sin(tttavg*2/r2d))}
			local tsskd = get_average{make_score(skid_adjust(tskdavg)), make_score(skid_adjust(tskddev)), make_score(skid_adjust(t2skdavg)), make_score(skid_adjust(t2skddev))}

			tc = pack(substract_scores{tcong, tcskd, tcacx, tcacy, tcacz})
			ts = pack(substract_scores{tsias, tssnk, tshtd, tstrk, tsskd})

			table.insert(output, "        Comfort: "..string.format("%.0f%% (R=%.0f%%, S=%.0f%%, X=%.0f%%, Y=%.0f%%, Z=%.0f%%)", unpack(mult(tc, 100))))
			table.insert(output, "        Skill: "..string.format("%.0f%% (I=%.0f%%, B=%.0f%%, H=%.0f%%, T=%.0f%%, S=%.0f%%)", unpack(mult(ts, 100))))
		end

		table.insert(output, " ")
	end
		
	-- Climb/Enroute/Descent
	local ec, es = {}, {}
	if (to50 ~= nil and apr ~= nil and apr-1 >= to50+1) then
		local iasmin, iasmax = get_minmax(fdrias, to50+1, apr-1)
		local tasmin, tasmax = get_minmax(fdrtas, to50+1, apr-1)
		local gsmin, gsmax = get_minmax(fdrgs, to50+1, apr-1)
		local vsmin, vsmax = get_minmax(fdrvs, to50+1, apr-1)
		local altmin, altmax = get_minmax(fdralt, to50+1, apr-1)

		local eskdavg = get_average(fdrskid, to50+1, apr-1)
		local eskddev = get_deviation(fdrskid, to50+1, apr-1, eskdavg)
		local eacxavg = get_average(fdracx, to50+1, apr-1)
		local eacxdev = get_deviation(fdracx, to50+1, apr-1, eacxavg)
		local eacyavg = get_average(fdracy, to50+1, apr-1)
		local eacydev = get_deviation(fdracy, to50+1, apr-1, eacyavg)
		local eaczavg = get_average(fdracz, to50+1, apr-1)
		local eaczdev = get_deviation(fdracz, to50+1, apr-1, eaczavg)

		-- Comfort components
		local ecskd = get_average{make_score(skid_adjust(eskdavg)), make_score(skid_adjust(eskddev))}
		local ecacx = get_average{make_score(math.abs(eacxavg)/32), make_score(eacxdev/32)}
		local ecacy = get_average{make_score(math.abs(eacyavg)/32), make_score(eacydev/32)}
		local ecacz = get_average{make_score(math.abs(eaczavg)/32), make_score(eaczdev/32)}

		-- Skill components
		local esskd = get_average{make_score(skid_adjust(eskdavg)), make_score(skid_adjust(eskddev))}
		local minseg = 15
		local minvs = 100
		local minslope = math.tan(1.5/r2d) -- +/- enroute slope
		local esvgs = {} -- vgs scores
		local esias = {} -- ias scores
		local eseg = "" -- segments
		if ((apr-1)-(to50+1) >= minseg/FRR) then
			local fdrvgs = {}
			for i = to50+1,apr-1 do
				fdrvgs[i] = fdrvs[i] / (fdrgs[i]*nm2f/60)
			end

			-- figure out climb/descent/enroute segments and score them
			local i = to50+1
			while (i <= apr-1) do
				local j, k

				-- Ground
				j = 0
				while (i+j <= apr-1 and fdrong[i+j] == 1) do
				end
				if (j > 0) then
					eseg = eseg.."G"

					i = i + j
				end
				
				-- Climb
				j, k = 0, 0
				while (i+j <= apr-1 and fdrong[i+j] == 0 and j-k >= k and k < minseg/FRR) do
					if (fdrvs[i+j]/fdrgs[i+j]/nm2f*60 < minslope) then
						k = k + 1
					else
						k = 0
					end
					j = j + 1
				end
				if (j-k >= k) then
					if (k >= minseg/FRR) then
						j = j - k
					end
					if (j >= minseg/FRR) then
						local iasavg = get_average(fdrias, i, i+j-1)
						local iasdev = get_deviation(fdrias, i, i+j-1, iasavg)
						local vgsavg = get_average(fdrvgs, i, i+j-1)
						local vgsdev = get_deviation(fdrvgs, i, i+j-1, vgsavg)

						table.insert(esias, make_score(iasdev/iasavg))
						--table.insert(esvgs, make_score(vgsdev/math.abs(vgsavg)))

						eseg = eseg.."C"
						if (ipc == nil and DEBUG == true) then
							print(string.format("C %s (%d..%d) %d+/-%dkias %.1f+/-%.1fdeg (%d%%, %d%%)",
								format_time(get_flight_time(i, i+j-1)), i, i+j-1, iasavg, iasdev, math.atan(vgsavg)*r2d, math.atan(vgsdev)*r2d, esias[#esias]*100, esvgs[#esvgs]*100))
						end
					end
					
					i = i + j
				elseif (j-k > 0 and j-k < minseg/FRR) then -- ignore segment
					if (ipc == nil and DEBUG == true) then
						print(string.format("C %s (%d..%d)", format_time(get_flight_time(i, i+j-k-1)), i, i+j-k-1))
					end
					i = i + j - k
				end

				-- Enroute
				j, k = 0, 0
				while (i+j <= apr-1 and fdrong[i+j] == 0 and j-k >= k and k < minseg/FRR) do
					if (fdrvs[i+j]/fdrgs[i+j]/nm2f*60 <= -minslope or fdrvs[i+j]/fdrgs[i+j]/nm2f*60 >= minslope) then
						k = k + 1
					else
						k = 0
					end
					j = j + 1
				end
				if (j-k >= k) then
					if (k >= minseg/FRR) then
						j = j - k
					end
					if (j >= minseg/FRR) then
						local gsavg = get_average(fdrgs, i, i+j-1)
						local gsdev = get_deviation(fdrgs, i, i+j-1, iasavg)
						local iasavg = get_average(fdrias, i, i+j-1)
						local iasdev = get_deviation(fdrias, i, i+j-1, iasavg)
						local vgsavg = get_average(fdrvgs, i, i+j-1)
						local vgsdev = get_deviation(fdrvgs, i, i+j-1, vgsavg)
						local altavg = get_average(fdralt, i, i+j-1)
						local altdev = get_deviation(fdralt, i, i+j-1, altavg)

						table.insert(esias, make_score(iasdev/iasavg))
						table.insert(esvgs, pack(get_average{make_score(math.abs(vgsavg)/minslope), make_score(vgsdev/minslope)})[1])
						
						eseg = eseg.."E"
						if (ipc == nil and DEBUG == true) then
							print(string.format("E %s (%d..%d) %d+/-%dkts %d+/-%dkias %.1f+/-%.1fdeg %d+/-%dft (%d%%, %d%%)",
								format_time(get_flight_time(i, i+j-1)), i, i+j-1, gsavg, gsdev, iasavg, iasdev, math.atan(math.abs(vgsavg))*r2d, math.atan(vgsdev)*r2d, altavg, altdev, esias[#esias]*100, esvgs[#esvgs]*100))
						end
					end
					
					i = i + j
				elseif (j-k > 0 and j-k < minseg/FRR) then -- ignore segment
					if (ipc == nil and DEBUG == true) then
						print(string.format("E %s (%d..%d)", format_time(get_flight_time(i, i+j-k-1)), i, i+j-k-1))
					end
					i = i + j - k
				end
				
				-- Descent
				j, k = 0, 0
				while (i+j <= apr-1 and fdrong[i+j] == 0 and j-k >= k and k < minseg/FRR) do
					if (fdrvs[i+j]/fdrgs[i+j]/nm2f*60 > -minslope) then
						k = k + 1
					else
						k = 0
					end
					j = j + 1
				end
				if (j-k >= k) then
					if (k >= minseg/FRR) then
						j = j - k
					end
					if (j >= minseg/FRR) then
						local iasavg = get_average(fdrias, i, i+j-1)
						local iasdev = get_deviation(fdrias, i, i+j-1, iasavg)
						local vgsavg = get_average(fdrvgs, i, i+j-1)
						local vgsdev = get_deviation(fdrvgs, i, i+j-1, vgsavg)
						
						--table.insert(esias, make_score(iasdev/iasavg))
						table.insert(esvgs, make_score(vgsdev/math.abs(vgsavg)))
						
						eseg = eseg.."D"
						if (ipc == nil and DEBUG == true) then
							print(string.format("D %s (%d..%d) %d+/-%dkias %.1f+/-%.1fdeg (%d%%, %d%%)",
								format_time(get_flight_time(i, i+j-1)), i, i+j-1, iasavg, iasdev, math.atan(math.abs(vgsavg))*r2d, math.atan(vgsdev)*r2d, esias[#esias]*100, esvgs[#esvgs]*100))
						end
					end
					
					i = i + j
				elseif (j-k > 0 and j-k < minseg/FRR) then -- ignore segment
					if (ipc == nil and DEBUG == true) then
						print(string.format("D %s (%d..%d)", format_time(get_flight_time(i, i+j-k-1)), i, i+j-k-1))
					end
					i = i + j - k
				end
			end
		end
		
		if (#eseg > 0) then
			table.insert(output, "    Climb/Enroute/Descent ("..eseg..")")
		else
			table.insert(output, "    Climb/Enroute/Descent")
		end
		table.insert(output, "        Min./Max. IAS: "..format_speed(iasmin, "kias")..", "..format_speed(iasmax, "kias"))
		table.insert(output, "        Min./Max. TAS: "..format_speed(tasmin, "ktas")..", "..format_speed(tasmax, "ktas"))
		table.insert(output, "        Min./Max. GS: "..format_speed(gsmin, "kts")..", "..format_speed(gsmax, "kts"))
		table.insert(output, "        Min./Max. VS: "..format_speed(vsmin, "fpm")..", "..format_speed(vsmax, "fpm"))
		table.insert(output, "        Min./Max. Altitude: "..format_altitude(altmin)..", "..format_altitude(altmax))
		
		ec = pack(substract_scores{ecskd, ecacx, ecacy, ecacz})
		
		table.insert(output, "        Comfort: "..string.format("%.0f%% (S=%.0f%%, X=%.0f%%, Y=%.0f%%, Z=%.0f%%)", unpack(mult(ec, 100))))
		
		if (#esvgs > 0 and #esias > 0) then
			esvgs = get_average(esvgs)
			esias = get_average(esias)
			es = pack(substract_scores{esias, esvgs, esskd})
			
			table.insert(output, "        Skill: "..string.format("%.0f%% (I=%.0f%%, A=%.0f%%, S=%.0f%%)", unpack(mult(es, 100))))
		end
		
		table.insert(output, " ")
	end
	
	-- Approach
	local ac, as = {}, {}
	if (ldg50 ~= nil and apr ~= nil) then
		table.insert(output, "    Approach")

		local fdrvgs = {}
		for i = apr,ldg50-1 do
			fdrvgs[i-apr+1] = fdrvs[i] / (fdrgs[i]*nm2f/60)
		end
		local adist = get_total(fdrgs, apr, ldg50-1)/3600*nm2f*FRR
		local aaltd = fdralt[apr] - fdralt[ldg50-1]
		local apath = math.atan2(aaltd, adist)*r2d
		
		local agsavg = get_average(fdrgs, apr, ldg50-1)
		local aiasavg = get_average(fdrias, apr, ldg50-1)
		local aiasdev = get_deviation(fdrias, apr, ldg50-1, aiasavg)
		local avsiavg = get_average(fdrvs, apr, ldg50-1)
		local avsidev = get_deviation(fdrvs, apr, ldg50-1, avsiavg)
		local avgsavg = get_average(fdrvgs)
		local avgsdev = get_deviation(fdrvgs, nil, nil, avgsavg)
		local atrkavg = get_average_deg(fdrtrk, apr, ldg50-1)
		local atrkdev = get_limit(get_deviation_deg(fdrtrk, apr, ldg50-1, atrkavg), 0, 45)

		local askdavg = get_average(fdrskid, apr, ldg50-1)
		local askddev = get_deviation(fdrskid, apr, ldg50-1, askdavg)
		local aacxavg = get_average(fdracx, apr, ldg50-1)
		local aacxdev = get_deviation(fdracx, apr, ldg50-1, aacxavg)
		local aacyavg = get_average(fdracy, apr, ldg50-1)
		local aacydev = get_deviation(fdracy, apr, ldg50-1, aacyavg)
		local aaczavg = get_average(fdracz, apr, ldg50-1)
		local aaczdev = get_deviation(fdracz, apr, ldg50-1, aaczavg)

		table.insert(output, "        Path: "
		  ..format_speed(aiasavg, "kias")..", "
		  ..format_speed(agsavg, "kts")..", "
		  ..format_speed(avsiavg, "fpm")..", "
		  ..string.format("%.1fdeg", apath))

		local acskd = get_average{make_score(skid_adjust(askdavg)), make_score(skid_adjust(askddev))}
		local acacx = get_average{make_score(math.abs(aacxavg)/32), make_score(aacxdev/32)}
		local acacy = get_average{make_score(math.abs(aacyavg)/32), make_score(aacydev/32)}
		local acacz = get_average{make_score(math.abs(aaczavg)/32), make_score(aaczdev/32)}

		local asias = get_average{make_score(aiasdev/math.abs(aiasavg))}
		local asvgs = get_average{make_score(avgsdev/math.abs(avgsavg))}
		local astrk = get_average{make_score(math.sin(atrkdev*2/r2d))}
		local asskd = get_average{make_score(skid_adjust(askdavg)), make_score(skid_adjust(askddev))}

		ac = pack(substract_scores{acskd, acacx, acacy, acacz})
		as = pack(substract_scores{asias, asvgs, astrk, asskd})

		table.insert(output, "        Comfort: "..string.format("%.0f%% (S=%.0f%%, X=%.0f%%, Y=%.0f%%, Z=%.0f%%)", unpack(mult(ac, 100))))
		table.insert(output, "        Skill: "..string.format("%.0f%% (I=%.0f%%, A=%.0f%%, T=%.0f%%, S=%.0f%%)", unpack(mult(as, 100))))
		table.insert(output, " ")
	end
	
	-- Landing/Flare
	local lc, ls = {}, {}
	if (ldg ~= nil) then
		local ltext = get_fdr_value(nil, TEXT)
		if (ltext == nil) then
			ltext = ""
		else
			ltext = ltext..", "
		end
		ltext = ltext
		  ..string.format("%.0flbs", get_fdr_value(nil, GW))..", "
		  ..string.format("%.0f%%", get_fdr_value(nil, FLAP)*100)..", "
		  ..format_speed(get_stall(nil), "kias")

		table.insert(output, "    Landing/Flare ("..ltext..")")

		local ldg1 = get_fdr_value(ldg, GS)
		local ldg2 = get_fdr_value(nil, GS)
		local ldga = (ldg1-ldg2) / get_flight_time(ldg, nil)
		local ldgt = ldg2/ldga
		local ldgd = 0.5*ldga*ldgt*ldgt/3600*nm2f -- projected landing distance after recording stop
		
		if (ldg50 ~= nil) then
			table.insert(output, "        From 50 Feet: "
			  ..format_time(get_flight_time(ldg50, nil) + ldgt)..", "
			  ..format_distance(get_total(fdrgs, ldg50, nil)/3600*nm2f*FRR + ldgd)..", "
			  ..format_speed(fdrias[ldg50], "kias"))
		end

		if (ldg35 ~= nil) then
			table.insert(output, "        From 35 Feet: "
			  ..format_time(get_flight_time(ldg35, nil) + ldgt)..", "
			  ..format_distance(get_total(fdrgs, ldg35, nil)/3600*nm2f*FRR + ldgd)..", "
			  ..format_speed(fdrias[ldg35], "kias"))
		end

		-- crazy stuff to try to figure out the real VS
		local lvsmin,lvsmax = get_minmax(fdrvs, ldg, nil)
		local lvsnow1 = get_average(fdragl, ldg-1/FRR*2, ldg-1) - get_average(fdragl, ldg-1/FRR*2-1, ldg-2) -- VS using last two seconds altitude average
		local lvsnow2 = get_average(fdragl, ldg-1/FRR*1, ldg-1) - get_average(fdragl, ldg-1/FRR*1-1, ldg-2) -- VS using last second altitude average
		local lvsnow3 = get_average(fdragl, ldg-1/FRR/2, ldg-1) - get_average(fdragl, ldg-1/FRR/2-1, ldg-2) -- VS using last half second altitude average
		local lvsnow12 = lvsnow2 + (lvsnow2-lvsnow1) -- instantenous VS based on the acceleration between averages
		local lvsnow23 = lvsnow3 + (lvsnow3-lvsnow2) -- instantenous VS based on the acceleration between averages
		local lvsnow = (lvsnow12+lvsnow23) / 2 -- average of the two instantaneous VS values
		for i = ldg,table.getn(fdragl) do
			local v1 = get_average(fdragl, i-1/FRR*2+1, i) - get_average(fdragl, i-1/FRR*2, i-1)
			local v2 = get_average(fdragl, i-1/FRR*1+1, i) - get_average(fdragl, i-1/FRR*1, i-1)
			local v3 = get_average(fdragl, i-1/FRR/2+1, i) - get_average(fdragl, i-1/FRR/2, i-1)
			local v12 = v2 + (v2-v1)
			local v23 = v3 + (v3-v2)
			local v = (v12+v23) / 2
			if (v < lvsnow) then
				lvsnow = v
			end
		end
		lvsnow = lvsnow*60/FRR

		local ltouch = (1 + 0.25*get_limit(get_fdr_value(nil, MTOW)/12500, 0, 1)) * get_stall(nil)
		table.insert(output, "        Ground Roll: "
		  ..format_time(get_flight_time(ldg, nil) + ldgt)..", "
		  ..format_distance(get_total(fdrgs, ldg, nil)/3600*nm2f*FRR + ldgd)..", "
		  ..string.format("%.0f(%+.0f)kias", fdrias[ldg], fdrias[ldg]-ltouch)..", "
		  ..format_speed(lvsnow, "fpm"))
	  
		if (apr ~= nil and ldg50 ~= nil) then
			-- Score components
			local lvstime = 0
			local lvsflot = 0
			for i = ldg50+1,table.getn(fdrong) do
				if (fdrong[i] == 0) then
					lvstime = lvstime + 1
					if (fdragl[i] >= fdragl[i-1]) then
						lvsflot = lvsflot + 1
					end
				end
			end
			local lvsapr = get_average(fdrvs, apr, ldg50-1)
			local lhdgnow = get_norm_deg(fdrhdg[ldg])
			local ltrknow = get_norm_deg(fdrtrk[ldg])
			local lhdgavg = get_average_deg(fdrhdg, ldg, nil)
			local ltrkavg = get_average_deg(fdrtrk, ldg, nil)
			local ltrkdev = get_limit(get_deviation_deg(fdrtrk, ldg, nil, ltrkavg), 0, 45)
			
			local longavg = get_average(fdrong, ldg, nil)
			local lskdavg = get_average(fdrskid, ldg, nil)
			local lskddev = get_deviation(fdrskid, ldg, nil, lskdavg)
			local lacxavg = get_average(fdracx, ldg, nil)
			local lacxdev = get_deviation(fdracx, ldg, nil, lacxavg)
			local lacyavg = get_average(fdracy, ldg, nil)
			local lacydev = get_deviation(fdracy, ldg, nil, lacyavg)
			local laczavg = get_average(fdracz, ldg, nil)
			local laczdev = get_deviation(fdracz, ldg, nil, laczavg)
			
			ldg1 = ldg
			ldg2 = nil
			if (ldg50 ~= nil) then
				ldg1 = ldg50
				ldg2 = ldg - 1 
			elseif (ldg35 ~= nil) then
				ldg1 = ldg35
				ldg2 = ldg - 1
			end

			local l2trkavg = get_average_deg(fdrtrk, ldg1, ldg2)
			local l2trkdev = get_limit(get_deviation_deg(fdrhdg, ldg1, ldg2, l2trkavg), 0, 45)
			
			local l2skdavg = get_average(fdrskid, ldg1, ldg2)
			local l2skddev = get_deviation(fdrskid, ldg1, ldg2, l2skdavg)
			local l2acxavg = get_average(fdracx, ldg1, ldg2)
			local l2acxdev = get_deviation(fdracx, ldg1, ldg2, l2acxavg)
			local l2acyavg = get_average(fdracy, ldg1, ldg2)
			local l2acydev = get_deviation(fdracy, ldg1, ldg2, l2acyavg)
			local l2aczavg = get_average(fdracz, ldg1, ldg2)
			local l2aczdev = get_deviation(fdracz, ldg1, ldg2, l2aczavg)
			
			-- Comfort scores
			local lcong = get_average{make_score(1-longavg)}
			local lcskd = get_average{make_score(skid_adjust(lskdavg)), make_score(skid_adjust(lskddev)), make_score(skid_adjust(l2skdavg)), make_score(skid_adjust(l2skddev))}
			local lcacx = get_average{make_score(math.abs(lacxavg)/32), make_score(lacxdev/32), make_score(math.abs(l2acxavg)/32), make_score(l2acxdev/32)}
			local lcacy = get_average{make_score(math.abs(lacyavg)/32), make_score(lacydev/32), make_score(math.abs(l2acyavg)/32), make_score(l2acydev/32)}
			local lcacz = get_average{make_score(math.abs(laczavg)/32), make_score(laczdev/32), make_score(math.abs(l2aczavg)/32), make_score(l2aczdev/32)}

			-- Skill scores
			local lhtnow = get_limit(get_diff_deg(math.abs(lhdgnow-ltrknow)), -45, 45)
			local lhtavg = get_limit(get_diff_deg(math.abs(lhdgavg-ltrkavg)), -45, 45)
			local lttavg = get_limit(get_diff_deg(math.abs(ltrkavg-l2trkavg)), -45, 45)
			--print(get_stall(nil))
			--print(ltouch)

			local lsias = get_average{make_score(math.abs(fdrias[ldg]-ltouch)/math.max(fdrias[ldg], ltouch))}
			local lsvsi = get_average{make_score(math.abs(lvsnow)/math.abs(lvsapr))}
			local lshtd = get_average{make_score(math.sin(lhtnow*2/r2d)), make_score(math.sin(lhtavg*2/r2d))}
			local lstrk = get_average{make_score(math.sin(ltrkdev*2/r2d)), make_score(math.sin(l2trkdev*2/r2d)), make_score(math.sin(lttavg*2/r2d))}
			local lsflt = get_average{make_score(lvsflot/lvstime)}
			local lsskd = get_average{make_score(skid_adjust(lskdavg)), make_score(skid_adjust(lskddev)), make_score(skid_adjust(l2skdavg)), make_score(skid_adjust(l2skddev))}

			lc = pack(substract_scores{lcong, lcskd, lcacx, lcacy, lcacz})
			ls = pack(substract_scores{lsias, lsvsi, lsflt, lshtd, lstrk, lsskd})
			
			table.insert(output, "        Comfort: "..string.format("%.0f%% (R=%.0f%%, S=%.0f%%, X=%.0f%%, Y=%.0f%%, Z=%.0f%%)", unpack(mult(lc, 100))))
			table.insert(output, "        Skill: "..string.format("%.0f%% (I=%.0f%%, V=%.0f%%, B=%.0f%%, H=%.0f%%, T=%.0f%%, S=%.0f%%)", unpack(mult(ls, 100))))
		end

		table.insert(output, " ")
	end

	table.insert(output, "Overall Comfort: "..string.format("%.0f%%", get_average{tc[1], ec[1], ac[1], lc[1]}*100))
	table.insert(output, "Overall Skill: "..string.format("%.0f%%", get_average{ts[1], es[1], as[1], ls[1]}*100))
	
	if (ipc ~= nil) then
		local f = assert(io.open("FlightCritic_"..os.date("%Y%m%d_%H%M%S")..".txt", "w"))
		for i=1,table.getn(output) do
			local t = f:write(output[i].."\n")
		end
		f:close()
	end

	format_output(output)
end

-- ----------------------------------------------------------------------------
-- Main functions

-- (Vs, KTTN 09015G25KT 075V105 TB MDT)
function extra()
	local a = {}
	
	local arpt = ipc.readSTR(0x0658, 4)
	local wdir = ipc.readUW(0x0E92)*360/65536
	local wvar = ipc.readUW(0x0E96)*360/65536
	local wspd = ipc.readUW(0x0E90)
	local wgst = ipc.readUW(0x0E94)
	local wtrb = math.floor(ipc.readUB(0x0E98)/64+0.5)
	local ctrb = math.floor(ipc.readUW(0x0E88)/72+0.5)
	local mtrb = math.max(wtrb, ctrb)
	
	local gw = ipc.readDBL(0x30C0)
	local mtow = ipc.readUD(0x1334)/256
	local flap = (ipc.readUD(0x0BE0)+ipc.readUD(0x0BE4)) / 32768
	local vs0 = ipc.readDBL(0x0538)*3600/nm2f
	local vs1 = ipc.readDBL(0x0540)*3600/nm2f
	local a = { gw, mtow, flap, vs0, vs1 }
	
	local s = ""
	while (string.byte(arpt, #arpt) == 0) do
		arpt = string.sub(arpt, 1, #arpt-1)
	end
	if (arpt ~= "") then
		s = s..arpt.." "
	end
	
	s = s..string.format("%03.0f", wdir)
	if (wgst >= wspd+3) then
		s = s..string.format("%02.0fG%02.0fKT", wspd, wgst)
	else
		s = s..string.format("%02.0fKT", wspd)
	end

	if (wvar >= 3) then
		s = s.." "
		local wdir1 = math.floor((wdir-wvar)+0.5)
		if (wdir1 < 1) then
			wdir1 = wdir1 + 360
		end
		local wdir2 = math.floor((wdir+wvar)+0.5)
		if (wdir2 > 360) then
			wdir2 = wdir2 - 360
		end
		s = s..string.format("%03dV%03d", wdir1, wdir2)
	end
	
	if (mtrb > 0) then
		s = s.." TB "
		if (mtrb >= 4) then
			s = s.."EXTRM"
		elseif (mtrb >= 3) then	
			s = s.."SVR"
		elseif (mtrb >= 2) then	
			s = s.."MDT"
		elseif (mtrb >= 1) then
			s = s.."LGT"
		end
	end
	
	if (s ~= "") then
		a[#a+1] = s
	end
	
	return a	
end

local ignore = false
function run(ong, vs)
	local pause = ipc.readUW(0x0264)
	local slew = ipc.readUW(0x05DC)
	
	if (ignore == true or pause == 1 or slew == 1) then
		return
	end
	
	if (ong == nil) then
		ong = ipc.readUW(0x0366)
	end
	local gs = ipc.readSD(0x02B4)/65536*3600*m2f/nm2f
	if (vs == nil) then
		vs = ipc.readSW(0x02C8)*60/256*m2f
	end

	if (FDR == nil) then
		if (ong == 1 and gs >= HWM) then
			start()
			record(ong, gs, vs, extra())
		end
	else
		if (ong == 1 and gs <= LWM) then
			record(ong, gs, vs, extra())
			analyze()
			stop()
		else
			record(ong, gs, vs)
		end
	end
end

function run_timer(t)
	run(nil, nil)
	ignore = false
end

function run_offset(o, v)
	run(v, ipc.readSW(0x030C)*60/256*m2f)
	ignore = true -- ignore next timer event
end

function toggle(f)
	if (FDR == nil) then
		start()
	else
		analyze()
		stop()
	end
end

if (ipc ~= nil) then
	if (DEBUG) then
		ipc.display("Flight Critic")
	end
	
	stop()
	event.timer(1000*FRR, "run_timer")
	event.offset(0x0366, "UW", "run_offset")
	event.flag(1, "toggle")
else
	local j = 0
	for i = 1,#arg do
		if (string.lower(string.sub(arg[i], 1, 2)) == "-d" or string.lower(string.sub(arg[i], 1, 3)) == "--d") then
			DEBUG = true
		else
			if (j > 0) then
				print("")
			end
			j = j + 1

			start()
			
			-- load CSV
			local f = assert(io.open (arg[i]))
			for s in f:lines() do
				local r = {}
				for v in string.gmatch(string.gsub(s, "[\n\r\t]", ""), "[^,]*") do
					if (v ~= "") then
						local n = tonumber(v)
						if (n ~= nil) then
							table.insert(r, n)
						else
							table.insert(r, v)
						end
					end
				end
				table.insert(FDR, r)
			end
			table.remove(FDR, 1)

			analyze()
			stop()
		end
	end
end
