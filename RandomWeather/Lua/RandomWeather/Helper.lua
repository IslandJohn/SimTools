-- Helper functions
math.randomseed(os.time())
for i = 1,math.random(1, 100) do math.random() end

function rwrand(low, high)
	local r = math.random()
	return low + r * (high - low)
	
end

function rwround(n)
	return math.floor(n + 0.5)
end

function rwdeg(d)
	while (d < 0.5) do
		d = d + 360
	end
	while (d >= 360.5) do
		d = d - 360
	end
	return d
end
