------------------------------
-- Variables     			--
------------------------------

local bossName = BigWigs.bossmods.naxx.kelthuzad
local module = BigWigs:GetModule(AceLibrary("Babble-Boss-2.2")[bossName])
local L = BigWigs.i18n[bossName]


-- module variables
module.revision = 20014 -- To be overridden by the module!
module.enabletrigger = module.translatedName -- string or table {boss, add1, add2}
--module.wipemobs = { L["add_name"] } -- adds which will be considered in CheckForEngage
module.toggleoptions = {"frostbolt", "frostboltbar", -1, "frostblast", "proximity", "fissure", "mc", "ktmreset", -1, "fbvolley", -1, "detonate", "detonateicon", -1 ,"guardians", -1, "addcount", "phase", "bosskill"}

-- Proximity Plugin
module.proximityCheck = function(unit) return CheckInteractDistance(unit, 2) end
module.proximitySilent = true


-- locals
module.timer = {
	phase1 = 320,
	firstFrostboltVolley = 30,
	frostboltVolley = 15,
	frostbolt = 2,
	phase2 = 15,
	firstDetonate = 35,
	detonate = 20,
	firstFrostblast = 45,
	mindcontrol = 60,
	guardians = 16,
	frostblast = 30,
	detonate = 5,
	nextDetonate = 20,
}
local timer = module.timer

module.icon = {
	abomination = "",
	soulWeaver = "",
	frostboltVolley = "Spell_Frost_FrostWard",
	mindcontrol = "Inv_Belt_18",
	phase1 = "",
	phase2 = "",
	guardians = "",
	frostblast = "Spell_Frost_FreezingBreath",
	detonate = "Spell_Nature_WispSplode",
	frostbolt = "Spell_Frost_FrostBolt02",
}
local icon = module.icon

module.syncName = {
	detonate = "KelDetonate",
	frostblast = "KelFrostBlast",
	frostbolt = "KelFrostbolt",
	frostboltOver = "KelFrostboltStop",
	frostboltVolley = "KelFrostboltVolley",
	fissure = "KelFissure",
	mindcontrol = "KelMindControl",
	abomination = "KelAddDiesAbom",
	soulWeaver = "KelAddDiesSoul",
	phase2 = "KelPhase2",
	phase3 = "KelPhase3",
	guardians = "KelGuardians",
}
local syncName = module.syncName


module.timeLastFrostboltVolley = 0    -- saves time of first frostbolt 
module.numFrostboltVolleyHits = 0	-- counts the number of people hit by frostbolt
module.numAbominations = 0	-- counter for Unstoppable Abomination's
module.numWeavers = 0 	-- counter for Soul Weaver's
module.timePhase1Start = 0    -- time of p1 start, used for tracking add count
module.warnedAboutPhase3Soon = nil
module.frostbolttime = 0


------------------------------
--      Synchronization	    --
------------------------------
function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.phase2 then
		self:Phase2()
	elseif sync == syncName.phase3 then
		self:Phase3()
	elseif sync == syncName.guardians then
		self:Guardians()
	elseif sync == syncName.mindcontrol then
		self:MindControl()
	elseif sync == syncName.frostblast then
		self:FrostBlast()
	elseif sync == syncName.detonate and rest then
		self:Detonate()
	elseif sync == syncName.frostbolt then       -- changed from only frostbolt (thats only alert, if someone still wants to see the bar, it wouldnt work then)
		self:Frostbolt()
	elseif sync == syncName.frostboltOver then
		self:FrostboltOver()
	elseif sync == syncName.frostboltVolley then
		self:FrostboltVolley()
	elseif sync == syncName.fissure then
		self:Fissure()
	elseif sync == syncName.abomination and rest then
		self:AbominationDies(rest)
	elseif sync == syncName.soulWeaver and rest then
		self:WeaverDies(rest)
	end
end


------------------------------
-- Sync Handlers	    	--
------------------------------
function module:Phase2()
	self:Bar(L["bar_phase2"], timer.phase2, icon.phase2, true, BigWigsColors.db.profile.start)
	self:Bar(L["bar_detonateNext"], timer.firstDetonate, icon.detonate)
	self:Bar(L["bar_mindControlAndFrostBlast"], timer.firstFrostblast, icon.frostblast)
	self:DelayedMessage(timer.phase2, L["msg_phase2Now"], "Important")
	self:DelayedMessage(timer.firstDetonate - 5, L["msg_detonateSoon"], "Important")
	self:DelayedMessage(timer.firstFrostblast - 5, L["msg_mindControlAndfrostblastSoon"], "Important")
	
	if self.db.profile.fbvolley then
		self:Bar(L["bar_frostboltVolley"], timer.firstFrostboltVolley, icon.frostboltVolley)
	end
	
	-- master target should be automatically set, as soon as a raid assistant targets kel'thuzad
	self:KTM_Reset()
	
	-- proximity silent
	self:Proximity()
end

function module:Phase3()
	if self.db.profile.phase then
		self:Message(L["msg_phase3Now"], "Attention", nil, "Beware")
	end
end

