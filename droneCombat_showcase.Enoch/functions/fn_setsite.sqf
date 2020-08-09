#define DEBUG
#define ALPHA_ON	1.0
#define ALPHA_OFF	0.4
#define DRAW(SHOW)\
	_color = [[1,0,0,1],[0,1,0,1],[0,0,1,1],[1,1,0,1],[1,0,1,1],[0,1,1,1],[1,0.5,0,1]] select ((_logic getvariable ["#index",0]) % 7);\
	if !(SHOW) then {_color set [3,0.4];};\
	_drawIcon = ["\a3\Ui_f\data\Map\LocationTypes\borderCrossing_CA.paa",_color,position _logic,0.75,0.75,0,_class,2,0.04,"RobotoCondensed","right"];\
	["bin_diagSites",_class,"icon",[_drawIcon]] call bin_fnc_debugDraw;\
	_isRectangle = false;\
	_drawArea = if (SHOW) then {\
		_areaOut = _logic getvariable ["areaOut",[position _logic,0,0,0,false]];\
		_isRectangle = _areaOut select 4;\
		[_areaOut select 0,_areaOut select 1,_areaOut select 2,_areaOut select 3,_color,""]\
	} else {\
		_areaIn = _logic getvariable ["areaIn",[position _logic,0,0,0,false]];\
		_isRectangle = _areaIn select 4;\
		[_areaIn select 0,_areaIn select 1,_areaIn select 2,_areaIn select 3,_color,""]\
	};\
	["bin_diagSites",_class,if (_isRectangle) then {"rectangle"} else {"ellipse"},[_drawArea]] call bin_fnc_debugDraw;

#define VAR_IGNORE	"$i"
#define VAR_KILL	"$k"
#define VAR_VISITED	"$v"
#define VAR_SPAWNED	"#spawned"

params [
	["_logic",objnull,[objnull]],
	["_mode","",[""]],
	["_params",[]]
];
private _path = _logic getvariable ["#path",""];
private _class = _logic getvariable ["#class",""];

