local RF = select(2, ...)
local servers = RF.servers
local posts = RF.posts
RF.version = "1.4.0"
RF.togRemove = false

local spaced_realm = string.gsub(GetRealmName(), "%s+", "")
RF.myRealm = string.gsub(spaced_realm, "'", "")
---- Set variables for realm/data-centre info ----
RF.info = servers[RF.myRealm] 
RF.region, RF.dataCentre = RF.info[1], RF.info[2]

if RF.region == 'NA' then
	if RF.dataCentre == 'EAST' then
		RF.postType = posts.na_east_post
	end

	if RF.dataCentre == 'WEST' then
		RF.postType = posts.na_west_post
	end
end

if RF.region == 'OC' then RF.postType = posts.oc_post end
if RF.region == 'LA' then RF.postType = posts.la_post end
if RF.region == 'BR' then RF.postType = posts.br_post end
---- Removing Enrties when togRemove is enabled
-- function RF.removeEntries(results)
-- 	if RF.togRemove then
-- 		for i=1, #results do
-- 			local resultID = results[i]
-- 			local searchResults = C_LFGList.GetSearchResultInfo(resultID)

-- 			local leaderName = searchResults.leaderName

-- 			if leaderName ~= nil then -- Filter out nil entries from LFG Pane
-- 				local name, realm = RF:sanitiseName(leaderName)
-- 				local info = servers[realm]
-- 				if info ~= nil then
-- 					local region = info[1]
-- 					if RF.region ~= region then
-- 						table.remove(results, i)
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- 	table.sort(results)
-- 	LFGListFrame.SearchPanel.totalResults = #results
-- 	return true
-- end

---- Updating the text of entries
function RF.updateEntries(results)
	local searchResults = C_LFGList.GetSearchResultInfo(results.resultID)
	local activityID = searchResults.activityID
	local leaderName = searchResults.leaderName
	local activityName = C_LFGList.GetActivityInfo(activityID)

	if leaderName ~= nil then -- Filter out nil entries from LFG Pane
		local name, realm = RF:sanitiseName(leaderName)
		local info = servers[realm]
		if info then
			local region, dataCentre = info[1], info[2]
			if region == "NA" then
				results.ActivityName:SetText(
					RF:regionTag(
						RF.region, 
						region, 
						region..'-'..dataCentre, 
						activityName,
						RF.dataCentre,
						dataCentre
					)
				)
				results.ActivityName:SetTextColor(
					RF:dungeonText(RF.region, region)
				)
			else
				results.ActivityName:SetText(
					RF:regionTag(
						RF.region, 
						region, 
						region, 
						activityName,
						nil, nil
					)
				)
				results.ActivityName:SetTextColor(
					RF:dungeonText(RF.region, region)
				)
			end
		end
	end
end

function RF.sortSearchResults(results) 
    local categoryID = LFGListFrame.SearchPanel.categoryID;
	local countRemoved = 0
	local countRemaining = 0
	
	-- RF.region -- filter by this
	local function FilterSearchResults(searchResultID)
		if not RF.togRemove then 
			return 
		end

		local searchResults = C_LFGList.GetSearchResultInfo(searchResultID)
		local leaderName = searchResults.leaderName
		local removedByFilter = true

		if leaderName ~= nil then -- Filter out nil entries from LFG Pane
			local name, realm = RF:sanitiseName(leaderName)
			local info = servers[realm]
			if info then
				local region, dataCentre = info[1], info[2]

				if (RF.region == region and RF.dataCentre == dataCentre) then
					removedByFilter = false
					countRemaining = countRemaining + 1
				end
			end
		end

		if (removedByFilter) then 
			--print('removing '..searchResultID)
			--table.remove(results,searchResultID)
			LFGListSearchPanel_AddFilteredID(LFGListFrame.SearchPanel, searchResultID)
			countRemoved = countRemoved + 1
		end
	end
  
	if (#results > 0 and categoryID == 2) then
		for index = #results, 1, -1 do
			FilterSearchResults(results[index])
		end
		
		if (LFGListFrame.SearchPanel.filteredIDs) then
			LFGListUtil_FilterSearchResults(LFGListFrame.SearchPanel.results, LFGListFrame.SearchPanel.filteredIDs)
			--LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel) --causes stack overflow
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
			LFGListFrame.SearchPanel.filteredIDs = nil
			--print('Removed: '..countRemoved..', leaving '..countRemaining)
		end
	end
end

function RF.Dialog_UseRF_OnClick(self, button, down)
    local checked = self:GetChecked()
    RF.togRemove = checked
    LFGListSearchPanel_DoSearch(LFGListFrame.SearchPanel)
end

function RF.Dialog_SetUpRFCheckbox()
    local button = CreateFrame("CheckButton", "UseRFButton", LFGListFrame.SearchPanel, "UICheckButtonTemplate")
    button:SetSize(26, 26)
    button:SetHitRectInsets(-2, -30, -2, -2)
    button.text:SetText("RF")
    button.text:SetFontObject("GameFontHighlight")
    button.text:SetWidth(30)
    button:SetPoint("LEFT", LFGListFrame.SearchPanel.RefreshButton, "LEFT", -62, 0)
    button:SetPoint("TOP", LFGListFrame.SearchPanel.RefreshButton, "TOP", 0, -3)
    button:SetScript("OnClick", RF.Dialog_UseRF_OnClick)
    button:SetScript("OnEnter", function (self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Enable or disable the local region filter")
    end)
    button:SetScript("OnLeave", function () GameTooltip:Hide() end)
    RF.UseRFButton = button
end


-- SLASH_RFILTER1 = "/rfilter"
-- SlashCmdList["RFILTER"] = function(msg)
-- 	if RF.togRemove then
-- 		print('|cff00ffff[Region Filter]: |cffFF6EB4 Not filtering outside regions')
-- 	else
-- 		print('|cff00ffff[Region Filter]: |cffFF6EB4 Filtering outside regions')
-- 	end
-- 	RF.togRemove = not RF.togRemove
-- 	LFGListSearchPanel_UpdateResultList (LFGListFrame.SearchPanel)
-- 	LFGListSearchPanel_UpdateResults 	(LFGListFrame.SearchPanel)
-- end

---- Print When Loaded ----
local welcomePrompt = CreateFrame("Frame")
welcomePrompt:RegisterEvent("PLAYER_LOGIN")
welcomePrompt:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		print("|cff00ffff[Region Filter]|r |cffffcc00Version "..RF.version.."|r. If there any bugs please report them at https://github.com/jamesb93/RegionFilter")
		print("|cff00ffff[Region Filter]|r If possible, stop using CurseForge (soon/now to be Overwolf) and try CurseBreaker https://www.github.com/AcidWeb/CurseBreaker.")
		print(RF.postType)
	end
end)

RF.Dialog_SetUpRFCheckbox()
-- hooksecurefunc("LFGListUtil_SortSearchResults", RF.sortEntries)
hooksecurefunc("LFGListSearchEntry_Update", 	RF.updateEntries)
hooksecurefunc("LFGListUtil_SortSearchResults", RF.sortSearchResults);