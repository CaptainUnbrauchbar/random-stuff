if !(isserver || is3DEN) exitwith {};

//TODO Done
/*
(backpackContainer this) setObjectTexture [1, "a3\supplies_f_enoch\bags\data\b_cur_01_co.paa"];  
(backpackContainer this) setObjectTexture [2, "a3\supplies_f_enoch\bags\data\b_cur_01_co.paa"];  
this linkItem "G_AirPurifyingRespirator_01_nofilter_F";
_maskLayer = "maskLayerPlayer" cutRsc ["RscCBRN_APR", "PLAIN", -1, false];
*/

/*
 * Arguments:
 * 0: Center of zone, position array
 * 1: Threatlevel between 1 and 4.9, float
 * 2: Radius of full effect, float
 * 3: Radius of partial effect, float
 */
[getMarkerPos "contaminated_Drone", 2.5, 30, 50] call cbrn_fnc_createZone;


exCount = 0;
inCombat = true;
isnotMoving = false;
opforgo = false;
doEnd = false;
moShipMove = false,

[bin_droneRes,"Drone"] call bin_fnc_behaviorInit;
[bin_droneRes,"Drone"] call bin_fnc_setMoveProperties;
[bin_droneRes, (getpos bin_droneRes) vectorAdd [0,0,2],4,4,16,35,35,2] call bin_fnc_setObjectGrid;
[bin_droneRes] call bin_fnc_soundDrone;

["AlienTracker",bin_droneRes,2] call bin_fnc_setAntenna;
["AlienTracker","EM_Drone_01_Tracking_01"] call bin_fnc_addSignal;

// Add spectrum device to player
player addweapon "hgun_esd_01_F";
player addhandgunitem "muzzle_antenna_02_f";

waitUntil {simulationEnabled bin_droneRes};

[bin_droneRes,"gravityBurst",0] call bin_fnc_setBehaviorCoef; 

private _res_module_01 = [bin_droneRes,"I_A_AlienDrone_Module_01_F","science"] call bin_fnc_initDroneModule;
private _res_module_02 = [bin_droneRes,"I_A_AlienDrone_Module_01_F","science"] call bin_fnc_initDroneModule;

{
	_x setVariable ["bin_droneModule_damage",false];
	_x setVariable ["bin_droneModule_interval", 0.7];
	_x setVariable ["bin_droneModule_radius", 3.5];
	_x setVariable ["bin_droneModule_height", 1.1+(_foreachIndex+1)*1.2];
	_x setVariable ["bin_droneModule_rotationTime", 8.5*(_foreachIndex+1)];
}foreach [_res_module_01,_res_module_02];

//Wait until combat at Science Ship
waitUntil {bin_droneRes getVariable ["#bD",0] > 0.01};

moShipMove = true;

//Move Mothership (not good solution but only one I could get to work)
_startingAltitude = (getPosASL bin_mothership) select 2;

_x = ((getPos shipMarker select 0)-(getPos bin_mothership select 0));
_y = ((getPos shipMarker select 1)-(getPos bin_mothership select 1));

_dir = _x atan2 _y;
if (_dir < 0) then {_dir = _dir+360};		//direction from A to B

bin_mothership setDir _dir;


for [{_i=7},{_i>0},{_i=_i-0.01}] do {
	_x = sin(_dir) * _i;
	_y = cos(_dir) * _i;
	bin_mothership setPosASL [(getPos bin_mothership select 0) + _x,(getPos bin_mothership select 1) + _y, _startingAltitude];
	sleep 0.01;
};


[bin_drone1,"CombatDrone"] call bin_fnc_setMoveProperties;
[bin_drone2,"CombatDrone"] call bin_fnc_setMoveProperties;
// Create initial grid

[bin_drone1, (getpos bin_drone1) vectorAdd [0,0,4],8,8,16,4,4,3] call bin_fnc_setObjectGrid;
[bin_drone2, (getpos bin_drone2) vectorAdd [0,0,4],8,8,16,4,4,3] call bin_fnc_setObjectGrid;
// Start script responsible for drone movement sounds

