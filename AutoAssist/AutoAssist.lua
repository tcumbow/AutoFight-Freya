local ADDON_NAME = "AutoAssist"
local ADDON_VERSION = "1.0"
local ADDON_AUTHOR = "Tom Cumbow"
local Config = { }

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


local function SetPixel(x)
	PDL:SetColor(0,0,(x/255))
	PreviousPixel = CurrentPixel
	CurrentPixel = x
	-- d(x)
end

local function DoAbility(ability)
	if ability[CurrentBar] then return ability[CurrentBar]
	elseif ability[OtherBar] then return (16+OtherBar)
	else d("Impossible situation in DoAbility function")
	end
end

local function UpdateLastSights()
	if TargetIsEnemy then LastEnemySightTime = GetGameTimeMilliseconds() end
	if AvailableReticleInteraction == "Steal" or AvailableReticleInteraction == "BlockedSteal" then LastStealSightTime = GetGameTimeMilliseconds() end
	--if not IsPlayerMoving() then LastStationaryTime = GetGameTimeMilliseconds() end
end

local function GetPotionIsReady()
	local timeRemaining, _, global, _ = GetSlotCooldownInfo(GetCurrentQuickslot())
	local potionsAvailable = GetSlotItemCount(GetCurrentQuickslot())
	if potionsAvailable==nil then return false end
	if timeRemaining==0 and global and potionsAvailable > 0 then
		return true
	else
		return false
	end
end

local function UpdateAbilitySlotInfo()

	BurstHeal = { }
	SelfHeal = { }
	HealOverTime = { }
	SkeletonMage = { }
	SpiritMender = { }
	Degeneration = { }
	Ritual = { }
	RemoteInterrupt = { }
	Taunt = { }
	SunFire = { }
	MagMajorResolveSkill = { }
	Meditation = { }
	ImbueWeapon = { }
	DamageShield = { }
	RapidManeuver = { }
	Accelerate = { }
	WeaknessToElements = { }
	UnstableWall = { }
	SoulTrap = { }
	DestructiveTouch = { }
	MagDpsSpamSkill = { }
	Pokes = { }
	SolarBarrage = { }
	VolatileFamiliar = { }
	TwilightMatriarch = { }
	MagMajSorc = { }
	RadiantAura = { }
	BoundlessStorm = { }
	CrystalFragments = { }
	Fury = { }
	InnerLight = { }
	DnInferno = { }

	EnergyOverload = { }

	for barNumIterator = 0, 1 do
		if Config.SwapBars or barNumIterator==CurrentBar then -- only examine current bar unless SwapBars is true
			for i = 3, 7 do
				local AbilityName = GetAbilityName(GetSlotBoundId(i,barNumIterator))
				if AbilityName == "Ritual of Rebirth" or AbilityName == "Twilight Matriarch Restore" then
					BurstHeal.Slotted = true
					BurstHeal[barNumIterator] = i-2
				elseif AbilityName == "Polar Wind" or AbilityName == "Green Dragon Blood" then
					SelfHeal.Slotted = true
					SelfHeal[barNumIterator] = i-2
				elseif AbilityName == "Rapid Regeneration" or AbilityName == "Radiating Regeneration" then
					HealOverTime.Slotted = true
					HealOverTime[barNumIterator] = i-2
				elseif AbilityName == "Skeletal Arcanist" then
					SkeletonMage.Slotted = true
					SkeletonMage[barNumIterator] = i-2
				elseif AbilityName == "Spirit Mender" then
					SpiritMender.Slotted = true
					SpiritMender[barNumIterator] = i-2
				elseif AbilityName == "Inner Rage" then
					Taunt.Slotted = true
					Taunt[barNumIterator] = i-2
				elseif AbilityName == "Deep Thoughts" then
					Meditation.Slotted = true
					Meditation[barNumIterator] = i-2
				elseif AbilityName == "Elemental Weapon" then
					ImbueWeapon.Slotted = true
					ImbueWeapon[barNumIterator] = i-2
				elseif AbilityName == "Channeled Focus" or AbilityName == "Restoring Focus" or AbilityName == "Summoner's Armor" or AbilityName == "Expansive Frost Cloak" then
					MagMajorResolveSkill.Slotted = true
					MagMajorResolveSkill[barNumIterator] = i-2
				elseif AbilityName == "Extended Ritual" then
					Ritual.Slotted = true
					Ritual[barNumIterator] = i-2
				elseif AbilityName == "Degeneration" then
					Degeneration.Slotted = true
					Degeneration[barNumIterator] = i-2
				elseif AbilityName == "Vampire's Bane" or AbilityName == "Reflective Light" then
					SunFire.Slotted = true
					SunFire[barNumIterator] = i-2
				elseif AbilityName == "Radiant Ward" or AbilityName == "Blazing Shield" or AbilityName == "Conjured Ward" or AbilityName == "Empowered Ward" then
					DamageShield.Slotted = true
					DamageShield[barNumIterator] = i-2
				elseif AbilityName == "Explosive Charge" then
					RemoteInterrupt.Slotted = true
					RemoteInterrupt[barNumIterator] = i-2
				elseif AbilityName == "Rapid Maneuver" or AbilityName == "Charging Maneuver" then
					RapidManeuver.Slotted = true
					RapidManeuver[barNumIterator] = i-2
				elseif AbilityName == "Accelerate" or AbilityName == "Race Against Time" then
					Accelerate.Slotted = true
					Accelerate[barNumIterator] = i-2
				elseif AbilityName == "Elemental Drain" or AbilityName == "Elemental Susceptibility" or AbilityName == "Weakness to Elements" then
					WeaknessToElements.Slotted = true
					WeaknessToElements[barNumIterator] = i-2
				elseif AbilityName == "Unstable Wall of Storms" then
					UnstableWall.Slotted = true
					UnstableWall[barNumIterator] = i-2
				elseif AbilityName == "Soul Trap" or AbilityName == "Soul Splitting Trap" or AbilityName == "Consuming Trap" then
					SoulTrap.Slotted = true
					SoulTrap[barNumIterator] = i-2
				elseif AbilityName == "Destructive Touch" or AbilityName == "Shock Touch" or AbilityName == "Destructive Reach" or AbilityName == "Shock Reach" then
					DestructiveTouch.Slotted = true
					DestructiveTouch[barNumIterator] = i-2
				elseif AbilityName == "Force Shock" or AbilityName == "Force Pulse" or AbilityName == "Crushing Shock" or AbilityName == "Ricochet Skull" or AbilityName == "Piercing Javelin" or AbilityName == "Aurora Javelin" or AbilityName == "Solar Flare" or AbilityName == "Dark Flare" then
					MagDpsSpamSkill.Slotted = true
					MagDpsSpamSkill[barNumIterator] = i-2
				elseif AbilityName == "Puncturing Sweep" then
					Pokes.Slotted = true
					Pokes[barNumIterator] = i-2
				elseif AbilityName == "Solar Barrage" then
					SolarBarrage.Slotted = true
					SolarBarrage[barNumIterator] = i-2
				elseif AbilityName == "Summon Volatile Familiar" then
					VolatileFamiliar.Slotted = true
					VolatileFamiliar[barNumIterator] = i-2
				elseif AbilityName == "Summon Twilight Matriarch" then
					TwilightMatriarch.Slotted = true
					TwilightMatriarch[barNumIterator] = i-2
				elseif AbilityName == "Boundless Storm" then
					BoundlessStorm.Slotted = true
					BoundlessStorm[barNumIterator] = i-2
					Accelerate.Slotted = true
					Accelerate[barNumIterator] = i-2
				elseif AbilityName == "Crystal Fragments" then
					CrystalFragments.Slotted = true
					CrystalFragments[barNumIterator] = i-2
				elseif AbilityName == "Endless Fury" then
					Fury.Slotted = true
					Fury[barNumIterator] = i-2
				elseif AbilityName == "Inner Light" then
					InnerLight.Slotted = true
					InnerLight[barNumIterator] = i-2
				elseif AbilityName == "Inferno" or AbilityName == "Flames of Oblivion" then
					DnInferno.Slotted = true
					DnInferno[barNumIterator] = i-2
				elseif AbilityName == "Surge" or AbilityName == "Power Surge" or AbilityName == "Critical Surge" or AbilityName == "Blue Betty" or AbilityName == "Molten Armaments" then
					MagMajSorc.Slotted = true
					MagMajSorc[barNumIterator] = i-2
				elseif AbilityName == "Radiant Aura" then
					RadiantAura.Slotted = true
					RadiantAura[barNumIterator] = i-2
				elseif AbilityName == "Efficient Purge" or AbilityName == "Revealing Flare" or AbilityName == "Bound Aegis" or AbilityName == "Blockade of Storms" or AbilityName == "" then -- do nothing, cuz we don't care about these abilities
				else
					d("Unrecognized ability:"..AbilityName)
				end
			end
			local AbilityId = GetSlotBoundId(8,barNumIterator)
			local UltimateName = GetAbilityName(AbilityId)
			if UltimateName == "Energy Overload" then
				EnergyOverload.Slotted = true
				EnergyOverload[barNumIterator] = DoUltimate
				EnergyOverload.Cost = GetAbilityCost(AbilityId)
			end
		end
	end
