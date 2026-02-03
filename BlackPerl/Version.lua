local AddonName, Addon = ...

local BlackPerl = CreateFrame("Frame", BackdropTemplateMixin and "BackdropTemplate")

BlackPerl:RegisterEvent("ADDON_LOADED")

BlackPerl:SetScript("OnEvent", function(self, event, ...)
	if not BlackPerl[event] then
		return
	end

	BlackPerl[event](BlackPerl, ...)
end)

function BlackPerl:ADDON_LOADED(addon)
	if addon ~= AddonName then
		return
	end

	C_ChatInfo.RegisterAddonMessagePrefix("BlackPerlVersion")

	self:RegisterEvents()

	self.playerName = string.gsub(UnitName("player").."-"..GetRealmName(), "%s+", "")
	self.version = C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("BlackPerl", "Version") or "1.1.0"

	self:UnregisterEvent("ADDON_LOADED")
end

function BlackPerl:PLAYER_ENTERING_WORLD()
	self.timer = C_Timer.NewTimer(3, self.SendVersion)

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function BlackPerl:GROUP_MEMBERS_JOINED()
	if self.timer and self.timer.Cancel then
		self.timer:Cancel()
	end

	self.timer = C_Timer.NewTimer(3, self.SendVersion)
end

function BlackPerl:GROUP_ROSTER_UPDATE()
	local num = GetNumGroupMembers()

	if num ~= self.groupSize then
		if num > 1 and self.groupSize and num > self.groupSize then
			self:GROUP_MEMBERS_JOINED()
		end

		self.groupSize = num
	end
end

function BlackPerl:CHAT_MSG_ADDON(prefix, msg, channel, sender)
	if prefix ~= "BlackPerlVersion" or sender == self.playerName then
		return
	end

	if self:CompareVersion(msg) then
		print("|cFF50C0FFBlackPerl|r:", XPERL_NEW_VERSION_DETECTED, "|cFFFF0000"..msg.."|r", XPERL_DOWNLOAD_LATEST, XPERL_DOWNLOAD_LOCATION)

		self.newVersion = msg

		self:UnregisterEvent("CHAT_MSG_ADDON")
	end
end

function BlackPerl:RegisterEvents()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_ADDON")
end

function BlackPerl:CompareVersion(version)
	local _, _, major, minor, build = string.find(self.version, "(%d+)%.(%d+)%.(%d+)")

	local _, _, newMajor, newMinor, newBuild = string.find(version, "(%d+)%.(%d+)%.(%d+)")

	if newMajor > major then
		return true
	elseif newMajor < major then
		return false
	end

	if newMinor > minor then
		return true
	elseif newMinor < minor then
		return false
	end

	if newBuild > build then
		return true
	elseif newBuild < build then
		return false
	end

	return false
end

function BlackPerl:SendVersion()
	local channel

	if IsInRaid() then
		channel = (not IsInRaid(LE_PARTY_CATEGORY_HOME) and IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "RAID"
	elseif IsInGroup() then
		channel = (not IsInGroup(LE_PARTY_CATEGORY_HOME) and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) and "INSTANCE_CHAT" or "PARTY"
	elseif IsInGuild() then
		channel = "GUILD"
	end

	if channel then
		local version = BlackPerl.version

		if BlackPerl.newVersion then
			version = BlackPerl.newVersion
		end

		C_ChatInfo.SendAddonMessage("BlackPerlVersion", version, channel)
	end
end
