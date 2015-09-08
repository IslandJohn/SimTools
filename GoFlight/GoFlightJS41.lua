function SetMain(vel, state)
	if (state == 1) then
		ipc.writeLvar("LeftBatSwitch", 0)
		ipc.writeLvar("RightBatSwitch", 0)
		ipc.writeLvar("LeftAvionicsMaster", 0)
		ipc.writeLvar("RightAvionicsMaster", 0)
		ipc.writeLvar("LeftAvionicsMasterGuard", 0)
		ipc.writeLvar("RightAvionicsMasterGuard", 0)
		LightsOff()
	elseif (state == 2) then
		ipc.writeLvar("LeftBatSwitch", 1)
		ipc.writeLvar("RightBatSwitch", 1)
		ipc.writeLvar("LeftAvionicsMaster", 0)
		ipc.writeLvar("RightAvionicsMaster", 0)
		ipc.writeLvar("LeftAvionicsMasterGuard", 0)
		ipc.writeLvar("RightAvionicsMasterGuard", 0)
		LightsOn()
	elseif (state == 3) then
		ipc.writeLvar("LeftBatSwitch", 1)
		ipc.writeLvar("RightBatSwitch", 1)
		ipc.writeLvar("LeftAvionicsMasterGuard", 1)
		ipc.writeLvar("RightAvionicsMasterGuard", 1)
		ipc.writeLvar("LeftAvionicsMaster", 1)
		ipc.writeLvar("RightAvionicsMaster", 1)
	end
end

function SetEngineMode(vel, state)
	if (PowerEngine == 1) then
		if (state == 1) then
			ipc.writeLvar("LeftGenSwitch", 1)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("StartMasterKnob", 1)
		elseif (state == 2) then
			ipc.writeLvar("LeftGenSwitch", 2)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("StartMasterKnob", 1)
		elseif (state == 3) then
			ipc.writeLvar("LeftGenSwitch", 1)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("StartMasterKnob", 0)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("LeftStart", 1)
			ipc.writeLvar("StartOneToggle", 1)
			ipc.writeLvar("LeftStartCheck", 1)
			ipc.writeLvar("LeftStartTimer", 1)
		end
	elseif (PowerEngine == 2) then
		if (state == 1) then
			ipc.writeLvar("RightGenSwitch", 1)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("StartMasterKnob", 1)
		elseif (state == 2) then
			ipc.writeLvar("RightGenSwitch", 2)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("StartMasterKnob", 1)
		elseif (state == 3) then
			ipc.writeLvar("RightGenSwitch", 1)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("StartMasterKnob", 2)
			ipc.sleep(PowerDelay)
			ipc.writeLvar("RightStart", 1)
			ipc.writeLvar("StartTwoToggle", 1)
			ipc.writeLvar("RightStartCheck", 1)
			ipc.writeLvar("RightStartTimer", 1)
		end
	end
end

function ToggleFuel(short)
	if (ipc.readLvar("LeftStbyFuelPump") == 0 and ipc.readLvar("RightStbyFuelPump") == 0) then
		ipc.writeLvar("LeftStbyFuelPump", 1)
		ipc.writeLvar("RightStbyFuelPump", 1)
	else
		ipc.writeLvar("LeftStbyFuelPump", 0)
		ipc.writeLvar("RightStbyFuelPump", 0)
	end
	
--	if (PowerEngine == 1) then
--		if (ipc.readLvar("LeftStbyFuelPump") == 0) then
--			ipc.writeLvar("LeftStbyFuelPump", 1)
--		else
--			ipc.writeLvar("LeftStbyFuelPump", 0)
--		end
--	elseif (PowerEngine == 2) then
--		if (ipc.readLvar("RightStbyFuelPump") == 0) then
--			ipc.writeLvar("RightStbyFuelPump", 1)
--		else
--			ipc.writeLvar("RightStbyFuelPump", 0)
--		end
--	end
end

function ToggleIgnition(short)
	if (ipc.readLvar("LeftIgnition") == 0 and ipc.readLvar("RightIgnition") == 0) then
		ipc.writeLvar("LeftIgnition", 1)
		ipc.writeLvar("RightIgnition", 1)
	else
		ipc.writeLvar("LeftIgnition", 0)
		ipc.writeLvar("RightIgnition", 0)
	end
	
