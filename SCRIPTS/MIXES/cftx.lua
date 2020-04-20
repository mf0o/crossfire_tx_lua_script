-- 2019-11-13	added address for dynamic power and max power as crossfire v3.21 had different values than v2.88

-- define inputs
local cfinputs = {
        { "cfTxPower", SOURCE},                 -- GV1; 0,1,2,3 maps to TX power levels
        { "cfTxDyn", SOURCE},                   -- GV2; 0,1 store requested Dynamic in global variable, e.g. GV2
        { "cfTxDevice", VALUE, 0, 500, 238 },	-- 238 seems to be the default
        { "playSounds", VALUE, 0, 1, 1 },		-- enable custom sounds
        { "playBeep", VALUE, 0, 1, 1 }			-- enable beeps 
    }

-- Variables to store parameters last programmed to vtx

local dynamicPowerAddr = 6		-- 8 @ v2.88, 6 @ v3.21
local maxPowerAddr = 5		    -- 5 @ v2.88, 5 @ v3.21

local exdelay = 50   	-- 1s
						-- was 2, delay between crossfireTelemetryPush, TX doesnt like to get fired too heavily
					  	-- crossfireTelemetryPush(0x28, { 0x00, 0xEA })

local lastCfPower
local lastCfDyn
local firstrun = 1

local BeepFrequency = 4000 -- Hz
local BeemLengthMiliseconds = 20

local function cfrun(cfTxPower, cfTxDyn, cfTxDevice, playSounds, playBeep )
    
	-- ignore any settings on first run of the script, send only further changes to vtx
	if firstrun == 1 then
		lastcfTxPower = cfTxPower
		lastcfTxDyn = cfTxDyn
		firstrun = 0
		extime = getTime()

	end
	
	if (lastcfTxDyn ~= cfTxDyn) and (extime+exdelay < getTime()) then
		
		print ("cftx "..extime.." [dynamic power ".. cfTxDyn .."]")
		print (cfTxPower ..':'.. cfTxDyn..':'..  cfTxDevice..':'..  playSounds..':'..  playBeep)
		
		-- play beep on activation
		if (playBeep == 1) then
			playTone(BeepFrequency,BeemLengthMiliseconds,0)
		end
		
		-- disable dynamic power
		if (lastcfTxDyn == 1) and (cfTxDyn == 0) then
			crossfireTelemetryPush(0x2D, { cfTxDevice, 0xEA, dynamicPowerAddr, cfTxDyn })
			if (playSounds == 1) then
				playFile("crsfDynOff.wav")
			end
		end
		
		-- enable dynamic power
		if (lastcfTxDyn == 0) and (cfTxDyn == 1) then
			crossfireTelemetryPush(0x2D, { cfTxDevice, 0xEA, dynamicPowerAddr, cfTxDyn })
			if (playSounds == 1) then
				playFile("crsfDynOn.wav")
			end
		end
		
		lastcfTxDyn = cfTxDyn
		extime = getTime()
	end
	
	-- change module power
	if (lastcfTxPower ~= cfTxPower) and (extime+exdelay < getTime()) then
		
		print ("cftx "..extime.." [tx power ".. cfTxPower .."]")
		print (cfTxPower ..':'.. cfTxDyn..':'..  cfTxDevice..':'..  playSounds..':'..  playBeep)
		
		-- play beep or sound
		if (playBeep == 1) then
			playTone(BeepFrequency,BeemLengthMiliseconds,0)
		end
		if (cfTxPower > lastcfTxPower) and (playSounds == 1) then
			playFile("crsfPowerInc.wav")
		end
		
		-- write telemetry
		crossfireTelemetryPush(0x2D, { cfTxDevice, 0xEA, maxPowerAddr, cfTxPower })

		-- save state and update execution time
		lastcfTxPower = cfTxPower
		extime = getTime()
	end
	
    return
end

return {input=cfinputs, run=cfrun}
