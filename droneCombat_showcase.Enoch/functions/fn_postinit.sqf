if (!bin_isContact) exitwith {};

[] call bin_fnc_initActors;
[] call bin_fnc_initSites;
[] call bin_fnc_initAcctime;
[] spawn bin_fnc_initProbeMap;

if (bin_isFreeRoam || bin_isHub) then {

	if (isnil "BIN_player") then {BIN_Player = player; player setvehiclevarname "BIN_player";};

	//[] call bin_fnc_initHub;
	//["initAll"] call bin_fnc_moduleDangerZone;

	//if (!bin_isSitesTest && !bin_isEditorSite) then {
		//if !(BIN_Inventory isequalto []) then {player setUnitLoadout BIN_Inventory;};
		//setdate [2037,06,24,floor BIN_daytime,(BIN_daytime % 1) * 60]; // ToDo: Move year, month and day to config
		//if (bin_isFreeRoam) then {
		//	private _point = missionnamespace getvariable [BIN_travelPoint,objnull];
		//	if !(isnull _point) then {
		//		player setposatl getposatl _point;
		//		player setdir direction _point;
		//		BIN_travelPoint = "";
		//	} else {
		//		if !(BIN_Position isequalto [0,0,0]) then {player setposatl BIN_Position;};
		//	};
		//};
	//};
};

[1] call bin_fnc_initLocations;
[1] call bin_fnc_initQuests;
//[] call bin_fnc_initGroup;
[1] call bin_fnc_initInventory;
[] call bin_fnc_initMiniUGV;

//--- 100% healing
player addeventhandler ["HandleHeal",{_this spawn {sleep 6; player setdamage 0; (_this # 1) removeitem "FirstAidKit";}; true}];

//--- Initialize friendly HQ antenna
if !(isnil "bin_home") then {["Home",bin_home,true,"Home",nil,nil,nil,nil,true] call bin_fnc_setAntenna;};

//--- Reset mission display variables (only upon restart, the display doesn't exist yet when starting the mission)
(findDisplay 46) setVariable ["BIS_skipKeyDown",nil];

bin_isInit = true;