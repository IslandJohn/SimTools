require "socket"

GFRP48_RotaryOffset = 1
GFRP48_RotaryCallback = 1
GFRP48_RotaryState = 2
GFRP48_RotaryMin = 3
GFRP48_RotaryMax = 4
GFRP48_RotaryLimit = 5

GFRP48_PushLong = 500
GFRP48_PushOffset = 5
GFRP48_PushCallback = 1
GFRP48_PushLast = 2

GFRP48_Map = {}

function GFRP48_DefineRotary(unit, control, callback, state, min, max, limit)
	if (GFRP48_Map[unit] == nil) then
		GFRP48_Map[unit] = {}
	end
	if (GFRP48_Map[unit][control+GFRP48_RotaryOffset] == nil) then
		GFRP48_Map[unit][control+GFRP48_RotaryOffset] = {}
	end
	GFRP48_Map[unit][control+GFRP48_RotaryOffset][GFRP48_RotaryCallback] = callback
	GFRP48_Map[unit][control+GFRP48_RotaryOffset][GFRP48_RotaryState] = state
	GFRP48_Map[unit][control+GFRP48_RotaryOffset][GFRP48_RotaryMin] = min
	GFRP48_Map[unit][control+GFRP48_RotaryOffset][GFRP48_RotaryMax] = max
	GFRP48_Map[unit][control+GFRP48_RotaryOffset][GFRP48_RotaryLimit] = limit
end

function GFRP48_DefinePush(unit, control, callback)
	if (GFRP48_Map[unit] == nil) then
		GFRP48_Map[unit] = {}
	end
	if (GFRP48_Map[unit][control+GFRP48_PushOffset] == nil) then
		GFRP48_Map[unit][control+GFRP48_PushOffset] = {}
	end
	GFRP48_Map[unit][control+GFRP48_PushOffset][GFRP48_PushCallback] = callback
	GFRP48_Map[unit][control+GFRP48_PushOffset][GFRP48_PushLast] = nil
end

function GFRP48_Event(model, unit)
	--ipc.log("Model = " .. model .. ", Unit = " .. unit)
	if (GFRP48_Map[unit] == nil) then
		return
	end
	
	gfd.GetValues(model, unit)
	
	for i = 0,3 do
		j = i + GFRP48_RotaryOffset
		if (GFRP48_Map[unit][j] ~= nil) then
			k = gfd.Dial(i);
			l = GFRP48_Map[unit][j][GFRP48_RotaryLimit]
			if (l ~= nil and math.abs(k) > l) then
				if (k < 0) then
					k = -l
				else
					k = l
				end
			end
			if (k ~= 0) then
				s = GFRP48_Map[unit][j][GFRP48_RotaryState]
				if (s ~= nil) then
					s = s + k
					smin = GFRP48_Map[unit][j][GFRP48_RotaryMin]
					smax = GFRP48_Map[unit][j][GFRP48_RotaryMax]
					if (smin ~= nil and s < smin) then
						s = smin
					end
					if (smax ~= nil and s > smax) then
						s = smax
					end
					GFRP48_Map[unit][j][GFRP48_RotaryState] = s
				end
				if (s == nil) then
					ipc.log(GFRP48_Map[unit][j][GFRP48_RotaryCallback] .. "(" .. k .. ")")
				else
					ipc.log(GFRP48_Map[unit][j][GFRP48_RotaryCallback] .. "(" .. k .. ", " .. s .. ")")
				end
				_G[GFRP48_Map[unit][j][GFRP48_RotaryCallback]](k, s)
			end
		end
	end
	
	for i = 0,7 do
		j = i + GFRP48_PushOffset
		if (GFRP48_Map[unit][j] ~= nil) then
			k = gfd.TestButton(i);
			if (k) then
				if (GFRP48_Map[unit][j][GFRP48_PushLast] == nil) then
					GFRP48_Map[unit][j][GFRP48_PushLast] = socket.gettime()
				end
			else
				if (GFRP48_Map[unit][j][GFRP48_PushLast] ~= nil) then
					d = socket.gettime() - GFRP48_Map[unit][j][GFRP48_PushLast]
					GFRP48_Map[unit][j][GFRP48_PushLast] = nil
					ipc.log(GFRP48_Map[unit][j][GFRP48_PushCallback] .. "(" .. (d) .. ")")
					_G[GFRP48_Map[unit][j][GFRP48_PushCallback]](d < GFRP48_PushLong / 1000)
				end
			end 
		end
	end
end

function LightsOn()
	n = gfd.GetNumDevices(GFRP48)
	for i=0,n,1 do
		gfd.SetLights(GFRP48, i, 255, 0)
	end
end

function LightsOff()
	n = gfd.GetNumDevices(GFRP48)
	for i=0,n,1 do
		gfd.SetLights(GFRP48, i, 0, 255)
	end
end

ipc.log("Starting...")

LightsOff()
event.sim(CLOSE, "LightsOff")
event.gfd(GFRP48, "GFRP48_Event")