[bin_drone1] call bin_fnc_soundDrone;
[bin_drone2] call bin_fnc_soundDrone;
// Snap to grid we created just before

[bin_drone1,getposatl bin_drone1] call bin_fnc_moveTo;
[bin_drone2,getposatl bin_drone2] call bin_fnc_moveTo;

waitUntil {(simulationEnabled bin_drone1) and (simulationEnabled bin_drone2)};
sleep 2;
//[bin_mothership, bin_mothership, shipMarker, 0.01, 0.01] call compile preprocessFileLineNumbers "moveEmptyObject.sqf";

// Add signals to Drone
["AlienTracker",bin_drone1,2] call bin_fnc_setAntenna;
["AlienTracker","EM_Drone_01_Tracking_01"] call bin_fnc_addSignal;

["AlienTracker",bin_drone2,2] call bin_fnc_setAntenna;
["AlienTracker","EM_Drone_01_Tracking_01"] call bin_fnc_addSignal;

sleep 2;
// Move to combat zone
[bin_drone1,"CombatDrone"] call bin_fnc_behaviorInit;
[bin_drone1,"Jump",[getpos helper_1,false,[100,"Drone_Long"]],true,true] call bin_fnc_setBehavior;

[bin_drone2,"CombatDrone"] call bin_fnc_behaviorInit;
[bin_drone2,"Jump",[getpos helper_2,false,[100,"Drone_Long"]],true,true] call bin_fnc_setBehavior;

// Initialize modules after Drone is ready

private _module_01 = [bin_drone1,"I_A_AlienDrone_Module_02_F","combat"] call bin_fnc_initDroneModule;
private _module_02 = [bin_drone1,"_I_A_AlienDrone_Module_02_F","combat"] call bin_fnc_initDroneModule;

private _module_03 = [bin_drone2,"I_A_AlienDrone_Module_02_F","combat"] call bin_fnc_initDroneModule;
private _module_04 = [bin_drone2,"_I_A_AlienDrone_Module_02_F","combat"] call bin_fnc_initDroneModule;

{
	_x setCombatMode "RED";
	_x setVariable ["bin_droneModule_damage",false];
	_x setVariable ["bin_droneModule_interval", 0.75];
	_x setVariable ["bin_droneModule_radius", 4.28683];
	_x setVariable ["bin_droneModule_height", 1.5*(_foreachIndex+1)];
	_x setVariable ["bin_droneModule_rotationTime", 6.5*(_foreachIndex+1)];
}foreach [_module_01,_module_02,_module_03,_module_04];

[west,0] call bin_fnc_setTargetWeight;
[independent,0] call bin_fnc_setTargetWeight;

waitUntil {isnotMoving};

while {inCombat} do {
	_rndm = random 17;
	for "_t1" from 1 to 4 do {[bin_drone1,"SwarmMissile_01_launcher_F"] call bis_fnc_fire;};
	sleep _rndm;
	_rndm = random 17;
	for "_t2" from 1 to 4 do {[bin_drone2,"SwarmMissile_01_launcher_F"] call bis_fnc_fire;};
	sleep _rndm;
};

sleep 1;

[bin_drone1,"jump",[getpos extract_position,true,[100,"Drone_Long"]],true,true] call bin_fnc_setBehavior;
[bin_drone2,"jump",[getpos extract_position,true,[100,"Drone_Long"]],true,true] call bin_fnc_setBehavior;
[bin_droneRes,"jump",[getpos extract_position,true,[1000,"Drone_Long"]],true,true] call bin_fnc_setBehavior;

[car,"Get in Vehicle","\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa","\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa","_this distance _target < 3","_caller distance _target < 3", {}, {}, {_this call compile preprocessFileLineNumbers "endMission.sqf" }, {}, [], 3, 0, true, false] call BIS_fnc_holdActionAdd;

/*
_moShip setVelocityTransformation [
	getPos _moShip, 
	getPos shipMarker, 
	[0,0,0], 
	[0,5,0],
	[0,1,0],
	[0,1,0],
	[0,0,1],
	[0,0,1],
	1
];
*/
