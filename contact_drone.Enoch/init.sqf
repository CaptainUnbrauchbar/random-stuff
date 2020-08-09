if !(isserver || is3DEN) exitwith {};

[bin_drone,"Drone"] call bin_fnc_behaviorInit;
[bin_drone,"Drone"] call bin_fnc_setMoveProperties;
[bin_drone, (getpos bin_drone) vectorAdd [0,0,2],4,4,16,35,35,2] call bin_fnc_setObjectGrid;
[bin_drone] call bin_fnc_soundDrone;

bin_curator call bin_fnc_curatorInit;

// Add spectrum device to player
player addweapon "hgun_esd_01_F";
player addhandgunitem "muzzle_antenna_02_f";

// Add signals to Drone
["AlienTracker",bin_drone,2] call bin_fnc_setAntenna;
["AlienTracker","EM_Drone_01_Tracking_01"] call bin_fnc_addSignal;

// Initalize modules
waitUntil {simulationEnabled BIN_drone};

private _sidePrefix = "I_A";
switch(side BIN_drone)do
{
	case west: {_sidePrefix = "B_A"};
	case east: {_sidePrefix = "O_A"};
};
private _moduleType_1 = format["%1_AlienDrone_Module_01_F",_sidePrefix];

private _module_01 = [BIN_drone,_moduleType_1,"science"] call bin_fnc_initDroneModule;
private _module_02 = [BIN_drone,_moduleType_1,"science"] call bin_fnc_initDroneModule;

{
	_x setVariable ["bin_droneModule_damage",false];
	_x setVariable ["bin_droneModule_interval", 0.7];
	_x setVariable ["bin_droneModule_radius", 3.5];
	_x setVariable ["bin_droneModule_height", 1.1+(_foreachIndex+1)*1.2];
	_x setVariable ["bin_droneModule_rotationTime", 8.5*(_foreachIndex+1)];
}foreach [_module_01,_module_02];