end


local function BigLogicRoutine()
	-- Last-Minute Info Gathering
		UpdateLastSights()
		Moving = IsPlayerMoving()
		if not Moving then Sprinting = false end
		if (GetGameTimeMilliseconds() - LastEnemySightTime) > 3000 then EnemiesAround = false else EnemiesAround = true	end
		PotionReady = GetPotionIsReady()
		PotionName = GetSlotName(GetCurrentQuickslot())
		UpdateAbilitySlotInfo()

	-- Mounted/Dead/InMenu
		if InputReady == false or IsUnitDead("player") then
			SetPixel(DoNothing)
		elseif Config.Loot and not TFC_AUTOLOOT_LOADED and Config.PlatinumDismount and AvailableReticleInteraction=="Mine" and AvailableReticleTarget=="Platinum Seam" then
			SetPixel(DoInteract)
		elseif Config.Gallop and RapidManeuver.Slotted and Mounted and not MajorGallop and StaminaPercent > 0.80 then
			SetPixel(DoAbility(RapidManeuver))
		elseif Config.MountSprint and Mounted and Moving and not Sprinting then
			SetPixel(DoMountSprint)
		elseif Mounted then
			SetPixel(DoNothing)

	-- Combat: Healing
		elseif Config.BreakFree and (Stunned or Feared) and StaminaPercent > 0.49 then
			SetPixel(DoBreakFreeInterrupt)
		elseif Config.Healing and TwilightMatriarch.Slotted and not TwilightActive and InCombat and LowestGroupHealthPercent < 0.70 and not Crouching then
			SetPixel(DoAbility(TwilightMatriarch))
		elseif Config.Healing and BurstHeal.Slotted and LowestGroupHealthPercent < 0.40 and not Crouching then
			SetPixel(DoAbility(BurstHeal))
		elseif Config.Healing and BurstHeal.Slotted and LowestGroupHealthPercent < 0.60 and MagickaPercent > 0.40 and not Crouching then
			SetPixel(DoAbility(BurstHeal))
		elseif Config.Healing and HealOverTime.Slotted and LowestGroupHealthPercentWithoutRegen < 0.90 and InCombat and not Crouching then
			SetPixel(DoAbility(HealOverTime))
		elseif Config.Healing and BurstHeal.Slotted and not HealOverTime.Slotted and LowestGroupHealthPercent < 0.80 and MagickaPercent > 0.50 and not Crouching then
			SetPixel(DoAbility(BurstHeal))
		elseif Config.Healing and SpiritMender.Slotted and not SpiritMenderActive and LowestGroupHealthPercent < 0.90 and MagickaPercent > 0.30 and InCombat and not Crouching then
			SetPixel(DoAbility(SpiritMender))
		elseif Config.Healing and SelfHeal.Slotted and HealthPercent < 0.70 and MagickaPercent > 0.30 and not Crouching then
			SetPixel(DoAbility(SelfHeal))
		elseif Config.PotionSpell and PotionReady and MagickaPercent < 0.10 and (PotionName=="Essence of Spell Power" or PotionName=="Essence of Spell Critical") and InCombat then
			SetPixel(DoQuickslot)
		elseif Config.PotionTri and PotionReady and PotionName=="Crown Tri-Restoration Potion" and InCombat and (MagickaPercent < 0.50 or HealthPercent < 0.50 or StaminaPercent < 0.50) then
			SetPixel(DoQuickslot)

	-- Combat: High Priority (Procs, Interrupt, Dodge, Block)
		elseif Config.RemoteInterrupt and RemoteInterrupt.Slotted and MustInterrupt and MagickaPercent > 0.49 and not Crouching then
			SetPixel(DoAbility(RemoteInterrupt))
		elseif Config.DamageAbils and Fury.Slotted and TargetNotFury and TargetHealthPercent < 0.50 and TargetHealthPercent > 0.20 and TargetIsEnemy and not TargetIsBoss and not Crouching then
			SetPixel(DoAbility(Fury))
		elseif Config.Interrupt and MustInterrupt and StaminaPercent > 0.49 and not Crouching then
			SetPixel(DoBreakFreeInterrupt)
		elseif Config.TauntBosses and Taunt.Slotted and TargetIsBoss and TargetNotTaunted and MagickaPercent > 0.30 and InCombat and not Crouching then
			SetPixel(DoAbility(Taunt))
		elseif Config.Block and MustBlock and StaminaPercent > 0.99 then
			SetPixel(DoBlock)
		elseif Config.Dodge and MustDodge and StaminaPercent > 0.99 then
			SetPixel(DoRollDodge)
		elseif ImbueWeaponActive == true and InCombat and TargetIsEnemy and not Crouching then
			SetPixel(DoLightAttack)
		elseif CrystalFragmentsProc and CrystalFragments.Slotted and MagickaPercent > 0.30 and EnemiesAround and InCombat and not Crouching then
			SetPixel(DoAbility(CrystalFragments))

	-- Combat: Medium Priority (Buffs, DoTs, Looting, Meditation)
		elseif Config.PotionSpell and PotionReady and (PotionName=="Essence of Spell Power" or PotionName=="Essence of Spell Critical") and not MajorProphecy and not SunFire.Slotted and not InnerLight.Slotted and InCombat then
			SetPixel(DoQuickslot)
		elseif Config.Overload and EnergyOverload.Slotted and not EnergyOverloadActive and MagickaPercent < 0.40 and Ultimate > (EnergyOverload.Cost * 5) and InCombat and not Crouching then
			SetPixel(DoAbility(EnergyOverload))
		elseif (Config.Buffs or Config.Healing) and Ritual.Slotted and not MinorMending and InCombat and MagickaPercent > 0.55 and not Crouching then
			SetPixel(DoAbility(Ritual))
		elseif Config.Buffs and MagMajorResolveSkill.Slotted and not MajorResolve and MagickaPercent > 0.50 and (InCombat or EnemiesAround) and not Crouching then
			SetPixel(DoAbility(MagMajorResolveSkill))
		elseif Config.Buffs and BoundlessStorm.Slotted and not MajorResolve and MagickaPercent > 0.50 and (InCombat or EnemiesAround) and not Crouching then --merge with skill above?
			SetPixel(DoAbility(BoundlessStorm))
		elseif Config.Loot and not TFC_AUTOLOOT_LOADED and (AvailableReticleInteraction=="Search" and not InventoryFull and AvailableReticleTarget~="Book Stack" and AvailableReticleTarget~="Bookshelf") then
			SetPixel(DoInteract)
		elseif Config.DamageAbils and SkeletonMage.Slotted and not SkeletonMageActive and MagickaPercent > 0.60 and InCombat and not Crouching then
			SetPixel(DoAbility(SkeletonMage))
		elseif Config.DamageAbils and VolatileFamiliar.Slotted and not FamiliarActive and MagickaPercent > 0.60 and (InCombat or EnemiesAround) and not Crouching then
			SetPixel(DoAbility(VolatileFamiliar))
		elseif Config.DamageAbils and VolatileFamiliar.Slotted and not FamiliarAOEActive and MagickaPercent > 0.60 and (InCombat or EnemiesAround) and not Crouching then
			SetPixel(DoAbility(VolatileFamiliar))
		elseif (Config.DamageAbils or Config.Buffs) and SoulTrap.Slotted and TargetIsNotSoulTrap and MagickaPercent > 0.50 and InCombat and TargetIsEnemy and not Crouching then
			SetPixel(DoAbility(SoulTrap))
		elseif (Config.DamageAbils or Config.Buffs) and RadiantAura.Slotted and TargetNotMagSteal and TargetIsEnemy and not Crouching then
			SetPixel(DoAbility(RadiantAura))
		elseif (Config.DamageAbils or Config.Buffs) and DnInferno.Slotted and not DnInfernoActive and MagickaPercent > 0.50 and (InCombat or EnemiesAround) and not Crouching then
			SetPixel(DoAbility(DnInferno))
		elseif Config.DamageAbils and SunFire.Slotted and TargetNotSunFired and MagickaPercent > 0.70 and InCombat and TargetIsEnemy and not Crouching then
			SetPixel(DoAbility(SunFire))
		elseif Config.DamageAbils and DestructiveTouch.Slotted and TargetIsNotDestructiveTouched and MagickaPercent > 0.70 and InCombat and TargetIsEnemy and not Crouching then
			SetPixel(DoAbility(DestructiveTouch))
		elseif Config.Buffs and MagMajSorc.Slotted and not MajorSorcery and MagickaPercent > 0.60 and (InCombat or EnemiesAround) and not Crouching then
			SetPixel(DoAbility(MagMajSorc))
		elseif Config.Buffs and Degeneration.Slotted and not MajorSorcery and MagickaPercent > 0.60 and InCombat and EnemiesAround and not Crouching then
			SetPixel(DoAbility(Degeneration))
		elseif (Config.Buffs or Config.DamageAbils) and WeaknessToElements.Slotted and TargetNotMajorBreach and TargetMaxHealth > 40000 and TargetIsEnemy and MagickaPercent > 0.60 and not Crouching then
			SetPixel(DoAbility(WeaknessToElements))
		elseif Config.Buffs and SunFire.Slotted and (MajorProphecy == false or MinorSorcery == false) and MagickaPercent > 0.60 and EnemiesAround and InCombat and not Crouching then
			SetPixel(DoAbility(SunFire))
		elseif DamageShield.Slotted and (InCombat == true or EnemiesAround) and DamageShieldActive == false and MagickaPercent > 0.50 and not Crouching then
			SetPixel(DoAbility(DamageShield))
		elseif MeditationActive and InCombat and (MagickaPercent < 0.98 or StaminaPercent < 0.98) then
			SetPixel(DoNothing)
		elseif Config.Meditation and Meditation.Slotted and (MagickaPercent < 0.80 or StaminaPercent < 0.80) and MeditationActive == false and InCombat and not Crouching then
			SetPixel(DoAbility(Meditation))

		elseif Config.SwapToInnerLight and InnerLight.Slotted and not MajorProphecy and not Crouching then
			SetPixel(16+OtherBar)
		elseif Config.Overload and EnergyOverloadActive and MagickaPercent > 0.70 and ((UltimatePercent < 0.70 and not InBossBattle) or (UltimatePercent < 0.40) ) and not Crouching then
			SetPixel(DoAbility(EnergyOverload))
		elseif Config.DamageAbils and UnstableWall.Slotted and MagickaPercent > 0.85 and InCombat and TargetIsEnemy and not Crouching then
			SetPixel(DoAbility(UnstableWall))
	-- Combat: Low Priority (Damage Spamming)
		-- elseif SunFire.Slotted and MagickaPercent > 0.80 and InCombat and EnemiesAround then
		-- 	SetPixel(DoAbility(SunFire))
		elseif Config.DamageAbils and MagDpsSpamSkill.Slotted and MagickaPercent > 0.80 and InCombat and EnemiesAround and not Crouching then
			SetPixel(DoAbility(MagDpsSpamSkill))
		elseif Config.DamageAbils and ImbueWeapon.Slotted and EnemiesAround and InCombat == true and ImbueWeaponActive == false and MagickaPercent > 0.80 and not Crouching then
			SetPixel(DoAbility(ImbueWeapon))
		elseif Config.DamageAbils and CrystalFragments.Slotted and EnemiesAround and InCombat == true and MagickaPercent > 0.80 and not Crouching then
			SetPixel(DoAbility(CrystalFragments))
		elseif Config.DamageAbils and Pokes.Slotted and MagickaPercent > 0.80 and InCombat and TargetIsEnemy and not Crouching then
			SetPixel(DoAbility(Pokes))
		elseif Config.DamageAbils and SolarBarrage.Slotted and MagickaPercent > 0.80 and InCombat and not Empower and EnemiesAround and not Crouching then
			SetPixel(DoAbility(SolarBarrage))
		elseif Config.Overload and EnergyOverload.Slotted and UltimatePercent > 0.97 and EnemiesAround and not EnergyOverloadActive and not Crouching then
			SetPixel(DoAbility(EnergyOverload))
		elseif Config.Overload and EnergyOverloadActive and TargetIsEnemy and InCombat and not Crouching then
			SetPixel(DoLightAttack)
		elseif Config.HeavyAttacks and InCombat and EnemiesAround and not ImbueWeaponActive and MagickaPercent < 0.85 and not EnergyOverloadActive and not Crouching then
			SetPixel(DoHeavyAttack)
		elseif Config.LightAttacks and InCombat and EnemiesAround and not EnergyOverloadActive and not Crouching then
			SetPixel(DoLightAttack)
		elseif Config.HeavyAttacks and InCombat and EnemiesAround and not ImbueWeaponActive and not EnergyOverloadActive and not Crouching then
			SetPixel(DoHeavyAttack)

	-- Environment Interaction (Looting, Stealing, Sprinting)
		elseif ReelInFish and not InCombat then
			SetPixel(DoReelInFish)
			zo_callLater(PD_StopReelInFish, 2000)
		elseif Config.Disarm and AvailableReticleInteraction=="Disarm" then
			SetPixel(DoInteract)
		elseif Config.Loot and not TFC_AUTOLOOT_LOADED and (AvailableReticleInteraction=="Destroy" or AvailableReticleInteraction=="Cut" or AvailableReticleInteraction=="Mine" or AvailableReticleInteraction=="Collect" or AvailableReticleInteraction=="Loot" or (AvailableReticleInteraction=="Take" and not (AvailableReticleTarget=="Spoiled Food" or AvailableReticleTarget=="Greatsword" or AvailableReticleTarget=="Sword" or AvailableReticleTarget=="Axe" or AvailableReticleTarget=="Bow" or AvailableReticleTarget=="Shield" or AvailableReticleTarget=="Staff" or AvailableReticleTarget=="Sabatons" or AvailableReticleTarget=="Jerkin" or AvailableReticleTarget=="Dagger" or AvailableReticleTarget=="Cuirass" or AvailableReticleTarget=="Pauldron" or AvailableReticleTarget=="Helm" or AvailableReticleTarget=="Gauntlets" or AvailableReticleTarget=="Guards" or AvailableReticleTarget=="Boots" or AvailableReticleTarget=="Shoes")) or (AvailableReticleInteraction=="Use" and (AvailableReticleTarget=="Chest" or AvailableReticleTarget=="Treasure Chest" or AvailableReticleTarget=="Giant Clam" or AvailableReticleTarget=="Skyshard"))) then
			SetPixel(DoInteract)
		elseif Config.Steal and AvailableReticleInteraction=="Steal" and Hidden and not InCombat and not InventoryFull then
			SetPixel(DoInteract)
		elseif Config.CrouchSteal and AvailableReticleInteraction=="Steal" and not Crouching and not InCombat and not InventoryFull then
			SetPixel(DoCrouch)
			CrouchWasAuto = true
		elseif (GetGameTimeMilliseconds() - LastStealSightTime) > 3000 and CrouchWasAuto and Crouching and Moving then
			SetPixel(DoCrouch)
		elseif Config.Pickpocket and PickpocketPrime and Hidden then
			SetPixel(DoInteract)
		elseif Config.Expedition and RapidManeuver.Slotted and not MajorExpedition and Moving and StaminaPercent > 0.90 then
			SetPixel(DoAbility(RapidManeuver))
		elseif Config.Expedition and Accelerate.Slotted and not MajorExpedition and MagickaPercent > 0.99 and Moving and not Crouching then
			SetPixel(DoAbility(Accelerate))
		elseif Config.Sprint and ShouldSprint and Moving and not Sprinting and not Crouching then
			SetPixel(DoSprint)
		-- elseif Config.Sprint and Sprinting and (not ShouldSprint or StaminaPercent < 0.80) and Moving and not Crouching then
		-- 	SetPixel(DoSprint)

	-- End of Logic
		else
			SetPixel(DoNothing)
		end

		if CurrentPixel ~= DoSprint and CurrentPixel ~= DoMountSprint and CurrentPixel ~= DoNothing then Sprinting = false end
