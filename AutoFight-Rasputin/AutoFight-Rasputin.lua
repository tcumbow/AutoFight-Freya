local ADDON_NAME = "AutoFight-Rasputin"
local ADDON_VERSION = "1.0"
local ADDON_AUTHOR = "Tom Cumbow"

local RawPlayerName = GetRawUnitName("player")
local Mounted = false
local Moving = false
local MajorSorcery = false
local MajorProphecy = false
local MinorSorcery = false
local MajorResolve = false
local MinorMending = false
local MeditationActive = false
local ImbueWeaponActive = false
local DamageShieldActive = false
local MajorGallop = false
local MajorExpedition = false
local Empower = false
local SkeletonMageActive = false
local SpiritMenderActive = false
local FamiliarActive = false
local FamiliarAOEActive = false
local TwilightActive = false
local CrystalWeaver = false
local CrystalFragmentsProc = false
local DnInfernoActive = false
local EnergyOverloadActive = false

local MagickaPercent = 1.00
local StaminaPercent = 1.00
local HealthPercent = 1.00
local Stamina = 0
local StaminaPrevious = 0
local Health = 0
local HealthPrevious = 0
local Ultimate = 0
local UltimatePercent = 1.00

local LowestGroupHealthPercentWithoutRegen = 1.00
local LowestGroupHealthPercentWithRegen = 1.00
local LowestGroupHealthPercent = 1.00


local InputReady = true
local InCombat = false
local InventoryFull = false
local PotionReady = false
local PotionName
local Feared = false
local Stunned = false
local MustDodge = false
local MustInterrupt = false
local MustBreakFree = false
local MustBlock = false
local Sprinting = false
local Hidden = false
local Crouching = false
local CrouchWasAuto = false
local CurrentBar = 0
local OtherBar = 0

local LastStealSightTime = 0
local LastEnemySightTime = 0
-- local LastStationaryTime = 0

local CurrentPixel = 0
local PreviousPixel = 0

local TargetNotTaunted = false
local TargetIsNotPlayer = false
local TargetIsEnemy = false
local TargetIsBoss = false
local TargetNotSunFired = false
local TargetNotMajorBreach = false
local TargetMaxHealth = 0
local TargetHealth = 0
local TargetHealthPercent = 0
local TargetIsNotSoulTrap = false
local TargetIsNotDestructiveTouched = false
local TargetNotFury = false
local TargetNotMagSteal = false

local AvailableReticleInteraction = nil
local AvailableReticleTarget = nil

local PickpocketPrime = false

local FrontBar, BackBar = false, false
local InBossBattle = false
local ReelInFish = false
local ShouldSprint = false

local BurstHeal = { }
local SelfHeal = { }
local HealOverTime = { }
local SkeletonMage = { }
local SpiritMender = { }
local Degeneration = { }
local Ritual = { }
local RemoteInterrupt = { }
local Taunt = { }
local SunFire = { }
local MagMajorResolveSkill = { }
local Meditation = { }
local ImbueWeapon = { }
local DamageShield = { }
local RapidManeuver = { }
local Accelerate = { }
local WeaknessToElements = { }
local UnstableWall = { }
local SoulTrap = { }
local DestructiveTouch = { }
local MagDpsSpamSkill = { }
local Pokes = { }
local SolarBarrage = { }
local VolatileFamiliar = { }
local TwilightMatriarch = { }
local MagMajSorc = { }
local RadiantAura = { }
local BoundlessStorm = { }
local CrystalFragments = { }
local Fury = { }
local InnerLight = { }
local DnInferno = { }

local EnergyOverload = { }

local DoNothing = 0
-- 1 thru 5 are used for doing abilities 1 thru 5, based on the number assigned in UpdateAbilitySlotInfo()
local DoHeavyAttack = 6
local DoRollDodge = 7
local DoBreakFreeInterrupt = 8
local DoBlock = 9
local DoReelInFish = 10
local DoLightAttack = 11
local DoInteract = 12
local DoSprint = 13
local DoMountSprint = 14
local DoCrouch = 15
local DoFrontBar = 16
local DoBackBar = 17
local DoStartBlock = 18
local DoStopBlock = 19
local DoUltimate = 20
local DoQuickslot = 21


local function PreventAttackingInnocents()
	SetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS, 1)
end
local function AllowAttackingInnocents()
	SetSetting(SETTING_TYPE_COMBAT, COMBAT_SETTING_PREVENT_ATTACKING_INNOCENTS, 0)
end

local function OnEventCombatStateChanged(event, inCombat)
	InCombat = inCombat
	if InCombat then
		AllowAttackingInnocents()
		UpdateAbilitySlotInfo()
	else
		PreventAttackingInnocents()
		InBossBattle = false
	end
	BigLogicRoutine()
end

