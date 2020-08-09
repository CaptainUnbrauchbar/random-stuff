#define DEBUG
#define GROUP	(units player - [player])
#define DAMAGE_COEF	0.25
#define DIS_LIMIT_SOFT	400
#define DIS_LIMIT_HARD	600

private _group = group player;

BIN_groupMember_1 = objnull;
BIN_groupMember_2 = objnull;

//if (getnumber (missionconfigfile >> "CfgContact" >> "isGroup") == 0) exitwith {
if !(bin_isFreeRoam) exitwith {

	if (bin_isHub) then {
		_codeCompleted = {
			params ["_target","_caller","_actionId","_arguments"];
			_arguments params ["_id"];
			_group = group player;
			_units = units _group;

			_current = _units param [_id,objnull];

			if (_target in _units) then {

				//--- Swap
				_idOther = if (_id == 1) then {2} else {1};
				[_current,_target] joinsilent grpnull;
				if (_id > _idOther) then {
					_current joinassilent [_group,_idOther];
					_target joinassilent [_group,_id];
				} else {
					_target joinassilent [_group,_id];
					_current joinassilent [_group,_idOther];
				};
			} else {

				//--- Add
				if !(isnull _current) then {[_current] joinsilent grpnull;};
				_target joinassilent [_group,_id];
				_target directsay "SentConfirmOther";
			};
		};

		{
			private _class = tolower configname _x;
			private _var = "BIN_" + _class;
			if (!isnil _var) then {
				private _object = missionnamespace getvariable _var;
				if (_class in bin_groupAvailable) then {

					private _vehicleClass = gettext (_x >> "vehicleClass");
					private _identity = gettext (_x >> "identity");
					if (typeof _object != _vehicleClass) then {["Group member is type %1, should be %2!",typeof _object,_vehicleClass] call bis_fnc_error;};
					_object setvariable ["BIN_groupClass",_class];
					_object setidentity _identity;
					if (_class in bin_group) then {[_object] joinsilent _group;};

					_icon = _object call bin_fnc_getRoleIcon;
					{
						_groupID = _x;
						{
							_x params ["_title","_condition"];
							_title = format [_title,_groupID + 1];
							_condition = format [_condition,_groupID];

							_actionId = _object addaction ["",_codeCompleted,[_groupID],1000,true,true,"",_condition,3];
							//_actionId = [_object,_title,_icon,_icon,_condition,"true",{},{},_codeCompleted,{},[_groupID],1,1000,false] call bis_fnc_holdActionAdd;

							_object setuseractiontext [
								_actionId,
								_title,
								"<img size='2' color='#90000000' image='\a3\UI_F_Contact\Data\CfgIngameUI\CommandBar\unitCombatMode_ca.paa'/>",
								format ["<img size='2' color='#ffffff' image='%2'/><br /><t size='1.2' font='RobotoCondensedBold'>%1</t>",name _object,_icon] + "<br />" + _title
							];
						} foreach [
							["Join as #%1","!(_target in units player) && _target != (units player param [%1,objnull]) && {count units player >= %1}"],
							["Swap to #%1","_target in units player && {_target != (units player param [%1,objnull]) && {count units player == 3}}"]
						];


					} foreach [1,2];
				} else {
					//--- Soldier not available yet / anymore, delete
					deletevehicle _object;
				};
			};
		} foreach ("true" configclasses (configfile >> "CfgContact" >> "Group"));
	};

};

#ifdef DEBUG
	if (time > 0) then {
		player removealleventhandlers "fired";
		player removealleventhandlers "getinman";
		player removealleventhandlers "getoutman";
		player removealleventhandlers "animstatechanged";
		player removealleventhandlers "animdone";
		player removealleventhandlers "animchanged";
		removeallmissioneventhandlers "map";
		removeallmissioneventhandlers "draw3d";
		if !(isnil "bin_fnc_initGroup_loop") then {terminate bin_fnc_initGroup_loop;};
	};
#endif

//--- Load from config
{
	private _cfgGroupMember = configfile >> "CfgContact" >> "Group" >> _x;
	if (isclass _cfgGroupMember) then {
		_x = tolower _x;
		_var = "BIN_" + _x;
		_object = _group createunit [gettext (_cfgGroupMember >> "vehicleClass"),position player vectoradd [2 - 4 * _foreachindex,1,0],[],0,"none"]; //--- ToDo: Better position
		_object setidentity gettext (_cfgGroupMember >> "identity");
		_object setvariable ["BIN_groupClass",_x];
		_object setvehiclevarname _var;
		missionnamespace setvariable [_var,_object];
		missionnamespace setvariable ["BIN_groupMember_" + str (_foreachindex + 1),_object];
		bin_groupAvailable pushbackunique _x; //--- Make sure the soldier is marked as available
	} else {
		["Undefined group member '%1'!",_x] call bis_fnc_error;
	};
} foreach bin_group;

//--- Init states
enablesentences false; //--- Prevent the following orders to be said (enableSentences restored 0.1s later in a spawn code below)
_group setcombatmode "green";
//_group setformation "vee";