end








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




local function UpdateTargetInfo()
	if (DoesUnitExist('reticleover') and not (IsUnitDead('reticleover'))) then -- have a target, scan for auras
		-- local unitName = zo_strformat("<<t:1>>",GetUnitName('reticleover'))

		if GetUnitType('reticleover') == 1 then
			TargetIsNotPlayer = false
		else
			TargetIsNotPlayer = true
		end

		if GetUnitReaction('reticleover') == UNIT_REACTION_HOSTILE then
			TargetIsEnemy = true
		else
			TargetIsEnemy = false
		end

		if GetUnitDifficulty("reticleover") >= 3 then
			TargetIsBoss = true
			InBossBattle = true
		else
			TargetIsBoss = false
		end

		local currentHp, maxHp, _ = GetUnitPower('reticleover', POWERTYPE_HEALTH)
		TargetHealth = currentHp
		TargetMaxHealth = maxHp
		TargetHealthPercent = currentHp/maxHp

		local numAuras = GetNumBuffs('reticleover')

		TargetNotSunFired = true
		TargetNotTaunted = true
		TargetNotMajorBreach = true
		TargetIsNotSoulTrap = true
		TargetIsNotDestructiveTouched = true
		TargetNotFury = true
		TargetNotMagSteal = true
		if (numAuras > 0) then
			for i = 1, numAuras do
				local name, _, _, _, _, _, _, _, _, _, _, _ = GetUnitBuffInfo('reticleover', i)
				if name=="Taunt" then
					TargetNotTaunted = false
				elseif name=="Vampire's Bane" or name=="Reflective Light" or name=="Sun Fire" then
					TargetNotSunFired = false
				elseif name=="Major Breach" then
					TargetNotMajorBreach = false
				elseif name=="Endless Fury" then
					TargetNotFury = false
				elseif name=="Minor Magickasteal" then
					TargetNotMagSteal = false
				elseif name=="Soul Trap" or name=="Soul Splitting Trap" or name=="Consuming Trap" then
					TargetIsNotSoulTrap = false
				elseif name == "Destructive Touch" or name == "Shock Touch" or name == "Destructive Reach" or name == "Shock Reach" then
					TargetIsNotDestructiveTouched = false
				end
			end
		end
	else
		TargetNotTaunted = false
		TargetIsEnemy = false
		TargetIsNotPlayer = false
		TargetNotSunFired = false
		TargetIsBoss = false
		TargetNotMajorBreach = false
		TargetNotFury = false
		TargetIsNotSoulTrap = false
		TargetIsNotDestructiveTouched = false
	end
