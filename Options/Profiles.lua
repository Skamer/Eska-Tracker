--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                "EskaTracker.Options.Profiles"                         ""
--============================================================================--
import                         "EKT"
--============================================================================--

local function GetNumSpec()
  local _, class = UnitClass("player")
  if class == "DEMONHUNTER" then
    return 2
  elseif class == "DRUID" then
    return 4
  else
    return 3
  end
end

local function GetProfilesCreated()
  return Profiles:GetUserProfilesList()
end

local function GetAllProfilesList(self)
  local list = {
    ["__global"] = "Global profile",
    ["__char"]   = "Character profile",
    ["__spec"]   = "Specialization profile",
  }

  for profileName in pairs(Profiles:GetUserProfilesList()) do
    list[profileName] = profileName
  end

  return list
end

function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("profiles"):SetText("Profiles"):SetBuildingGroup("profiles/children"):SetOrder(600), "RootTree")

  self:AddProfilRecipes()
end

function AddProfilRecipes(self)
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Select a profile for your specialization"):SetOrder(10), "profiles/children")
  for i = 1, GetNumSpec() do
    OptionBuilder:AddRecipe(SpecProfileRecipe():SetSpecIndex(i):SetOrder(20 + 10 * i), "profiles/children")
  end

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cff00ff00Create a profile|r"):SetOrder(90), "profiles/children")
  --- [PART] Create a profile
  local lineEdit = LineEditRecipe()
  lineEdit:SetText("Enter the name of your new profile")
  lineEdit:SetOrder(100)
  lineEdit.OnValueConfirmed = lineEdit.OnValueConfirmed + function(self, profileName) OptionBuilder:SetVariable("create_profile_name", profileName)  end
  OptionBuilder:AddRecipe(lineEdit, "profiles/children")

  local createButton = ButtonRecipe()
  createButton:SetText("Create")
  createButton:SetOrder(101)
  createButton.OnClick = createButton.OnClick + function(self)
    local profileName = OptionBuilder:GetVariable("create_profile_name")
    if profileName then
      Profiles:Create(profileName)
      self:FireRecipeEvent("PROFILE_CREATED", profileName)
    end
  end
  OptionBuilder:AddRecipe(createButton, "profiles/children")

  -- [PART] Copy a profile
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Copy from another profile"):SetOrder(110), "profiles/children")

  local selectProfileToCopy = SelectRecipe()
  selectProfileToCopy:SetText("Select the profile you want copy")
  selectProfileToCopy:SetOrder(111)
  selectProfileToCopy:SetList(GetAllProfilesList)
  selectProfileToCopy:RefreshOnRecipeEvent("PROFILE_CREATED")
  selectProfileToCopy:RefreshOnRecipeEvent("PROFILE_DELETED")
  selectProfileToCopy.OnValueChanged = selectProfileToCopy.OnValueChanged + function(self, profileName) OptionBuilder:SetVariable("copy_profile_name", profileName) end
  OptionBuilder:AddRecipe(selectProfileToCopy, "profiles/children")

  -- Copy POPUP
  StaticPopupDialogs["EKT_COPY_PROFILE_RELOAD_UI"] = {
    text = "|cff00ff00The profile has been copied with success.|r |cff00ffffThe interface must be reloaded to apply changes !|r",
    button1 = "Reload the interface",
    OnAccept = function() ReloadUI() end,
  }

  local copyButton = ButtonRecipe()
  copyButton:SetText("Copy")
  copyButton:SetOrder(112)
  copyButton.OnClick = copyButton.OnClick + function(self)
    local profileName = OptionBuilder:GetVariable("copy_profile_name")
    if profileName then
      Profiles:CopyFrom(profileName)
      StaticPopup_Show("EKT_COPY_PROFILE_RELOAD_UI")
    end
  end
  OptionBuilder:AddRecipe(copyButton, "profiles/children")

  -- [Part] Delete a profile
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffff0000Delete a profile|r"):SetOrder(120), "profiles/children")

  local selectProfileToDelete = SelectRecipe()
  selectProfileToDelete:SetText("Select the profile to delete")
  selectProfileToDelete:SetOrder(121)
  selectProfileToDelete:RefreshOnRecipeEvent("PROFILE_DELETED")
  selectProfileToDelete:RefreshOnRecipeEvent("PROFILE_CREATED")
  selectProfileToDelete:SetList(GetProfilesCreated)
  selectProfileToDelete.OnValueChanged = selectProfileToDelete.OnValueChanged + function(self, profileName)  OptionBuilder:SetVariable("delete_profile_name", profileName) end
  OptionBuilder:AddRecipe(selectProfileToDelete, "profiles/children")


  local deleteButton = ButtonRecipe()
  deleteButton:SetText("Delete")
  deleteButton:SetOrder(122)
  deleteButton.OnClick = deleteButton.OnClick + function(self)
    local profileName = OptionBuilder:GetVariable("delete_profile_name")
    if profileName then
      Profiles:Delete(profileName)
      self:FireRecipeEvent("PROFILE_DELETED", profileName)
    end
  end
  OptionBuilder:AddRecipe(deleteButton, "profiles/children")

end