function module:MindControl()
	self:Message(L["msg_mindControl"], "Urgent", nil, "Beware")
	self:Bar(L["bar_mindControl"], timer.mindcontrol, icon.mindcontrol, true, BigWigsColors.db.profile.mindControl)
	
	self:KTM_Reset()
end

function module:Guardians()
	if self.db.profile.guardians then
		self:Message(L["msg_guardians"], "Important")
		self:Bar(L["bar_guardians"], timer.guardians, icon.guardians, true, BigWigsColors.db.profile.start)
	end
end

function module:FrostBlast()
	self:Message(L["msg_frostblast"], "Attention")
	self:DelayedMessage(timer.frostblast - 5, L["msg_frostblastSoon"])
	self:Bar(L["bar_frostBlast"], timer.frostblast, icon.frostblast)
end

function module:Detonate(name)
	if name and self.db.profile.detonate then
		self:Message(string.format(L["msg_detonateNow"], name), "Attention")
		if self.db.profile.detonateicon then 
			self:Icon(name, -1, timer.detonate) 
		end
		self:Bar(string.format(L["bar_detonateNow"], name), timer.detonate, icon.detonate)
		self:Bar(L["bar_detonateNext"], timer.nextDetonate, icon.detonate)
	end
end

function module:Frostbolt()
	if self.db.profile.frostbolt or self.db.profile.frostboltbar then
		module.frostbolttime = GetTime()
		if self.db.profile.frostbolt then
			self:Message(L["msg_frostbolt"], "Personal")
		end
		if self.db.profile.frostboltbar then
			self:Bar(L["bar_frostbolt"], timer.frostbolt, icon.frostbolt, true, BigWigsColors.db.profile.interrupt)
		end
	end
end

function module:FrostboltOver()
	if self.db.profile.frostbolt then
		self:RemoveBar(L["bar_frostbolt"])
		module.frostbolttime = 0
	end
end

function module:FrostboltVolley()
	if self.db.profile.fbvolley then
		self:Bar(L["bar_frostboltVolley"], timer.frostboltVolley, icon.frostboltVolley)
		
		--[[self:CancelScheduledEvent("bwfbvolley30")
		self:CancelScheduledEvent("bwfbvolley45")
		self:CancelScheduledEvent("bwfbvolley60") 
		self:ScheduleEvent("bwfbvolley30", self.Volley, 15, self)
		self:ScheduleEvent("bwfbvolley45", self.Volley, 30, self)
		self:ScheduleEvent("bwfbvolley60", self.Volley, 45, self) ]] -- why 3 times?
		
		self:CancelDelayedBar(L["bar_frostboltVolley"])
		self:DelayedBar(timer.frostboltVolley, L["bar_frostboltVolley"], timer.frostboltVolley, icon.frostboltVolley)
	end
end

function module:Fissure()
	if self.db.profile.fissure then
		self:Message(L["msg_fissure"], "Urgent", true, "Alarm")
		-- add bar?
	end
end

function module:AbominationDies(name)
	if name and self.db.profile.addcount then
		self:RemoveBar(string.format(L["bar_add"], module.numAbominations, name))
		module.numAbominations = module.numAbominations + 1
		if module.numAbominations < 14 then 
			self:Bar(string.format(L["bar_add"], module.numAbominations, name), (module.timePhase1Start + timer.phase1 - GetTime()), icon.abomination) 
		end	
	end
end

function module:WeaverDies(name)
	if name and self.db.profile.addcount then
		self:RemoveBar(string.format(L["bar_add"], module.numWeavers, name))
		module.numWeavers = module.numWeavers + 1
		if module.numWeavers < 14 then 
			self:Bar(string.format(L["bar_add"], module.numWeavers, name), (module.timePhase1Start + timer.phase1 - GetTime()), icon.soulWeaver) 
		end
	end
end


----------------------------------
-- Module Test Function    		--
----------------------------------

-- automated test
function module:TestModuleCore()
	-- check core functions	
	module:WeaverDies("test")
	module:AbominationDies("test")
	module:Fissure()
	module:FrostboltVolley()
	module:FrostboltOver()
	module:Frostbolt()
	module:Detonate("test")
	module:FrostBlast()
	module:Guardians()
	module:MindControl()
	module:Phase3()
	module:Phase2()
	
	module:BigWigs_RecvSync(syncName.phase2)
	module:BigWigs_RecvSync(syncName.phase3)
	module:BigWigs_RecvSync(syncName.guardians)
	module:BigWigs_RecvSync(syncName.mindcontrol)
	module:BigWigs_RecvSync(syncName.frostblast)
	module:BigWigs_RecvSync(syncName.detonate, "test")
	module:BigWigs_RecvSync(syncName.frostbolt)
	module:BigWigs_RecvSync(syncName.frostboltOver)
	module:BigWigs_RecvSync(syncName.frostboltVolley)
	module:BigWigs_RecvSync(syncName.fissure)
	module:BigWigs_RecvSync(syncName.abomination, "test")
	module:BigWigs_RecvSync(syncName.soulWeaver, "test")
end