end





local function UpdatePickpocketState()
	local isInBonus, isHostile, percentChance, _, isEmpty, prospectiveResult, _, _ = GetGameCameraPickpocketingBonusInfo()
	local cantInteract 	= isHostile or isEmpty or not prospectiveResult == PROSPECTIVE_PICKPOCKET_RESULT_CAN_ATTEMPT
	PickpocketPrime		= not cantInteract and percentChance == 100
end



local function UpdateBarState()
	local barNum = GetActiveWeaponPairInfo()
	if barNum == 1 then
		FrontBar = true
		BackBar = false
		CurrentBar = 0 --translating to match the zero-based bar numbering used by the ability routine above
		OtherBar = 1
	elseif barNum == 2 then
		BackBar = true
		FrontBar = false
		CurrentBar = 1
		OtherBar = 0
	end
end



local function DismissTwilight()
	-- All the abilityIDs for Twilights
	local PetList = { 24613, 30581, 30584, 30587, 24636, 30592, 30595, 30598, 24639, 30618, 30622, 30626 }

	local i, k, v

	-- Walk through the player's active buffs
	for i = 1, GetNumBuffs("player") do
		local buffName, timeStarted, timeEnding, buffSlot, stackCount, iconFilename, buffType, effectType, abilityType, statusEffectType, abilityId, canClickOff = GetUnitBuffInfo("player", i)
		-- Compare each buff's abilityID to the list of IDs we were given
		for k, v in pairs(PetList) do
			if abilityId == v then
				-- Cancel the buff if we got a match
				CancelBuff(buffSlot)
			end
		end
	end

