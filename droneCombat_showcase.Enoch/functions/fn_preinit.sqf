bin_isEditorHub = missionname == "hubSite";
bin_isEditorSite = isclass (configfile >> "CfgContact" >> "Sites" >> missionname) || bin_isEditorHub;
bin_isSitesTest = missionname == "_Sites";
bin_isContact = isclass (missionconfigfile >> "CfgContact") || bin_isEditorSite;
bin_isHub = getnumber (missionconfigfile >> "CfgContact" >> "isHub") > 0 || bin_isEditorHub;
bin_isFreeRoam = getnumber (missionconfigfile >> "CfgContact" >> "isFreeRoam") > 0 || (bin_isEditorSite && !bin_isEditorHub);
bin_isInit = false;
[] call bin_fnc_initConstants;
if (!bin_isContact) exitwith {};

//--- Save information about the current mission (not part of persistent variables, accessed from outside)
//profilenamespace setvariable ["BIN_currentMission",_mission];
//saveprofilenamespace;
BIN_currentMission = missionname;

//--- Persistent variables
"load" call bin_fnc_persistentVariables;
addmissioneventhandler ["ended",{"save" call bin_fnc_persistentVariables;}];

//--- Misc inits
[0] call bin_fnc_initQuests;
[] call bin_fnc_initDiary;
[] call bin_fnc_initAntennas;
[] call bin_fnc_initSideColors;
[] call bin_fnc_initCutLayers;
["Init",[]] call BIS_fnc_moduleFriendlyFire;

if (bin_isHub) then {
	enableteamswitch false; //--- Disables commanding menu in Contact
};

//--- Save & Load event handlers
bin_loadedTime = 0;
addmissioneventhandler [
	"loaded",
	{
		bin_loadedTime = time;
		[] call BIN_fnc_loadIDWMap;
		[] call bin_fnc_initCutLayers;
	}
];

[
	missionNamespace,
	"OnSaveGame",
	{
		[] call BIN_fnc_saveIDWMap;
	}
] call BIS_fnc_addScriptedEventHandler;