local function PD_RegisterForEvents()
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GAME_CAMERA_UI_MODE_CHANGED, OnEventUiModeChanged)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE, OnEventCombatStateChanged)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_MOUNTED_STATE_CHANGED, OnEventMountedStateChanged)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_EFFECT_CHANGED, OnEventEffectChanged)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_POWER_UPDATE, OnEventPowerUpdate)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_SUPPORT_RANGE_UPDATE, OnEventGroupSupportRangeUpdate)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_DISPLAY_ACTIVE_COMBAT_TIP, OnEventCombatTipDisplay)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_REMOVE_ACTIVE_COMBAT_TIP, OnEventCombatTipRemove)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_STUNNED_STATE_CHANGED, OnEventStunStateChanged)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, OnEventCombatEvent)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_RETICLE_TARGET_CHANGED, OnEventReticleChanged)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_WEAPON_PAIR_LOCK_CHANGED, OnEventBarSwap)
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ACTION_SLOT_UPDATED, OnEventBarSwap)
	-- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SKILL_BUILD_SELECTION_UPDATED, OnEventAbilityChange) -- Turns out this isn't the right event, I'm just going to update abilities when combat begins
	-- EVENT_MANAGER:AddFilterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
end


local function InitialInfoGathering()
	PreventAttackingInnocents()
	BindRequiredKeys()
	InCombat = IsUnitInCombat("player")
	Mounted = IsMounted()
	UpdateBarState()
	UpdateAbilitySlotInfo()
	PD_RegisterForEvents()
	UpdateBuffs()
end

local ETA = 0
local MyMagicka
local MyMaxMagicka
local MyHealth
local MyMaxHealth

local function UnitHasRegen(unitTag)
	local numBuffs = GetNumBuffs(unitTag)
	if numBuffs > 0 then
		for i = 1, numBuffs do
			local name, _, _, _, _, _, _, _, _, _, _, _ = GetUnitBuffInfo(unitTag, i)
			if name=="Rapid Regeneration" or name=="Radiating Regeneration" then
				return true
			end
		end
	end
	return false
end

local function UpdateLowestGroupHealth()
	GroupSize = GetGroupSize()
	LowestGroupHealthPercentWithoutRegen = 1.00
	LowestGroupHealthPercentWithRegen = 1.00
	LowestGroupHealthPercent = 1.00

	if GroupSize > 0 then
		for i = 1, GroupSize do
			local unitTag = GetGroupUnitTagByIndex(i)
			local currentHp, maxHp, effectiveMaxHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
			local HpPercent = currentHp / maxHp
			local HasRegen = UnitHasRegen(unitTag)
			local InHealingRange = IsUnitInGroupSupportRange(unitTag)
			local IsAlive = not IsUnitDead(unitTag)
			local IsPlayer = GetUnitType(unitTag) == 1
			if HpPercent < LowestGroupHealthPercent and InHealingRange and IsAlive and IsPlayer then
				LowestGroupHealthPercent = HpPercent
			end
			if HpPercent < LowestGroupHealthPercentWithoutRegen and HasRegen == false and InHealingRange and IsAlive and IsPlayer then
				LowestGroupHealthPercentWithoutRegen = HpPercent
			elseif HpPercent < LowestGroupHealthPercentWithRegen and HasRegen and InHealingRange and IsAlive and IsPlayer then
				LowestGroupHealthPercentWithRegen = HpPercent
			end
		end
	else
		local unitTag = "player"
		local currentHp, maxHp, effectiveMaxHp = GetUnitPower(unitTag, POWERTYPE_HEALTH)
		local HpPercent = currentHp / maxHp
		LowestGroupHealthPercent = HpPercent
		local HasRegen = UnitHasRegen(unitTag)
		if HasRegen == false then
			LowestGroupHealthPercentWithoutRegen = HpPercent
		elseif HasRegen then
			LowestGroupHealthPercentWithRegen = HpPercent
		end
	end
end


