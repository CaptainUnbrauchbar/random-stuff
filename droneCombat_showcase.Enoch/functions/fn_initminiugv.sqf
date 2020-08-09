#include "\a3\functions_f_contact\ai_misc\defines.inc"

#define MIN_STRENGTH		0.2
#define MIN_STRENGTH_CLEAR	0.3

params [
	["_mode","",[""]],
	["_params",[],[[]]]
];

if (_mode == "weaponAssembled") exitwith {
	_params params ["_unit","_object"];
	if !(unitIsUAV _object) exitwith {};
	if ((getUnitLoadout player # 9 # 1) iskindof ["UavTerminal_base",configfile >> "CfgWeapons"]) exitwith {["Cannot initialize scripted mini-UGV system, player has default UAV terminal. Remove it first!"] call bis_fnc_error;};
	_displayName = gettext (configfile >> "CfgVehicles" >> typeof _object >> "displayName");

	//--- Mark as current
	missionnamespace setvariable ["bin_fnc_initMiniUGV_drone",_object];

	//--- Init UI layers
	"bin_fnc_initMiniUGV_hack" cuttext ["","plain"];
	"bin_fnc_initMiniUGV" cuttext ["","plain"];

	//--- Init antenna
	_antenna = vehiclevarname _object;
	if (_antenna == "") then {_antenna = typeof _object;};
	[_antenna,_object,2,"MiniUGV",nil,nil,nil,nil,nil,true,nil,_displayName] call bin_fnc_setAntenna;
	[_antenna,"EM_Ugv_Enc_01"] call bin_fnc_addSignal;
	[_antenna,2] call bin_fnc_setAntennaCanReveal;
	[_antenna,2] call bin_fnc_setAntennaRevealValue;
	[_antenna,true] call bin_fnc_revealAntenna;
	[_antenna,true] call bin_fnc_revealFrequency;
	_object setvariable ["RscOptics_UGV_02_Science_gunner_ShowSignal",true];
	_object setvariable ["bin_disabled",false];

	if !(_object getvariable ["bin_fnc_initMiniUGV_init",false]) then {
		_object setvariable ["bin_fnc_initMiniUGV_init",true];

		//--- Take control
		player addaction [
			localize "STR_useract_uav_takecontrols",
			{
				["actionTakeControl",_this] call bin_fnc_initMiniUGV;
			},
			_object,
			5.2,
			false,
			true,
			"",
			"!((missionnamespace getvariable ['bin_fnc_initMiniUGV_drone',objnull]) getvariable ['bin_disabled',true])"
		];

		//--- Repair
		_object addaction [
			format [localize "STR_ACTION_REPAIR_VEHICLE",_displayName],
			{
				["actionRepair",_this] spawn bin_fnc_initMiniUGV;
			},
			_object,
			9,
			true,
			true,
			"",
			"_target getvariable ['bin_disabled',false]",
			3
		];

		//--- Connect
		_object addaction [
			localize "STR_useract_uav_uavterminalmakeconnection",
			{
				["actionConnect",_this] call bin_fnc_initMiniUGV;
			},
			_object,
			0,
			false,
			true,
			"",
			"_target != (missionnamespace getvariable ['bin_fnc_initMiniUGV_drone',objnull])",
			3
		];

		//--- Hack
		[
			_object,
			"signalEnded",
			{
				if !(_this call bin_fnc_hackAIDrone) exitwith {};
				["hack",_this] spawn bin_fnc_initMiniUGV;
			}
		] call bis_fnc_addscriptedeventhandler;

		//--- Invincibility
		_object addeventhandler [
			"handledamage",
			{
				["handleDamage",_this] call bin_fnc_initMiniUGV;
			}
		];
	};
};


if (_mode == "weaponDisassembled") exitwith {
	_params params ["_unit","_backpack"];
	_objectClass = gettext (configfile >> "CfgVehicles" >> typeof _backpack >> "assembleInfo" >> "assembleTo");
	_object = missionnamespace getvariable ["bin_fnc_initMiniUGV_drone",objnull];
	if (!isnull _object && {_objectClass == typeof _object && abs (position _object # 2) > 10}) then {
		{_x call bin_fnc_deleteAntenna;} foreach (_object call bin_fnc_getObjectAntennas);
		missionnamespace setvariable ["bin_fnc_initMiniUGV_drone",nil];
	};
};


if (_mode == "handleDamage") exitwith {
	_params params ["_object","_selection","_damage"];

	//--- Make sure global damage will not result in destruction
	if (_selection == "") then {_damage = 0;};

	//--- Some part is destroyed, render the object inoperational
	if (_damage >= 1 && !(_object getvariable ["bin_disabled",false])) then {
		if (cameraon == _object) then {
			objnull remotecontrol _object;
			player switchcamera "internal";
		};
		_smoke = createvehicle ["#particlesource",position _object,[],0,"can_collide"];
		_smoke attachto [_object,[0,0,0]];
		_smoke setparticleclass "UAVWreckSmoke";
		_object setcaptive true;
		_object enableweapondisassembly false;
		_object setvariable ["bin_smoke",_smoke];
		_object setvariable ["bin_disabled",true];
		["miniUGVDamaged",[_object]] call bin_fnc_showSimpleNotification;
	};

	_damage
};


if (_mode == "hack") exitwith {
	_object = (_params # 0) call bin_fnc_getAntennaObject;

	_tick = -1;
	waituntil {
		if (time > _tick) then {
			_object engineon true;
			_object animateSource ["Arm_forward",random 1];
			{_object animate [_x,round random 1,true];} foreach ["ChemDetectorLight","Detector1Light1_Green","Detector1Light1_Red","Detector1Light2_Green","Detector1Light2_Red"];
			_tick = time + random [0,0.1,0.2];
		};
		cameraon == _object
	};
	_object animateSource ["Arm_forward",_object animationsourcephase "Arm_forward",true];
	{_object animate [_x,1,true];} foreach ["ChemDetectorLight","Detector1Light1_Green","Detector1Light1_Red","Detector1Light2_Green","Detector1Light2_Red"];
	_object setvariable ["bin_hacked",false];
};


if (_mode == "actionTakeControl") exitwith {
	_params params ["_target","_caller","_actionId","_object"];

	//--- No signal
	_antenna = (_object call bin_fnc_getObjectAntennas) # 0;
	if (isnil "_antenna") exitwith {
		["miniUGVDamaged",[_object]] call bin_fnc_showSimpleNotification;
	};
	if (["bin_playerP",_antenna] call bin_fnc_getLinkStrength <= MIN_STRENGTH) exitwith {
		["miniUGVTooFar",[_object]] call bin_fnc_showSimpleNotification;
	};

	//--- Unlimited fuel
	_object setfuel 1;

	//--- Switch
	player remotecontrol _object;
	_object switchcamera "internal";

	//--- Hacked effect
	if (_object getvariable ["bin_hacked",false]) then {
		RscStatic_mode = 0;
		"bin_fnc_initMiniUGV" cutrsc ["RscStatic","plain"];
		"bin_fnc_initMiniUGV_hack" cutrsc ["RscRestartOS","plain"];
		[] spawn {
			_soundvolume = soundvolume;
			0 fadesound 0;
			sleep 5;
			RscStatic_mode = 0;
			"bin_fnc_initMiniUGV" cutrsc ["RscStatic","plain"];
			"bin_fnc_initMiniUGV_hack" cuttext ["","plain"];
			1 fadesound _soundvolume;
		};
	} else {
		RscStatic_mode = 0;
		"bin_fnc_initMiniUGV" cutrsc ["RscStatic","plain"];
		_soundvolume = soundvolume;
		0 fadesound 0;
		1 fadesound _soundvolume;
	};
	_object setvariable ["bin_hacked",false];

	//--- Check connection
	[_object] spawn {
		scriptname "BIN_fnc_initMiniUGV: Remote Control";
		params ["_object"];
		_antenna = (_object call bin_fnc_getObjectAntennas) # 0;
		if (isnil "_antenna") exitwith {};
		_pp = ppeffectcreate ["filmgrain",2047];
		_pp ppEffectEnable true;
		waituntil {
			_strength = ["bin_playerP",_antenna] call bin_fnc_getLinkStrength;
			if (_strength <= MIN_STRENGTH) then {
				objnull remotecontrol _object;
				player switchcamera "internal";
				["miniUGVTooFar",[_object]] call bin_fnc_showSimpleNotification;
			};

			_grainIntensity = linearconversion [MIN_STRENGTH_CLEAR,MIN_STRENGTH,_strength,0.01,1,true];
			_pp ppEffectAdjust [_grainIntensity,1,1.5,0.2,0.2,false]; 
			_pp ppEffectCommit 0;
			(uinamespace getvariable ['RscOptics_UGV_02_Science_gunner_CA_Signal',controlnull]) ctrlsettext format ["%1%2",(_strength * 100) tofixed 0,"%"];

			sleep 0.1;
			cameraon != _object
		};
		ppeffectdestroy _pp;
		"bin_fnc_initMiniUGV" cuttext ["","plain"];
		"bin_fnc_initMiniUGV_hack" cuttext ["","plain"];
	};
};


if (_mode == "actionRepair") exitwith {
	_params params ["_object","_selection","_damage","_source","_projectile","_hitIndex","_instigator","_hitPoint"];

	player playactionnow "medic";
	//playsound3d ["A3\Sounds_F\sfx\UI\vehicles\Vehicle_Repair.wss",player,false,getposasl player,1,0.3];
	sleep 4;

	deletevehicle (_object getvariable ["bin_smoke",objnull]);
	_object setdamage 0;
	_object setcaptive false;
	_object enableweapondisassembly true;
	_object setvariable ["bin_disabled",false];
};


if (_mode == "actionConnect") exitwith {
	_params params ["_object","_selection","_damage","_source","_projectile","_hitIndex","_instigator","_hitPoint"];
	missionnamespace setvariable ["bin_fnc_initMiniUGV_drone",_object];
};


if (_mode == "") exitwith {

	player addeventhandler ["weaponAssembled",{["weaponAssembled",_this] call bin_fnc_initMiniUGV;}];
	player addeventhandler ["weaponDisassembled",{["weaponDisassembled",_this] call bin_fnc_initMiniUGV;}];
};