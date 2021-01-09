local ADDON_VERSION = "1.0"
local ADDON_AUTHOR = "Tom Cumbow"
local ADDON_NAME = "AutoFight-Freya"

local MajorSorcery = false
local MajorProphecy = false
local MinorSorcery = false
local MajorResolve = false
local DnInfernoActive = false

local ETA = 0
local MyMagicka
local MyMaxMagicka
local MyStamina
local MyMaxStamina
local MyHealth
local MyMaxHealth
local MyHealthPercent


local function UpdateBuffs()
	MajorSorcery = false
	-- MajorProphecy = false
	-- MinorSorcery = false
	-- MajorResolve = false
	DnInfernoActive = false
	local numBuffs = GetNumBuffs("player")
	if numBuffs > 0 then
		for i = 1, numBuffs do
			local name, _, endTime, _, _, _, _, _, _, _, id, _ = GetUnitBuffInfo("player", i)
			if name=="Molten Armaments" then
				MajorSorcery = true
			-- elseif name=="Major Prophecy" then
			-- 	MajorProphecy = true
			-- elseif name=="Minor Sorcery" then
			-- 	MinorSorcery = true
			-- elseif name=="Major Resolve" then
			-- 	MajorResolve = true
			elseif name=="Flames of Oblivion" then
			 	DnInfernoActive = true
			end
		end
	end
end

local function AutoFightMain()
	if not IsUnitInCombat('player') then return end
	if IsReticleHidden() or IsUnitSwimming('player') then return end
	
	if ETA > GetGameTimeMilliseconds() then return end

	UpdateBuffs()
	MyMagicka, MyMaxMagicka = GetUnitPower('player', POWERTYPE_MAGICKA)
	MyStamina, MyMaxStamina = GetUnitPower('player', POWERTYPE_STAMINA)
	MyHealth, MyMaxHealth = GetUnitPower('player', POWERTYPE_HEALTH)
	MyHealthPercent = MyHealth/MyMaxHealth

	-- Self Heal
	if MyHealthPercent < 0.60 and MyStamina > 4000 then
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_4,50)
		ETA = GetGameTimeMilliseconds() + 1100

	-- Molten Armaments
	elseif not MajorSorcery and MyMagicka > 10000 then
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_3,50)
		ETA = GetGameTimeMilliseconds() + 1100

	-- Inferno
	elseif not DnInfernoActive and MyMagicka > 10000 then
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_5,50)

	-- Uppercut
	elseif GetUnitReaction('reticleover') == UNIT_REACTION_HOSTILE and MyStamina > 10000 then
		LibPixelControl.SetIndOnFor(LibPixelControl.VK_1,50)

	-- Heavy Attack
	elseif GetUnitReaction('reticleover') == UNIT_REACTION_HOSTILE then
		LibPixelControl.SetIndOnFor(LibPixelControl.VM_BTN_LEFT,2200)
		ETA = GetGameTimeMilliseconds() + 2700
	end

end

local function OnAddonLoaded(event, name)
	if name == ADDON_NAME then
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, event)
		if GetUnitName("player") == "Freya Fiori" then
			EVENT_MANAGER:RegisterForUpdate(ADDON_NAME, 100, AutoFightMain)
		end
	end
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