end


local function PeriodicUpdate()
	BigLogicRoutine()

	if TwilightActive and not InCombat and LowestGroupHealthPercent > 0.90 and (GetGameTimeMilliseconds() - LastEnemySightTime) > 45000 then
		DismissTwilight()
	end
	
	zo_callLater(PeriodicUpdate,250)
end

local function OccasionalUpdate()
	if GetNumBagUsedSlots(BAG_BACKPACK) == GetBagSize(BAG_BACKPACK) then
		InventoryFull = true
	else
		InventoryFull = false
	end

	zo_callLater(PeriodicUpdate,5000)
end







local function UpdateBuffs()
	MajorSorcery = false
	MajorProphecy = false
	MinorSorcery = false
	MajorResolve = false
	MinorMending = false
	MeditationActive = false
	ImbueWeaponActive = false
	DamageShieldActive = false
	MajorGallop = false
	MajorExpedition = false
	Empower = false
	SkeletonMageActive = false
	SpiritMenderActive = false
	FamiliarActive = false
	FamiliarAOEActive = false
	TwilightActive = false
	CrystalWeaver = false
	CrystalFragmentsProc = false
	DnInfernoActive = false
	EnergyOverloadActive = false
	-- MustBreakFree = false
	local numBuffs = GetNumBuffs("player")
	if numBuffs > 0 then
		local optimalBuffOverlap = 200 -- constant
		local msUntilBuffRecheckNeeded = 999999 -- if this value isn't replaced, then a buff recheck won't be scheduled
		for i = 1, numBuffs do
			local name, _, endTime, _, _, _, _, _, _, _, id, _ = GetUnitBuffInfo("player", i)
			local now = GetGameTimeMilliseconds()
			local timeLeft = (math.floor(endTime * 1000)) - now
			if name=="Major Sorcery" then
				MajorSorcery = true
			elseif name=="Major Prophecy" then
				MajorProphecy = true
			elseif name=="Minor Sorcery" then
				MinorSorcery = true
			elseif name=="Major Resolve" and timeLeft>optimalBuffOverlap then
				MajorResolve = true
				if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			elseif name=="Minor Mending" then
				MinorMending = true
			elseif name=="Deep Thoughts" then
				MeditationActive = true
			elseif name=="Elemental Weapon" and (timeLeft + 100) > optimalBuffOverlap then
				ImbueWeaponActive = true
				if timeLeft + 100 < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft + 100 end
			elseif name=="Blazing Shield" or name=="Radiant Ward" or name=="Conjured Ward" or name=="Empowered Ward" then
				DamageShieldActive = true
			elseif name=="Summon Volatile Familiar" and id==23316 then
				FamiliarActive = true
			elseif name=="Volatile Pulse" or (name=="Summon Volatile Familiar" and id==88933) then
				FamiliarAOEActive = true
			elseif name=="Summon Twilight Matriarch" then
				TwilightActive = true
			elseif name=="Crystal Weaver" then
				CrystalWeaver = true
			elseif name=="Crystal Fragments Proc" then
				CrystalFragmentsProc = true
			elseif name=="Flames of Oblivion" then
				DnInfernoActive = true
			elseif name=="Energy Overload" then
				EnergyOverloadActive = true
			elseif name=="Dampen Magic" then
				DamageShieldActive = true
			elseif name=="Empower" then
				Empower = true
			elseif name=="Skeletal Arcanist" then
				SkeletonMageActive = true
			elseif name=="Spirit Mender" then
				SpiritMenderActive = true
			elseif name=="Major Expedition" and timeLeft>optimalBuffOverlap then
				MajorExpedition = true
				if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			elseif name=="Major Gallop" and timeLeft>optimalBuffOverlap then
				MajorGallop = true
				if timeLeft < msUntilBuffRecheckNeeded then msUntilBuffRecheckNeeded = timeLeft end
			-- elseif name=="Rending Leap Ranged" or name=="Uppercut" or name=="Skeletal Smash" or name=="Stunning Shock" or name=="Discharge" or name=="Constricting Strike" or name=="Stun" then
			-- 	MustBreakFree = true


			-- elseif name=="Increased Experience" or name=="ESO Plus Member" or name=="Bound Aegis" or name=="Minor Resolve" or name=="Minor Slayer" or name=="Inner Light" or name=="Boon: The Steed" or name=="Critical Surge" or name=="Major Brutality" or name=="Minor Prophecy" or name=="Boundless Storm" then
			-- else
			-- 	d(name)
			end
		end
		if msUntilBuffRecheckNeeded < 999999 then
			zo_callLater(UpdateBuffs, msUntilBuffRecheckNeeded-optimalBuffOverlap)
		end
	end
	BigLogicRoutine()