local function UpdateBuffs()
	-- MajorSorcery = false
	-- MajorProphecy = false
	-- MinorSorcery = false
	-- MajorResolve = false
	-- MinorMending = false
	-- MeditationActive = false
	-- ImbueWeaponActive = false
	DamageShieldActive = false
	-- MajorGallop = false
	-- MajorExpedition = false
	-- Empower = false
	-- SkeletonMageActive = false
	-- SpiritMenderActive = false
	FamiliarActive = false
	FamiliarAOEActive = false
	TwilightActive = false
	-- CrystalWeaver = false
	CrystalFragmentsProc = false
	-- DnInfernoActive = false
	-- EnergyOverloadActive = false
	-- -- MustBreakFree = false
	local numBuffs = GetNumBuffs("player")
	if numBuffs > 0 then
		for i = 1, numBuffs do
			local name, _, endTime, _, _, _, _, _, _, _, id, _ = GetUnitBuffInfo("player", i)
			-- local now = GetGameTimeMilliseconds()
			-- local timeLeft = (math.floor(endTime * 1000)) - now
			-- if name=="Major Sorcery" then
			-- 	MajorSorcery = true
			-- elseif name=="Major Prophecy" then
			-- 	MajorProphecy = true
			-- elseif name=="Minor Sorcery" then
			-- 	MinorSorcery = true
			-- elseif name=="Major Resolve" and timeLeft>optimalBuffOverlap then
			-- 	MajorResolve = true
			-- 	if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			-- elseif name=="Minor Mending" then
			-- 	MinorMending = true
			-- elseif name=="Deep Thoughts" then
			-- 	MeditationActive = true
			-- elseif name=="Elemental Weapon" and (timeLeft + 100) > optimalBuffOverlap then
			-- 	ImbueWeaponActive = true
			-- 	if timeLeft + 100 < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft + 100 end
			if name=="Blazing Shield" or name=="Radiant Ward" or name=="Conjured Ward" or name=="Empowered Ward" then
				DamageShieldActive = true
			elseif name=="Summon Volatile Familiar" and id==23316 then
				FamiliarActive = true
			elseif name=="Volatile Pulse" or (name=="Summon Volatile Familiar" and id==88933) then
				FamiliarAOEActive = true
			elseif name=="Summon Twilight Matriarch" then
				TwilightActive = true
			-- elseif name=="Crystal Weaver" then
			-- 	CrystalWeaver = true
			elseif name=="Crystal Fragments Proc" then
				CrystalFragmentsProc = true
			-- elseif name=="Flames of Oblivion" then
			-- 	DnInfernoActive = true
			-- elseif name=="Energy Overload" then
			-- 	EnergyOverloadActive = true
			-- elseif name=="Dampen Magic" then
			-- 	DamageShieldActive = true
			-- elseif name=="Empower" then
			-- 	Empower = true
			-- elseif name=="Skeletal Arcanist" then
			-- 	SkeletonMageActive = true
			-- elseif name=="Spirit Mender" then
			-- 	SpiritMenderActive = true
			-- elseif name=="Major Expedition" and timeLeft>optimalBuffOverlap then
			-- 	MajorExpedition = true
			-- 	if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			-- elseif name=="Major Gallop" and timeLeft>optimalBuffOverlap then
			-- 	MajorGallop = true
			-- 	if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			end
		end
		-- if msUntilBuffRecheckNeeded < 999999 then
		-- 	zo_callLater(UpdateBuffs, msUntilBuffRecheckNeeded-optimalBuffOverlap)
		-- end
	end
	-- BigLogicRoutine()
end

local function AutoFightMain()
	if not IsUnitInCombat('player') then return end
	if IsReticleHidden() or IsUnitSwimming('player') then return end
	
	if ETA > GetGameTimeMilliseconds() then return end

	UpdateLowestGroupHealth()
	UpdateBuffs()
	MyMagicka, MyMaxMagicka = GetUnitPower('player', POWERTYPE_MAGICKA)

	-- MyHealth, MyMaxHealth = GetUnitPower('player', POWERTYPE_HEALTH)

	if not TwilightActive and MyMagicka > 3500 then
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_1,50)
		ETA = GetGameTimeMilliseconds() + 2000
	end

	if LowestGroupHealthPercent < 0.40 and TwilightActive and MyMagicka > 3500 then
		if not IsBlockActive() then LibPixelControl.SetIndOnFor(LibPixelControl.VM_BTN_RIGHT,1100) end
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_1,50)
		ETA = GetGameTimeMilliseconds() + 1100
	end

	if CrystalFragmentsProc and GetUnitReaction('reticleover') == UNIT_REACTION_HOSTILE and MyMagicka > 3500 then
		if not IsBlockActive() then LibPixelControl.SetIndOnFor(LibPixelControl.VM_BTN_RIGHT,1100) end
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_4,50)
		ETA = GetGameTimeMilliseconds() + 600
	end

	if not DamageShieldActive and MyMagicka > 10000 then
		if not IsBlockActive() then LibPixelControl.SetIndOnFor(LibPixelControl.VM_BTN_RIGHT,1100) end
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_3,50)
		ETA = GetGameTimeMilliseconds() + 1100
	end

	if not FamiliarActive and MyMagicka > 20000 then
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_2,50)
		ETA = GetGameTimeMilliseconds() + 2000
	end
	
	if FamiliarActive and not FamiliarAOEActive and MyMagicka > 20000 then
		if not IsBlockActive() then LibPixelControl.SetIndOnFor(LibPixelControl.VM_BTN_RIGHT,1100) end
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_2,50)
		ETA = GetGameTimeMilliseconds() + 1100
	end

	if GetUnitReaction('reticleover') == UNIT_REACTION_HOSTILE and MyMagicka > 10000 then
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_4,50)
		ETA = GetGameTimeMilliseconds() + 1500
	end

	
end

local function OnAddonLoaded(event, name)
	if name == ADDON_NAME then
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, event)
		EVENT_MANAGER:RegisterForUpdate(ADDON_NAME, 100, AutoFightMain)
	end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
