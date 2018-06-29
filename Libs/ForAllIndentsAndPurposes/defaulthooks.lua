local addons = {}

addons["LuaSlinger"] = {
   "LuaSlingerScratchBox",
   "LuaSlingerScriptBox",
   "LuaSlingerLibraryBox",
   "LuaSlingerImportBox"}

addons["TinyPad"] = {
   "TinyPadEditBox"}

addons["Phoenix"] = {
   "PhoenixEntryEditBox"}

addons["LuaPad"] = {
   "LuaPadEditBox"}

addons["Inspector"] = {}
for i = 1, 8 do
   addons["Inspector"][i] = "IG_ScriptFrameScriptTab"..i.."ListScrollFrameChildFrameEditBox"
end
addons["FuncBook"] = {
   "FuncBookFrameEditorScrollBoxEditBox"}

addons["myDebug"] = {
   "myDebugScriptsFrameEditBox"}

local function onEventHandler()
   local addonName = arg1
   local t = addons[addonName]
   if t then
      for k, v in next,t do
	 local editbox = getglobal(v)
	 if editbox then
	    IndentationLib.enable(editbox, nil, 4)
	 end
      end
   end
end

for addon, t in next,addons do
   for k, v in next,t do
      local editbox = getglobal(v)
      if editbox then
	 IndentationLib.enable(editbox, nil, 4)
      end
   end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", onEventHandler)
frame:RegisterEvent("ADDON_LOADED")