end





local function OnEventMountedStateChanged(eventCode,mounted)
	Mounted = mounted
	Sprinting = false
	BigLogicRoutine()
end

local function OnEventInteractableTargetChanged()
	UpdateLastSights()
	local action, interactableName, blocked, mystery2, additionalInfo = GetGameCameraInteractableActionInfo()
	-- d(action)
	-- d(interactableName)
	-- d(blocked)
	-- d(mystery2)
	-- d(additionalInfo)
	if action == "Steal From" then action = "Steal" end
	if blocked or additionalInfo == 2 then
		if action == "Steal" then
			action = "BlockedSteal"
		else
			action = nil
		end
		interactableName = nil
	end
	if action == "Pickpocket" then UpdatePickpocketState() else PickpocketPrime = false end
	if AvailableReticleInteraction ~= action or AvailableReticleTarget ~= interactableName then
		AvailableReticleInteraction = action
		AvailableReticleTarget = interactableName
		BigLogicRoutine()
	end

end



local function OnEventEffectChanged(e, change, slot, auraName, unitTag, start, finish, stack, icon, buffType, effectType, abilityType, statusType, unitName, unitId, abilityId, sourceType)
	UpdateLowestGroupHealth()
	UpdateTargetInfo()
	if unitTag=="player" then
		UpdateBuffs()
	else
		BigLogicRoutine()
	end
end

local function OnEventPowerUpdate(eventCode, unitTag, powerIndex, powerType, powerValue, powerMax, powerEffectiveMax)
	if unitTag=="player" and powerType==POWERTYPE_MAGICKA then
		MagickaPercent = powerValue / powerMax
		BigLogicRoutine()
	elseif unitTag=="player" and powerType==POWERTYPE_STAMINA then
		StaminaPrevious = Stamina
		Stamina = powerValue
		StaminaPercent = powerValue / powerMax
		if (powerValue == powerMax or Stamina > StaminaPrevious) and not Mounted then Sprinting = false
		elseif Stamina < StaminaPrevious and not Mounted then Sprinting = true end
		BigLogicRoutine()
	elseif unitTag=="player" and powerType==POWERTYPE_MOUNT_STAMINA and powerValue==powerMax and Mounted then
		Sprinting = false
		BigLogicRoutine()
	elseif unitTag=="player" and powerType==POWERTYPE_MOUNT_STAMINA and powerValue<(powerMax-3) and Mounted then
		Sprinting = true
		BigLogicRoutine()
	elseif powerType==POWERTYPE_HEALTH then
		if unitTag=="player" then
			HealthPrevious = Health
			Health = powerValue
			HealthPercent = powerValue / powerMax
		end
		UpdateLowestGroupHealth()
		BigLogicRoutine()
	elseif unitTag=="player" and powerType==POWERTYPE_ULTIMATE then
		Ultimate = powerValue
		UltimatePercent = powerValue / powerMax
		BigLogicRoutine()
	end