--	if (PowerEngine == 1) then
--		if (ipc.readLvar("LeftIgnition") == 0) then
--			ipc.writeLvar("LeftIgnition", 1)
--		else
--			ipc.writeLvar("LeftIgnition", 0)
--		end
--	elseif (PowerEngine == 2) then
--		if (ipc.readLvar("RightIgnition") == 0) then
--			ipc.writeLvar("RightIgnition", 1)
--		else
--			ipc.writeLvar("RightIgnition", 0)
--		end
--	end
end

function SetLatValue(vel, state)
	if (APLat == 1) then
		if (vel < 0) then
			for i=1,vel*vel,1 do
				ipc.control(66587, 26901)
			end
		else
			for i=1,vel*vel,1 do
				ipc.control(66587, 26902)
			end
		end
	elseif (APLat == 2) then
		if (vel < 0) then
			for i=1,vel*vel,1 do
				ipc.control(66587, 26701)
			end
		else
			for i=1,vel*vel,1 do
				ipc.control(66587, 26702)
			end
		end
	elseif (APLat == 3) then
	end
end

function SetVertValue(vel, state)
	if (APVert == 1) then
		if (vel < 0) then
			for i=1,vel*vel,1 do
				ipc.control(66587, 3920)
			end
		else
			for i=1,vel*vel,1 do
				ipc.control(66587, 3921)
			end
		end
	elseif (APVert == 2) then
		if (vel < 0) then
			for i=1,vel*vel,1 do
				ipc.control(66587, 1501)
			end
		else
			for i=1,vel*vel,1 do
				ipc.control(66587, 1500)
			end
		end
	elseif (APVert == 3) then -- same as 2
		if (vel < 0) then
			for i=1,vel*vel,1 do
				ipc.control(66587, 1501)
			end
		else
			for i=1,vel*vel,1 do
				ipc.control(66587, 1500)
			end
		end
	end
end

function SetVSIValue(vel, state)
	APVert = 2
	SetVertValue(vel, state)
end

function ToggleHDGROL(short)
	if (short) then
		ipc.control(66587, 277)
	else
	end
end

function ToggleNAVGS(short)
	if (short) then
		ipc.control(66587, 278)
	else
	end
end

function ToggleAPRREV(short)
	if (short) then
		ipc.control(66587, 279)
	else
		ipc.control(66587, 280)
	end
end

function ToggleALTSELALT(short)
	if (short) then
		ipc.control(66587, 282)
	else
		ipc.control(66587, 281)
	end
end

function ToggleVSPIT(short)
	if (short) then
		ipc.control(66587, 283)
	else
	end
end

function ToggleIASMACH(short)
	if (short) then
		ipc.control(66587, 284)
	else
	end
end

function ToggleCDIOBS(short)
	if (short) then
	else
	end
end

function LightsSync(ofs, val)
	instr = logic.And(val, 32)
	logo = logic.And(val, 256)
	nav = logic.And(val, 1)
	wing = logic.And(val, 128)
	recog = logic.And(val, 64)
	
	if (instr ~= 0) then
		ipc.writeLvar("PanelFloodSW", 1)
	else
		ipc.writeLvar("PanelFloodSW", 0)
	end
	
	if (logo ~= 0) then
		ipc.writeLvar("NavLightSwitch", 0)
	elseif (nav ~= 0) then
		ipc.writeLvar("NavLightSwitch", 2)
	else
		ipc.writeLvar("NavLightSwitch", 1)
	end
	
	if (wing ~= 0) then
		ipc.writeLvar("IceOBSSwitch", 2)
	else
		ipc.writeLvar("IceOBSSwitch", 1)
	end
	
	if (recog ~= 0) then
		ipc.writeLvar("ConspicLight", 1)
	else
		ipc.writeLvar("ConspicLight", 0)
	end
end

event.offset(0x0d0c, "UW", "LightsSync")
ipc.log("Loaded JS41")