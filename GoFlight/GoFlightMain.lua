require "GoFlightPower"
require "GoFlightAP"
require "GoFlightRadio"

CustomRequire = {
	duket = "GoFlightDukeT",
	duke = "GoFlightDuke",
	js41 = "GoFlightJS41",
	e135 = "GoFlightERJ",
	e145 = "GoFlightERJ"
}

aircraft = ipc.readSTR(0x3500, 24)
ipc.log("Aircraft is "..aircraft)
for k,v in pairs(CustomRequire) do
	if (string.find(string.lower(aircraft), k) ~= nil) then
		require(v)
		break
	end
end

ipc.log("Ready.")
