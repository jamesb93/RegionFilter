local RF = select(2, ...)
local servers = RF.servers
local posts = RF.posts
RF.version = "1.5.0"
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
function RF.removeEntries(results)
	local isLocal = {}
	if RF.togRemove then
		local localCount = 0
		local originalResultCount = #results
		for i=originalResultCount, 1, -1 do
			local resultID = results[i]
			isLocal[resultID] = false
			local searchResults = C_LFGList.GetSearchResultInfo(resultID)

			local leaderName = searchResults.leaderName

			if leaderName ~= nil then -- Filter out nil entries from LFG Pane
				local name, realm = RF:sanitiseName(leaderName)
				local info = servers[realm]
				if info ~= nil then
					local region = info[1]
					if RF.region ~= region then
						table.remove(results, i)
					else
						localCount = localCount + 1
						isLocal[resultID] = true 
					end
				end
			end
		end
--[[ 		local outcomeMessage = '|cff00ffff[Region Filter]: |cffFF6EB4 Found ' ..localCount..'/'..originalResultCount..' groups.'
		--When refreshing the UI, GetSearchResultInfo will fail to provide information on some groups. 
		if (#results-localCount > 0) then
			outcomeMessage = outcomeMessage..'|cffff0000 Info missing from ' .. #results-localCount .. ', refresh to fix.'
		end
		print(outcomeMessage) ]]

		local function sortCompFunc(searchResultID1, searchResultID2)
			if (isLocal[searchResultID1]) then 
				if (not isLocal[searchResultID2]) then
					return true
				end
			else
				if (isLocal[searchResultID2]) then 
					return false
				end
			end
			return searchResultID1>searchResultID2
		end
	
		table.sort(results, sortCompFunc)
	else
		table.sort(results)
	end
	LFGListFrame.SearchPanel.totalResults = #results
	return true
end

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
			local region, dataCentre, regionColour = info[1], info[2], info[3]
			if region == "NA" then
				regionLabel = region..'-'..dataCentre;
			else
				regionLabel = region
			end
				results.ActivityName:SetText(
					RF:regionTag(
						regionLabel, 
						activityName,
						regionColour
					)
				)
				results.ActivityName:SetTextColor(
					RF:dungeonText(RF.region, region)
				)
		end
	end
end


SLASH_RFILTER1 = "/rfilter"
SlashCmdList["RFILTER"] = function(msg)
	if RF.togRemove then
		print('|cff00ffff[Region Filter]: |cffFF6EB4 Not filtering outside regions')
	else
		print('|cff00ffff[Region Filter]: |cffFF6EB4 Filtering outside regions')
	end
	RF.togRemove = not RF.togRemove
	LFGListSearchPanel_UpdateResultList (LFGListFrame.SearchPanel)
	LFGListSearchPanel_UpdateResults 	(LFGListFrame.SearchPanel)
end

---- Print When Loaded ----
local welcomePrompt = CreateFrame("Frame")
welcomePrompt:RegisterEvent("PLAYER_LOGIN")
welcomePrompt:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		print("|cff00ffff[Region Filter]|r |cffffcc00Version "..RF.version.."|r. If there any bugs please report them at https://github.com/jamesb93/RegionFilter")
		print(RF.postType)
	end
end)

hooksecurefunc("LFGListUtil_SortSearchResults", RF.removeEntries)
hooksecurefunc("LFGListSearchEntry_Update", RF.updateEntries)