end

local function OnEventGroupSupportRangeUpdate()
	UpdateLowestGroupHealth()
	BigLogicRoutine()
end

local function PreventStealing()
	SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_PREVENT_STEALING_PLACED, 1)
end
local function AllowStealing()
	SetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_PREVENT_STEALING_PLACED, 0)
end

local function OnEventStealthChange(_,_,stealthState)
	if stealthState > 0 then
		AllowStealing()
		Crouching = true
		if stealthState == 3 then
			Hidden = true
		else
			Hidden = false
		end
	else
		PreventStealing()
		Crouching = false
		CrouchWasAuto = false
		Hidden = false
	end
	BigLogicRoutine()
end

local function OnEventCombatTipDisplay(_, tipId)
	if tipId == 2 then
		return
	elseif tipId == 4 or tipId == 19 then
		MustDodge = true
		BigLogicRoutine()
	elseif tipId == 3 then
		MustInterrupt = true
		BigLogicRoutine()
	elseif tipId == 1 or tipId == 130 then
		MustBlock = true
		BigLogicRoutine()
	elseif tipId == 18 then
	else
		local name, tipText, iconPath = GetActiveCombatTipInfo(tipId)
		d(name)
		d(tipText)
		d(tipId)
	end

end

local function OnEventCombatTipRemove()
	MustDodge = false
	MustInterrupt = false
	MustBlock = false
	Feared = false
	BigLogicRoutine()
end

local function OnEventCombatEvent(_,result,_,_,_,_,_,_,targetName)
	if targetName == RawPlayerName then
		if result == ACTION_RESULT_FEARED then
			Feared = true
		end
	end
end

local function OnEventStunStateChanged(_,StunState)
	Stunned = StunState
	BigLogicRoutine()
end




local function OnEventReticleChanged()
	UpdateLastSights()
	UpdateTargetInfo()
	BigLogicRoutine()
end




local function OnEventBarSwap()
	UpdateBarState()
	UpdateAbilitySlotInfo()
	BigLogicRoutine()
end

local function OnEventAbilityChange()
	UpdateAbilitySlotInfo()
end

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

local function OnEventUiModeChanged()
	if (IsReticleHidden()) then
		InputReady = false
	else
		InputReady = true
		UpdateAbilitySlotInfo()
	end
	BigLogicRoutine()
end

function PD_ReelInFish()
	ReelInFish = true
	BigLogicRoutine()
end

function PD_StopReelInFish()
	ReelInFish = false
	BigLogicRoutine()
end

ZO_CreateStringId("SI_BINDING_NAME_AutoSprint", "AutoSprint")

function AutoAssistSprintYes()
	ShouldSprint = true
	BigLogicRoutine()
end