//--- Fire on my lead
player addeventhandler [
	"fired",
	{
		params ["_unit","_weapon","_muzzle","_mode","_ammo","_magazine","_projectile"];
		if (_weapon in [primaryweapon player,secondaryweapon player,handgunweapon player,"Throw"]) then {
			{_x setcombatmode "yellow";} foreach GROUP;
		};
	}
];

//--- Copy stance
bin_stance = stance player;
player addeventhandler [
	"animchanged",
	{
		_stance = stance player;
		if (_stance == bin_stance) exitwith {};

		bin_stance = _stance;
		_aiStance = switch _stance do {
			case "STAND": {"UP";};
			case "CROUCH": {"MIDDLE";};
			case "PRONE": {"DOWN";};
			default {"AUTO"};
		};
		{
			_x setunitpos (if (formationleader _x == player && behaviour _x != "COMBAT") then {_aiStance} else {"AUTO"});
		} foreach GROUP;
	}
];

//--- Get in / out vehicles
player addeventhandler [
	"getinman",
	{
		params ["_unit","_role","_vehicle","_turret"];
		{if (lifestate _x in ["HEALTHY","INJURED"]) then {_x moveinany _vehicle;};} foreach GROUP;
	}
];
player addeventhandler [
	"getoutman",
	{
		params ["_unit","_role","_vehicle","_turret"];
		{unassignvehicle _x; dogetout _x;} foreach GROUP;
		group player leavevehicle _vehicle;
	}
];

//--- Member handlers
{
	#ifdef DEBUG
		if (time > 0) then {
			_x removealleventhandlers "killed";
			_x removealleventhandlers "handledamage";
			_x removealleventhandlers "dammaged";
		};
	#endif

	_x addeventhandler [
		"killed",
		{
			params ["_object","_killer","_instigator","_useEffects"];
			player reveal _object;
			cuttext [format ["<img shadow='2' image='\a3\Ui_f\data\GUI\Cfg\Hints\death_ca.paa' size='3' /><br /><br />%1 is down!",name _object],"PLAIN",0,true,true];
			playmusic "EventTrack02_F_EPB";

			_class = _object getvariable ["BIN_groupClass",""];
			bin_group = bin_group - [_class];
			bin_groupAvailable = bin_groupAvailable - [_class]; //--- Unregister from available soldiers
		}
	];

	[_x] call bin_fnc_initRevive;

	_x addeventhandler [
		"handledamage",
		{
			params ["_object","_selection","_damage","_source","_projectile","_hitIndex","_instigator","_hitPoint"];

			private _damagePrev = if (_selection == "") then {damage _object} else {_object gethitpointdamage _hitPoint};
			private _damageDelta = (_damage - _damagePrev) * DAMAGE_COEF;
			_damage = _damagePrev + _damageDelta;
			_damage

			//if (lifestate _object == "INCAPACITATED") then {_damagePrev} else {_damage}
		}
	];
} foreach (units player - [player]);

//--- Mission handlers
addmissioneventhandler [
	"map",
	{
		params ["_mapIsOpened","_mapIsForced"];
		_hud = shownHUD;
		if (_mapIsOpened) then {
			showCommandingMenu "";
			_hud set [6,false]; //--- Hide command bar in the map
		} else {
			_hud set [6,true && acctime == 1];
		};
		showHUD _hud;
	}
];

//--- Loop
bin_fnc_initGroup_loop = [] spawn {
	scriptname "BIN_fnc_initGroup: Loop";
	_timeRearm = time + 60;

	sleep 0.1;
	enablesentences true;

	while {alive player} do {
		_units = (units player - [player]);
		{
			(expecteddestination _x) params ["_pos","_mode"];
			_return = false;

			//--- Unit too far from player
			_dis = _x distance player;
			if (_dis > DIS_LIMIT_HARD) then {
				if (lifestate _x == "INCAPACITATED") then {_x setdamage 1;}; //--- Kill abandoned soldiers

				if (visiblemap || {(worldtoscreen position _x) isequalto []}) then {

					//--- Hard limit - Teleport close when player is not looking
					_newPos = position player getpos [DIS_LIMIT_SOFT,player getdir _x];
					_x setvehicleposition [_newPos,[],0,"none"];
				};
			} else {
				if (_mode == "DoNotPlan" && {_dis > DIS_LIMIT_SOFT}) then {

					//--- Soft limit - break orders and return to formation
					_x groupradio "SentWhereAreYou";
					_return = true;
				};
			};

			//--- Destination too far from player
			if (vehicle _x == _x && {_mode == "LEADER PLANNED" && {_pos distance2d player > DIS_LIMIT_HARD}}) then {
				_x groupradio "SentCommandFailed";
				hint "Position is too far!";
				_return = true;
			};

			if (_return) then {
				[_x] join grpnull;
				_x joinassilent [group player,_foreachindex];
				_x dofollow player;
			};
		} foreach _units;

		//--- Refill ammo every minute
		if (time > _timeRearm) then {
			{_x setunitloadout getunitloadout typeof _x;} foreach _units;
			_timeRearm = time + 60;
		};
		
		sleep 0.1;
	};
};