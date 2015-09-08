--[[
Random Weather 1.3.0
E-mail: pilotjohn at gearsdown.com

Features:
- Themes with randomized parameters
- Many pre-defined VFR, MVFR, IFR, LIFR themes
- Randomly picked themes with configurable probabilities (weights)
- Excluded themes (by weight) can still be selected through user input
- Custom themes can be provided as METAR input
- Temperature layers with different lapse rates
- Surface temperatures adjusted for latitude and season
- Graduated visibility layers
- Multiple cloud layers with order restrictions
- Cloud bases adjustable based on coverage
- Precipitation type based on cloud and surface temperatures
- Precipitation rate adjusted by cloud coverage
- Icing based on cloud temperatures and adjusted by cloud coverage
- Multiple wind layers with controllable shear
- Surface wind based on prevailing direction by latitude
- Winds aloft direction and strength based on latitude
- Share generated weather over the Internet

Setup:
1. In FSUIPC "Buttons + Switches" (or similar in "Keys"),
     "PRESS" "BUTTON",
     check "Select for FS control",
     choose "Lua RandomWeather",
     and enter "1" for "Paramater"
2. If you want weather generated on flight startup, then
   edit "FSUIPC.ini" and add (substitute X for 1 or next # if exists):
     [Auto]
     X=Lua RandomWeather
]]

-- Script options
local NODYNAMICS = false -- Global dynamics disable
local PROMPT = false -- Prompt for theme on start-up
local DISPLAY = false -- Display progress messages
local DEBUG = true -- Enable debugging (creates RandomWeather.txt)
local NETWORK = "http://randomweather.gearsdown.com/" -- URL (where RandomWeather.php is deployed) to upload/download generated weather

-- Weather themes
local DYNAMICS = "Dynamics"
local PRESSURE = "Pressure"
local TEMPERATURE = "Temperature"
local VISIBILITY = "Visibility"
local CLOUDS = "Clouds"
local WINDS = "Winds"
local WEIGHT = "Weight"
local ORDER = "Order"
local weather_themes = { 
	["VFR Easy"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			1010, -- Minimum pressure (mbar)
			1030, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			10, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			15, -- Minimum dew point spread (C)
			25, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			30, -- Minimum surface visibility (SM)
			60, -- Maximum surface visibility (SM)
			45, -- Minimum upper altitude visibility (SM)
			60, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, }, -- Allowed cloud types (1,8,9,10)
				1000, -- Minimum base (M)
				3000, -- Maximum base (M)
				150, -- Minimum height (M)
				500, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				2, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				4, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				2, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				2, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			10, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			5, -- Maximum gust (KTS)
			45, -- Prevailing heading range (+/-)
			5, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			5, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			0, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 13,
		[ORDER] = 1,
	},
	["VFR Medium"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			1005, -- Minimum pressure (mbar)
			1025, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			0, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			5, -- Minimum dew point spread (C)
			15, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			15, -- Minimum surface visibility (SM)
			45, -- Maximum surface visibility (SM)
			30, -- Minimum upper altitude visibility (SM)
			60, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 8, 9, 9, 9, }, -- Allowed cloud types (1,8,9,10)
				1000, -- Minimum base (M)
				2000, -- Maximum base (M)
				300, -- Minimum height (M)
				1000, -- Maximum height (M)
				1, -- Minimum coverage (eighth)
				3, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				1, -- Maximum icing (0-4)
				4, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
			},
			{
				{ 8, 9, 9, 9, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				1000, -- Maximum base (M)
				300, -- Minimum height (M)
				1000, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				4, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				0, -- Maximum turbulence (0-4)
				4, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				2, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			5, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			10, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 13,
		[ORDER] = 2,
	},
	["VFR Hard"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			1000, -- Minimum pressure (mbar)
			1020, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			0, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			25, -- Maximum temperature (C)
			5, -- Minimum dew point spread (C)
			15, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			15, -- Minimum surface visibility (SM)
			30, -- Maximum surface visibility (SM)
			30, -- Minimum upper altitude visibility (SM)
			45, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				1000, -- Minimum base (M)
				1500, -- Maximum base (M)
				500, -- Minimum height (M)
				1500, -- Maximum height (M)
				2, -- Minimum coverage (eighth)
				4, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				12, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				0, -- Maximum icing (0-4)
				6, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
			},
			{
				{ 8, 8, 9, 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				500, -- Maximum base (M)
				500, -- Minimum height (M)
				1500, -- Maximum height (M)
				1, -- Minimum coverage (eighth)
				5, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				1, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
			{
				{ 8, 8, 9, 9, 9, 9, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				500, -- Maximum base (M)
				500, -- Minimum height (M)
				1500, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				6, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				0, -- Maximum turbulence (0-4)
				4, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				2, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			10, -- Minimum speed without gust (KTS)
			30, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			15, -- Maximum gust (KTS)
			75, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			15, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			1, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 13,
		[ORDER] = 3,
	},
	["VFR Clear"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			1005, -- Minimum pressure (mbar)
			1025, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			0, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			5, -- Minimum dew point spread (C)
			15, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			45, -- Minimum surface visibility (SM)
			60, -- Maximum surface visibility (SM)
			45, -- Minimum upper altitude visibility (SM)
			60, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			15, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			1, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 11,
		[ORDER] = 4,
	},
	["VFR Cloudy"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			1005, -- Minimum pressure (mbar)
			1025, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			0, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			5, -- Minimum dew point spread (C)
			15, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			45, -- Minimum surface visibility (SM)
			60, -- Maximum surface visibility (SM)
			45, -- Minimum upper altitude visibility (SM)
			60, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, }, -- Allowed cloud types (1,8,9,10)
				1000, -- Minimum base (M)
				1500, -- Maximum base (M)
				1000, -- Minimum height (M)
				1500, -- Maximum height (M)
				3, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				5, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 9, 9, 9, 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				300, -- Maximum base (M)
				1000, -- Minimum height (M)
				1500, -- Maximum height (M)
				2, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				4, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				2, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				1, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				300, -- Maximum base (M)
				1000, -- Minimum height (M)
				1500, -- Maximum height (M)
				1, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				0, -- Maximum turbulence (0-4)
				2, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				1, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				0, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			15, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			2, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			1, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 11,
		[ORDER] = 5,
	},
	["VFR Calm"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			1000, -- Minimum pressure (mbar)
			1020, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			0, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			25, -- Maximum temperature (C)
			5, -- Minimum dew point spread (C)
			15, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			10, -- Minimum surface visibility (SM)
			20, -- Maximum surface visibility (SM)
			15, -- Minimum upper altitude visibility (SM)
			30, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 8, 9, }, -- Allowed cloud types (1,8,9,10)
				1000, -- Minimum base (M)
				3000, -- Maximum base (M)
				150, -- Minimum height (M)
				500, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				2, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				4, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				2, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				2, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			5, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			0, -- Maximum gust (KTS)
			30, -- Prevailing heading range (+/-)
			0, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			0, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			0, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 11,
		[ORDER] = 6,
	},
	["VFR Windy"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			1010, -- Minimum pressure (mbar)
			1030, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			10, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			15, -- Minimum dew point spread (C)
			25, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			30, -- Minimum surface visibility (SM)
			60, -- Maximum surface visibility (SM)
			45, -- Minimum upper altitude visibility (SM)
			60, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				1000, -- Minimum base (M)
				1500, -- Maximum base (M)
				500, -- Minimum height (M)
				1500, -- Maximum height (M)
				2, -- Minimum coverage (eighth)
				4, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				3, -- Maximum turbulence (0-4)
				12, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				6, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				500, -- Maximum base (M)
				500, -- Minimum height (M)
				1500, -- Maximum height (M)
				1, -- Minimum coverage (eighth)
				5, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				500, -- Maximum base (M)
				500, -- Minimum height (M)
				1500, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				6, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				4, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				2, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			15, -- Minimum speed without gust (KTS)
			30, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			15, -- Maximum gust (KTS)
			90, -- Prevailing heading range (+/-)
			30, -- Prevailing heading variance (+/-)
			60, -- Upper heading range (+/-)
			30, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			3, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			2, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 11,
		[ORDER] = 7,
	},
	["MVFR Visibility"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			995, -- Minimum pressure (mbar)
			1015, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			2, -- Minimum dew point spread (C)
			5, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			3, -- Minimum surface visibility (SM)
			5, -- Maximum surface visibility (SM)
			5, -- Minimum upper altitude visibility (SM)
			10, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				1000, -- Minimum base (M)
				2000, -- Maximum base (M)
				1000, -- Minimum height (M)
				3000, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				5, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				5, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 7,
		[ORDER] = 8,
	},
	["MVFR Ceiling"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			995, -- Minimum pressure (mbar)
			1015, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			2, -- Minimum dew point spread (C)
			5, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			5, -- Minimum surface visibility (SM)
			15, -- Maximum surface visibility (SM)
			10, -- Minimum upper altitude visibility (SM)
			20, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				300, -- Minimum base (M)
				1000, -- Maximum base (M)
				1000, -- Minimum height (M)
				2000, -- Maximum height (M)
				4, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				16, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				3, -- Maximum icing (0-4)
				5, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-300, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				300, -- Maximum base (M)
				1000, -- Minimum height (M)
				2000, -- Maximum height (M)
				5, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			2, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			1, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 7,
		[ORDER] = 9,
	},
	["MVFR Both"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			995, -- Minimum pressure (mbar)
			1015, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			0, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			2, -- Minimum dew point spread (C)
			5, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			3, -- Minimum surface visibility (SM)
			5, -- Maximum surface visibility (SM)
			5, -- Minimum upper altitude visibility (SM)
			10, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				300, -- Minimum base (M)
				1000, -- Maximum base (M)
				1000, -- Minimum height (M)
				2000, -- Maximum height (M)
				4, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				16, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				3, -- Maximum icing (0-4)
				5, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-300, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				300, -- Maximum base (M)
				1000, -- Minimum height (M)
				2000, -- Maximum height (M)
				5, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				2, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			2, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			1, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 7,
		[ORDER] = 10,
	},
	["IFR Visibility"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			990, -- Minimum pressure (mbar)
			1010, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			1, -- Minimum dew point spread (C)
			3, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			1, -- Minimum surface visibility (SM)
			3, -- Maximum surface visibility (SM)
			3, -- Minimum upper altitude visibility (SM)
			5, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				300, -- Minimum base (M)
				1000, -- Maximum base (M)
				1000, -- Minimum height (M)
				3000, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				6, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				24, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				3, -- Maximum icing (0-4)
				3, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-500, -- Decrease/increase bases by this much per octet
				5, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-150, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 5,
		[ORDER] = 11,
	},
	["IFR Ceiling"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			990, -- Minimum pressure (mbar)
			1010, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			1, -- Minimum dew point spread (C)
			3, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			3, -- Minimum surface visibility (SM)
			5, -- Maximum surface visibility (SM)
			5, -- Minimum upper altitude visibility (SM)
			10, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				150, -- Minimum base (M)
				300, -- Maximum base (M)
				1000, -- Minimum height (M)
				3000, -- Maximum height (M)
				4, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				24, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				6, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-75, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				150, -- Maximum base (M)
				1000, -- Minimum height (M)
				3000, -- Maximum height (M)
				6, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				12, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				3, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 5,
		[ORDER] = 12,
	},
	["IFR Both"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			990, -- Minimum pressure (mbar)
			1010, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			1, -- Minimum dew point spread (C)
			3, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			1, -- Minimum surface visibility (SM)
			3, -- Maximum surface visibility (SM)
			3, -- Minimum upper altitude visibility (SM)
			5, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				150, -- Minimum base (M)
				300, -- Maximum base (M)
				1000, -- Minimum height (M)
				3000, -- Maximum height (M)
				4, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				24, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				6, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-75, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				150, -- Maximum base (M)
				1000, -- Minimum height (M)
				3000, -- Maximum height (M)
				6, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				12, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				3, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			2, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			1, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 5,
		[ORDER] = 13,
	},
	["LIFR Visibility"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			980, -- Minimum pressure (mbar)
			1000, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			0, -- Minimum dew point spread (C)
			1, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			0, -- Minimum surface visibility (SM)
			1, -- Maximum surface visibility (SM)
			1, -- Minimum upper altitude visibility (SM)
			3, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				150, -- Minimum base (M)
				300, -- Maximum base (M)
				2000, -- Minimum height (M)
				3000, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				7, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				32, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				3, -- Maximum icing (0-4)
				5, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-75, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 3,
		[ORDER] = 14,
	},
	["LIFR Ceiling"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			980, -- Minimum pressure (mbar)
			1000, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			1, -- Minimum dew point spread (C)
			3, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			1, -- Minimum surface visibility (SM)
			3, -- Maximum surface visibility (SM)
			3, -- Minimum upper altitude visibility (SM)
			5, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				150, -- Maximum base (M)
				2000, -- Minimum height (M)
				3000, -- Maximum height (M)
				4, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				32, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				7, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-50, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				150, -- Maximum base (M)
				2000, -- Minimum height (M)
				3000, -- Maximum height (M)
				7, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				16, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			1, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			0, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 3,
		[ORDER] = 15,
	},
	["LIFR Both"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			980, -- Minimum pressure (mbar)
			1000, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			5, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			20, -- Maximum temperature (C)
			1, -- Minimum dew point spread (C)
			3, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			0, -- Minimum surface visibility (SM)
			1, -- Maximum surface visibility (SM)
			1, -- Minimum upper altitude visibility (SM)
			3, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				150, -- Maximum base (M)
				2000, -- Minimum height (M)
				3000, -- Maximum height (M)
				4, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				1, -- Maximum turbulence (0-4)
				32, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				7, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-50, -- Decrease/increase bases by this much per octet
			},
			{
				{ 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				150, -- Maximum base (M)
				2000, -- Minimum height (M)
				3000, -- Maximum height (M)
				7, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				2, -- Maximum turbulence (0-4)
				16, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			20, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			10, -- Maximum gust (KTS)
			60, -- Prevailing heading range (+/-)
			15, -- Prevailing heading variance (+/-)
			30, -- Upper heading range (+/-)
			10, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			2, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			1, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 3,
		[ORDER] = 16,
	},
	["Unpredictable"] = {
		[DYNAMICS] = {
			0, -- Minimum (0-4)
			4, -- Maximum (0-4)
		},
		[PRESSURE] = {
			980, -- Minimum pressure (mbar)
			1030, -- Maximum pressure (mbar)
		},
		[TEMPERATURE] = {
			0, -- Minimum temperature (C), assuming ISA is normal (it will be adjusted by month and latitude)
			25, -- Maximum temperature (C)
			0, -- Minimum dew point spread (C)
			25, -- Maximum dew point spread (C)
			true, -- New dew point spread at every layer?
			-16, -- Minimum lapse rate (C/1000M)
			 4, -- Maximum lapse rate (C/1000M)
			true, -- New lapse rate at every layer?
			13716, -- Highest temperature layer (M)
			6, -- Number of layers
		},
		[VISIBILITY] = {
			0, -- Minimum surface visibility (SM)
			60, -- Maximum surface visibility (SM)
			0, -- Minimum upper altitude visibility (SM)
			60, -- Maximum upper altitude visibility (SM)
			13716, -- Highest visibility layer (M)
			12, -- Number of layers
			false, -- Allow upper visibility with lower range than surface
		},
		[CLOUDS] = { -- layers
			{
				{ 8, 8, 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				2000, -- Maximum base (M)
				0, -- Minimum height (M)
				3000, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				4, -- Maximum turbulence (0-4)
				16, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				5, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				5, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				-250, -- Decrease/increase bases by this much per octet
			},
			{
				{ 8, 8, 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				300, -- Maximum base (M)
				0, -- Minimum height (M)
				3000, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				4, -- Maximum turbulence (0-4)
				8, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				4, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
			{
				{ 8, 8, 9, 9, 9, 10, }, -- Allowed cloud types (1,8,9,10)
				0, -- Minimum base (M)
				300, -- Maximum base (M)
				0, -- Minimum height (M)
				3000, -- Maximum height (M)
				0, -- Minimum coverage (eighth)
				8, -- Maximum coverage (eighth)
				0, -- Minimum turbulence (0-4)
				4, -- Maximum turbulence (0-4)
				4, -- Precipitation chance (%), type is based on cloud level (freezing layer) and surface temperature
				0, -- Minimum precipitation rate (0-5)
				3, -- Maximum precipitation rate (0-5)
				-- Icing chance is determined by cloud base and top temperatures
				0, -- Minimum icing (0-4)
				4, -- Maximum icing (0-4)
				0, -- +/-Coverage below/above which decrease/increase bases (if mininmum is alreay 0, maximum is decreased)
				0, -- Decrease/increase bases by this much per octet
			},
		},
		[WINDS] = {
			0, -- Minimum speed without gust (KTS)
			45, -- Maximum speed with gust (KTS)
			0, -- Minimum gust (KTS)
			30, -- Maximum gust (KTS)
			90, -- Prevailing heading range (+/-)
			30, -- Prevailing heading variance (+/-)
			90, -- Upper heading range (+/-)
			30, -- Upper heading variance (+/-)
			0, -- Minimum turbulence (0-4)
			4, -- Maximum turbulence (0-4)
			0, -- Minimum shear (0-3)
			2, -- Maximum shear (0-3)
			true, -- New speed delta at every layer?
			13716, -- Highest wind layer (M)
			9, -- Number of layers
		},
		[WEIGHT] = 2,
		[ORDER] = 17,
	},
}

-- Supporting libraries etc.
if (ipc == nil) then
	package.path = "Lua/?.lua;Lua/?/init.lua;"..package.path
end
require("mime")
require("socket.http")
require("vstruct")
require("RandomWeather/CopyTable")
require("RandomWeather/DataDumper")
require("RandomWeather/Helper")
require("RandomWeather/NWI")
require("RandomWeather/Generator")

-- Start
local themes = {}
local pick = {}
for k,v in pairs(weather_themes) do
	table.insert(themes, k)
	for i=1,v[WEIGHT] do
		table.insert(pick, k)
	end
end
table.sort(themes, function (a, b)
	a = weather_themes[a][ORDER]
	b = weather_themes[b][ORDER]
	if (a == nil) then return false end
	if (b == nil) then return true end
	return a<b
end)

local theme = "I:"..pick[math.random(1, table.getn(pick))]
if (ipc ~= nil) then
	if ((ipcPARAM == 0 and PROMPT == true) or ipcPARAM == 1) then
		local n = table.getn(themes) + 2
		local n2 = n
		if (NETWORK ~= nil and NETWORK ~= "") then
			n = n + 1
		end
		local c = string.len(n)
		local f = "    %"..c.."d"
		local s = ""
		
		s = s.."Random Weather\n  Select a weather theme, or enter a station ID for briefing (use blank for nearest):\n"
			..string.format(f.." - Reset\n", 0)
			..string.format(f.." - Random\n", 1)
		for i,v in ipairs(themes) do
			s = s..string.format(f.." - %s\n", i+1, v)
		end
		s = s..string.format(f.." - Custom", n2)
		if (NETWORK ~= nil and NETWORK ~= "") then
			s = s..string.format("\n"..f.." - Shared", n)
		end
		
		local a = ipc.ask(s)
		if (a == nil) then
			return
		end
		if (a == "") then
			a = "<??>"
		end
		if (tonumber(a) == nil) then
			local w = rwget(a)
			
			ipc.lineDisplay(rwmetar(w))
			ipc.lineDisplay(rwwinds(w), 2)
			ipc.sleep(60000)

			return
		end

		a = tonumber(a)
		if (a == 0) then
			theme = ""
		elseif (a == 1) then
		elseif (a == n2) then
			theme = ipc.ask("Random Weather\n  Enter custom weather METAR (use \"GLOB\" station ID for global setting): ")
			if (theme == nil or theme == "") then
				return
			end
			theme = "M:"..theme:upper()
		elseif (a == n) then
			theme = ipc.ask("Random Weather\n  Enter shared weather ID: ")
			if (theme == nil or theme == "") then
				return
			end
			theme = "N:"..theme:upper()
		elseif (a > 1) then
			theme = "I:"..themes[a-1]
		end
	end
elseif (arg[1] ~= nil) then
	theme = "N:"..arg[1]:upper()
end

-- Begin
if (ipc ~= nil) then
	if (DISPLAY == true) then
		ipc.lineDisplay("Random Weather", 0)
	end
end

-- Stop dynamic weather
if (ipc ~= nil) then
	if (DISPLAY == true) then
		ipc.lineDisplay("  Stopping dynamic weather", -32)
	end

	rwdynamics(0)
	ipc.sleep(1000)
end

-- Clear existing weather
if (ipc ~= nil and theme:sub(1, 2) ~= "M:") then
	if (DISPLAY == true) then
		ipc.lineDisplay("  Clearing existing weather", -32)
	end

	rwclear()
	ipc.sleep(1000)
end

-- Generate new weather
local weather = nil
if (theme:sub(1, 2) == "I:") then
	theme = theme:sub(3)
	if (ipc ~= nil) then
		if (DISPLAY == true) then
			ipc.lineDisplay("  Generating weather theme: "..theme, -32)
		end
		if (DEBUG == true) then
			local f = assert(io.open("RandomWeather.txt", "w+"))
			local t = f:write(DataDumper(weather_themes[theme], "weather_themes["..theme.."] = ").."\n")
			f:close()
		end
	else
		print(DataDumper(weather_themes[theme], "weather_themes["..theme.."] = "))
	end

	weather = rwgenerate(weather_themes[theme])
	local s, c
	if (NETWORK ~= nil and NETWORK ~= "") then
		s, c = socket.http.request(NETWORK, rwbin(weather))
	end
	if (c == 200) then
		theme = s
	else
		theme = nil
	end
elseif (theme:sub(1, 2) == "N:") then
	theme = theme:sub(3)
	if (ipc ~= nil) then
		if (DISPLAY == true) then
			ipc.lineDisplay("  Downloading shared weather: "..theme, -32)
		end
		if (DEBUG == true) then
			local f = assert(io.open("RandomWeather.txt", "w+"))
			local t = f:write("Shared weather ID: "..theme.."\n")
			f:close()
		end
	else
		print("ID = "..theme)
	end
	
	local s, c = socket.http.request(NETWORK..theme)
	if (c == 200 and #s == 1024) then
		weather = rwstruct(s)
	end
	theme = nil
elseif (theme:sub(1, 2) == "M:") then
	theme = theme:sub(3)
	if (ipc ~= nil) then
		if (DEBUG == true) then
			local f = assert(io.open("RandomWeather.txt", "w+"))
			local t = f:write("Custom weather METAR: "..theme.."\n")
			f:close()
		end
	else
		print("METAR = "..theme)
	end
	
	weather = nil
else
	if (ipc ~= nil) then
		if (DEBUG == true) then
			local f = assert(io.open("RandomWeather.txt", "w+"))
			f:close()
		end
	end
end

-- Set new weather
if (weather ~= nil) then
	if (ipc ~= nil) then
		if (DISPLAY == true) then
			ipc.lineDisplay("  Setting new weather", -32)
		end
		if (DEBUG == true) then
			local f = assert(io.open("RandomWeather.txt", "a+"))
			local t = f:write(rwdump(weather))
			f:close()
		end

		rwset(weather)
		ipc.sleep(1000)
		
		if (NODYNAMICS == false) then
			rwdynamics(weather.uDynamics)
			ipc.sleep(1000)
		end
	else
		print(rwdump(weather))
	end
elseif (theme ~= nil) then
	if (ipc ~= nil) then
		if (DISPLAY == true) then
			ipc.lineDisplay("  Setting custom weather", -32)
		end
		if (DEBUG == true) then
			local f = assert(io.open("RandomWeather.txt", "a+"))
			local t = f:write(theme)
			f:close()
		end
		
		rwsetmetar(theme)
		ipc.sleep(1000)
	end

	theme = nil
end

-- Exit
if (ipc ~= nil) then
	if (DISPLAY == true) then
		if (theme ~= nil) then
			ipc.lineDisplay("  Shared weather ID: "..theme, -32)
		end
		ipc.lineDisplay("Done.", -32)
		ipc.sleep(5000)
	elseif (theme ~= nil) then
		ipc.lineDisplay("Shared weather ID: "..theme)
		ipc.sleep(5000)
	end
else
	if (weather ~= nil) then
		print(rwmetar(weather))
		print(rwwinds(weather))
	end
	if (theme ~= nil) then
		print("ID = "..theme)
	end
end
