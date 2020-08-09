if (bin_isFreeRoam || bin_isHub) then {
	disableserialization;
	params ["_display",["_exitCode",2]];
	if (_exitCode != 2) exitwith {}; // 2 = mission end or client when server aborts, 4 = abort

	//--- Save
	"save" call bin_fnc_persistentVariables;
};