switch _mode do {

	case "init": {
		_class call bin_fnc_initPersistentObjects;

		private _content = _logic getvariable ["#contentInit",[[[],[],[],[],[],[]],[[],[],[],[],[],[]]]];
		_logic setvariable [VAR_SPAWNED,false];

		{_x setvariable ["bin_site",_logic];} foreach (_content # 0 # 1);
		{_x setvariable ["bin_site",_logic];} foreach (_content # 0 # 4);

		_logic call compile preprocessfilelinenumbers (_path + "start.sqf");
		_logic call compile preprocessfilelinenumbers (_path + "persistent.sqf");

		#ifdef DEBUG
			DRAW(false)
		#endif

		[_logic,"siteInit",[_content]] call bis_fnc_callscriptedeventhandler;
	};

	case "spawn": {

		private _whitelist = [];
		private _conditions = _logic getvariable ["#conditions",[]];
		{if (call (_x # 1)) then {_whitelist pushback (_x # 0);};} foreach (_conditions);

		#ifdef DEBUGx
			//--- Show a window where the player can toggle specific layers
			if (uinamespace getvariable ["bin_diagSites",false] && count _conditions > 0) then {
				uinamespace setvariable ["RscDisplaySiteConditions_input",[_class,_conditions,_whitelist]];
				(finddisplay 46) createdisplay "RscDisplaySiteConditions";
				waituntil {isnull (uinamespace getvariable ["RscDisplaySiteConditions",displaynull])};
				_whitelist = uinamespace getvariable ["RscDisplaySiteConditions_output",_whitelist];
			};
		#endif
		#ifdef DEBUG
			DRAW(true)
		#endif

		private _idsMissing = _logic getvariable [VAR_IGNORE,[]];
		private _idsKilled = _logic getvariable [VAR_KILL,[]];

		private _layersPersistent = getarray (configfile >> "CfgSites" >> _class >> "layersPersistent");
		if (_layersPersistent isequalto []) then {_layersPersistent = ["@persistent"];};
		private _content = [[true] + _layersPersistent + _whitelist,nil,nil,nil,_idsMissing] call compile preprocessfilelinenumbers (_path + "missionExported.sqf");
		_content params ["_entities","_entityIDs"];

		//--- Destroy previously destroyed objects
		{
			private _index = (_entityIDs # 0) find _x;
			if (_index >= 0) then {
				(_entities # 0 # _index) setdamage [1,false];
			};
		} foreach _idsKilled;

		_class call bin_fnc_initPersistentObjects;

		//--- Save site reference to named objects and groups
		isnil {
			{_x setvariable ["bin_site",_logic];} foreach ((_content # 0 # 0) select {vehiclevarname _x != ""});
			{_x setvariable ["bin_site",_logic];} foreach (_content # 0 # 4);
			{_x setvariable ["bin_site",_logic]; _x call bin_fnc_initAISquad;} foreach (_content # 0 # 1);
			_logic setvariable ["bin_reinforcementsPoints",(_content # 0 # 4) select {typeof _x == "ReinforcementsPoint"}];

			_logic setvariable ["#content",_content];
			_logic setvariable [VAR_VISITED,(_logic getvariable [VAR_VISITED,0]) + 1];
			_logic call compile preprocessfilelinenumbers (_path + "spawn.sqf");
			_logic call compile preprocessfilelinenumbers (_path + "persistent.sqf");
			_logic setvariable [VAR_SPAWNED,true];
		};

		[_logic,"siteSpawned",[_content]] call bis_fnc_callscriptedeventhandler;
		[missionnamespace,"siteSpawned",[_logic]] call bis_fnc_callscriptedeventhandler;

		["Site %1 spawned with layers %2.",_class,_whitelist] call bis_fnc_logformat;
	};

	case "despawn": {
		private _area = _logic getvariable ["areaIn",[position _logic,99999,99999,0,false]];
		private _content = _logic getvariable ["#content",[[[],[],[],[],[],[]],[[],[],[],[],[],[]]]];

		[_logic,"siteDespawned",[_content]] call bis_fnc_callscriptedeventhandler;
		[missionnamespace,"siteDespawned",[_logic]] call bis_fnc_callscriptedeventhandler;

		_content params ["_entities","_entityIDs"];
		_logic call compile preprocessfilelinenumbers (_path + "despawn.sqf");
		{
			private _obj = _x;
			if !(_obj getvariable ["bin_spawnFresh",false]) then {
				private _inArea = _obj inarea _area;
				private _toKill = !isnull _obj && !alive _obj;
				private _toIgnore = !_inArea || (_obj getvariable ["#changed",false]) || (_toKill && _obj iskindof "AllVehicles");

				if (_toIgnore) then {
					private _missing = _logic getvariable [VAR_IGNORE,[]];
					_missing pushbackunique (_entityIDs # 0 # _foreachindex);
					_logic setvariable [VAR_IGNORE,_missing];
				} else {
					if (_toKill) then {
						//--- Save killed object persistently, and don't delete them in this instance
						private _killed = _logic getvariable [VAR_KILL,[]];
						_killed pushbackunique (_entityIDs # 0 # _foreachindex);
						_logic setvariable [VAR_KILL,_killed];
					} else {
						if (_inArea) then { //--- Todo: Add to garbage collector which checks distance
							{_obj deletevehiclecrew _x;} foreach crew _obj;
							deletevehicle _obj;
						};
					};
				};
			};
		} foreach (_entities # 0);
		{deletegroup _x;} foreach (_entities # 1); //--- Groups
		{deletevehicle _x;} foreach (_entities # 2); //--- Triggers
		{deletevehicle _x;} foreach (_entities # 4); //--- Logics
		{deletemarker _x;} foreach (_entities # 5); //--- Markers
		_logic setvariable ["#content",nil];
		_logic setvariable [VAR_SPAWNED,false];
		["Site %1 despawned.",_class] call bis_fnc_logformat;

		#ifdef DEBUG
			DRAW(false)
		#endif
	};

	case "exit": {
		_params params [["_dummyCall",false,[true]]];

		private _area = _logic getvariable ["areaIn",[position _logic,99999,99999,0,false]];
		private _content = _logic getvariable ["#content",[[[],[],[],[],[],[]],[[],[],[],[],[],[]]]];

		[_logic,"siteDespawned",[_content]] call bis_fnc_callscriptedeventhandler;
		[missionnamespace,"siteDespawned",[_logic]] call bis_fnc_callscriptedeventhandler;

		_content params ["_entities","_entityIDs"];
		{
			private _obj = _x;
			private _inArea = _obj inarea _area;
			private _toKill = !isnull _obj && !alive _obj;
			private _toIgnore = !_inArea || (_obj getvariable ["#changed",false]) || (_toKill && _obj iskindof "AllVehicles");

			if (_toIgnore) then {
				private _missing = _logic getvariable [VAR_IGNORE,[]];
				_missing pushbackunique (_entityIDs # 0 # _foreachindex);
				_logic setvariable [VAR_IGNORE,_missing];
			} else {
				if (_toKill) then {
					//--- Save killed object persistently, and don't delete them in this instance
					private _killed = _logic getvariable [VAR_KILL,[]];
					_killed pushbackunique (_entityIDs # 0 # _foreachindex);
					_logic setvariable [VAR_KILL,_killed];
				};
			};
		} foreach (_entities # 0);

/*
		private _contentInit = _logic getvariable ["#contentInit",[[[],[],[],[],[],[]],[[],[],[],[],[],[]]]];
		_contentInit params ["_entitiesInit","_entityIDsInit"];
		_presistentObjects = [];
		{
			if (_x getvariable ["#p",false]) then {
				_presistentObjects pushback ([_x,true] call bin_fnc_setPersistentObject);
			};
		} foreach (_entitiesInit # 0);
*/
		//if !(_dummyCall) then {_logic call compile preprocessfilelinenumbers (_path + "exit.sqf");};

		//--- Save all variables with prefix $
		private _data = [];
		{
			_data pushback [_x,_logic getvariable _x];
		} foreach (allvariables _logic select {(_x select [0,1]) == "$"});
		_data
	};
	case "draw": {
		#ifdef DEBUG
			DRAW(true)
		#endif
	};
};