function AutoAssistSprintNo()
	ShouldSprint = false
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
	EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_STEALTH_STATE_CHANGED, OnEventStealthChange)
	-- EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SKILL_BUILD_SELECTION_UPDATED, OnEventAbilityChange) -- Turns out this isn't the right event, I'm just going to update abilities when combat begins
	-- EVENT_MANAGER:AddFilterForEvent(ADDON_NAME, EVENT_COMBAT_EVENT, REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
	ZO_PreHookHandler(RETICLE.interact, "OnEffectivelyShown", OnEventInteractableTargetChanged)
	ZO_PreHookHandler(RETICLE.interact, "OnHide", OnEventInteractableTargetChanged)
end


local function SetUpSettingsMenu()
	local LAM = LibAddonMenu2
	local panelName = "AutoAssistSettings"

	local panelData = {
		type = "panel",
		name = "AutoAssist",
		author = "Tom Cumbow",
	}
	local panel = LAM:RegisterAddonPanel(panelName, panelData)
	local optionsData = {
		{
			type = "checkbox",
			name = "Swap bars",
			getFunc = function() return Config.SwapBars end,
			setFunc = function(value) Config.SwapBars = value end
		},
		{
			type = "checkbox",
			name = "Break free",
			getFunc = function() return Config.BreakFree end,
			setFunc = function(value) Config.BreakFree = value end
		},
		{
			type = "checkbox",
			name = "Dodge",
			getFunc = function() return Config.Dodge end,
			setFunc = function(value) Config.Dodge = value end
		},
		{
			type = "checkbox",
			name = "Block",
			getFunc = function() return Config.Block end,
			setFunc = function(value) Config.Block = value end
		},
		{
			type = "checkbox",
			name = "Interrupt",
			getFunc = function() return Config.Interrupt end,
			setFunc = function(value) Config.Interrupt = value end
		},
		{
			type = "checkbox",
			name = "Remote interrupt",
			getFunc = function() return Config.RemoteInterrupt end,
			setFunc = function(value) Config.RemoteInterrupt = value end
		},
		{
			type = "checkbox",
			name = "Healing",
			getFunc = function() return Config.Healing end,
			setFunc = function(value) Config.Healing = value end
		},
		{
			type = "checkbox",
			name = "Use Crown Tri-Restoration potions",
			getFunc = function() return Config.PotionTri end,
			setFunc = function(value) Config.PotionTri = value end
		},
		{
			type = "checkbox",
			name = "Use Spell Power/Crit potions",
			getFunc = function() return Config.PotionSpell end,
			setFunc = function(value) Config.PotionSpell = value end
		},
		{
			type = "checkbox",
			name = "Taunt bosses",
			getFunc = function() return Config.TauntBosses end,
			setFunc = function(value) Config.TauntBosses = value end
		},
		{
			type = "checkbox",
			name = "Overload",
			getFunc = function() return Config.Overload end,
			setFunc = function(value) Config.Overload = value end
		},
		{
			type = "checkbox",
			name = "Buffs",
			getFunc = function() return Config.Buffs end,
			setFunc = function(value) Config.Buffs = value end
		},
		{
			type = "checkbox",
			name = "Meditation",
			getFunc = function() return Config.Meditation end,
			setFunc = function(value) Config.Meditation = value end
		},
		{
			type = "checkbox",
			name = "Swap to bar with Inner Light before attacking",
			getFunc = function() return Config.SwapToInnerLight end,
			setFunc = function(value) Config.SwapToInnerLight = value end
		},
		{
			type = "checkbox",
			name = "Damage abilities",
			getFunc = function() return Config.DamageAbils end,
			setFunc = function(value) Config.DamageAbils = value end
		},
		{
			type = "checkbox",
			name = "Heavy attacks",
			getFunc = function() return Config.HeavyAttacks end,
			setFunc = function(value) Config.HeavyAttacks = value end
		},
		{
			type = "checkbox",
			name = "Light attacks",
			getFunc = function() return Config.LightAttacks end,
			setFunc = function(value) Config.LightAttacks = value end
		},
		{
			type = "checkbox",
			name = "Loot/Harvest/Take",
			getFunc = function() return Config.Loot end,
			setFunc = function(value) Config.Loot = value end
		},
		{
			type = "checkbox",
			name = "Disarm traps",
			getFunc = function() return Config.Disarm end,
			setFunc = function(value) Config.Disarm = value end
		},
		{
			type = "checkbox",
			name = "Sprint",
			getFunc = function() return Config.Sprint end,
			setFunc = function(value) Config.Sprint = value end
		},
		{
			type = "checkbox",
			name = "Speed spell",
			getFunc = function() return Config.Expedition end,
			setFunc = function(value) Config.Expedition = value end
		},
		{
			type = "checkbox",
			name = "Sprint when mounted",
			getFunc = function() return Config.MountSprint end,
			setFunc = function(value) Config.MountSprint = value end
		},
		{
			type = "checkbox",
			name = "Speed spell on mount",
			getFunc = function() return Config.Gallop end,
			setFunc = function(value) Config.Gallop = value end
		},
		{
			type = "checkbox",
			name = "Dismount for Platinum",
			getFunc = function() return Config.PlatinumDismount end,
			setFunc = function(value) Config.PlatinumDismount = value end
		},
		{
			type = "checkbox",
			name = "Hide Twilight when no enemies around",
			getFunc = function() return Config.HideTwilight end,
			setFunc = function(value) Config.HideTwilight = value end
		},
		{
			type = "checkbox",
			name = "Steal when fully hidden",
			getFunc = function() return Config.Steal end,
			setFunc = function(value) Config.Steal = value end
		},
		{
			type = "checkbox",
			name = "Crouch and uncrouch when stealable items detected",
			getFunc = function() return Config.CrouchSteal end,
			setFunc = function(value) Config.CrouchSteal = value end
		},
		{
			type = "checkbox",
			name = "Pickpocket when 100% chance",
			getFunc = function() return Config.Pickpocket end,
			setFunc = function(value) Config.Pickpocket = value end
		},

	}
	LAM:RegisterOptionControls(panelName, optionsData)
end

local function BindSpecial (desiredActionName, keyCode)
    local layers = GetNumActionLayers()
    for layerIndex=1, layers do
        local layerName, categories = GetActionLayerInfo(layerIndex)
        for categoryIndex=1, categories do
			local categoryName, actions = GetActionLayerCategoryInfo(layerIndex, categoryIndex)
            for actionIndex=1, actions do
                local actionName, isRebindable, isHidden = GetActionInfo(layerIndex, categoryIndex, actionIndex)
                if isRebindable and actionName == desiredActionName then
                    -- LayerIndex,CategoryIndex,ActionIndex,BindIndex(1-4),KeyCode,Modx4
                    CallSecureProtected("BindKeyToAction", layerIndex, categoryIndex, actionIndex, 4, keyCode, 0, 0, 0, 0)
                end
            end
        end
    end
end

local function BindRequiredKeys()
	-- LayerIndex,CategoryIndex,ActionIndex,BindIndex(1-4),KeyCode,Modx4
    CallSecureProtected("BindKeyToAction", 1, 1, 8, 4, 29, 0, 0, 0, 0)  -- Dodge 8
    CallSecureProtected("BindKeyToAction", 1, 2, 1, 4, 28, 0, 0, 0, 0)  -- Attack 6
    CallSecureProtected("BindKeyToAction", 1, 2, 2, 4, 31, 0, 0, 0, 0)  -- Block 9
    CallSecureProtected("BindKeyToAction", 1, 2, 5, 4, 30, 0, 0, 0, 0)  -- Interrupt 8
    CallSecureProtected("BindKeyToAction", 1, 2, 8, 4, 22, 0, 0, 0, 0)  -- Front Bar 0
    CallSecureProtected("BindKeyToAction", 1, 2, 9, 4, 99, 0, 0, 0, 0)  -- Back Bar -
    BindSpecial("AutoSprint", 100) -- AutoSprint =
end

local function InitialInfoGathering()
	PreventAttackingInnocents()
	SetUpSettingsMenu()
	BindRequiredKeys()
	InCombat = IsUnitInCombat("player")
	Mounted = IsMounted()
	UpdateBarState()
	UpdateAbilitySlotInfo()
	PeriodicUpdate()
	OccasionalUpdate()
	PD_RegisterForEvents()
	AutoAssistLoaded = true -- global variable to indicate this add-on has been loaded, used to enable integrations in other add-ons
	PixelDataLoaded = true -- global variable to indicate this add-on has been loaded, used to enable integrations in other add-ons
	UpdateBuffs()
end




local function OnAddonLoaded(event, name)
	if name == ADDON_NAME then
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, event)
		Config = ZO_SavedVars:NewCharacterIdSettings("AutoAssistSavedVariables",1)
		AutoAssistWindow = WINDOW_MANAGER:CreateTopLevelWindow("AutoAssist")
		AutoAssistWindow:SetDimensions(100,100)
		PDL = CreateControl(nil, AutoAssistWindow,  CT_LINE)
		PDL:SetAnchor(TOPLEFT, AutoAssistWindow, TOPLEFT, 0, 0)
		PDL:SetAnchor(TOPRIGHT, AutoAssistWindow, TOPLEFT, 1, 1)
		SetPixel(DoNothing)

		zo_callLater(InitialInfoGathering, 1000)

	end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
