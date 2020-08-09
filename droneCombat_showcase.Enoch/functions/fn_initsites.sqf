#define DEBUG
#define AREA_BUFFER	+200
#define DEF_RADIUS	500
#define DEF_RADIUS_OUT	550
#define AREA_DEF	[position _logic,DEF_RADIUS_OUT,DEF_RADIUS_OUT,0,false]

private _cfg = configfile >> "CfgContact" >> "Sites";

//--- Call "siteSpawned" straight away when a site is already spawned
[
	missionnamespace,
	"ScriptedEventHandlerAdded",
	{
		params ["_logic","_name","_handlerID"];
		if (_name != "BIS_fnc_addScriptedEventHandler_siteSpawned") exitwith {};
		if (_logic getvariable ["#spawned",false]) then {
			[_logic,"siteSpawned",[_logic getvariable ["#content",[[],[]]]]] call bis_fnc_callscriptedeventhandler;
			[missionnamespace,"siteSpawned",[_logic]] call bis_fnc_callscriptedeventhandler;
		};
	}
] call bis_fnc_addscriptedeventhandler;

//--- Initialize the site currently previewed in the editor
//_isEditorSite = !((bin_isFreeRoam && !bin_isEditorSite) || bin_isHub);
_isEditorSite = bin_isEditorSite;
if (_isEditorSite) then {
	if (isnull finddisplay 313) exitwith {}; //--- Exit when not in editor
	_class = missionname;
	_classFound = false;
	{
		//--- Site editor preview - delete layers which are not visible
		if (configname _x == _class) exitwith {
			_classFound = true;
			_logic = missionnamespace getvariable [_class,objnull];
			_logic setvariable ["#class",_class];
			_area = [position _logic] + (_logic getvariable ["objectArea",[DEF_RADIUS,DEF_RADIUS,0,false]]);
			_logic setvariable ["areaIn",_area];
			_area = +_area;
			_area set [1,(_area # 1) AREA_BUFFER];
			_area set [2,(_area # 2) AREA_BUFFER];
			_logic setvariable ["areaOut",_area];
			{
				if !(_x # 1) then {
					_entities = getMissionLayerEntities (_x # 0);
					{
						_obj = _x;
						{_obj deletevehiclecrew _x;} foreach crew _obj;
						deletevehicle _obj;
					} foreach (_entities # 0);
					{
						deletemarker _x;
					} foreach (_entities # 1);
				};
			} foreach (uiNamespace getvariable ["bin_3den_layers",[]]);

			if !(isnil "bin_missionPreview") then {
				_entities = [[],[],[],[],[],[]];
				_entityIDs = [[],[],[],[],[],[]];
				for "_e" from 0 to 3 do {
					_in = bin_missionPreview # _e;
					_out = _entities # _e;
					_outID = _entityIDs # _e;
					for "_i" from 0 to (count _in - 1) step 2 do {
						if (_e == 0 && {side (_in # _i) == sidelogic}) then {
							(_entities # 4) pushback (_in # (_i));
							(_entityIDs # 4) pushback (_in # (_i + 1));
						} else {
							_out pushback (_in # (_i));
							_outID pushback (_in # (_i + 1));
						};
					};
				};
				_logic setvariable ["#content",[_entities,_entityIDs]];
			};
			_logic setvariable ["#spawned",true];

			private _all = allmissionobjects "All";
			private _logics = _all select {side group _x == sidelogic};
			private _triggers = _all select {_x iskindof "emptydetector"};
			private _objects = _all - _logics - _triggers;
			private _groups = allgroups select {side _x != sidelogic};
			private _waypoints = [];
			{_waypoints append waypoints _x;} foreach _groups;
			private _content = [[_objects,_groups,_triggers,[],_logics,allmapmarkers],[[],[],[],[],[],[]]];
			{_x setvariable ["bin_site",_logic];} foreach ((_content # 0 # 0) select {vehiclevarname _x != ""});
			{_x setvariable ["bin_site",_logic];} foreach (_content # 0 # 4);
			{_x setvariable ["bin_site",_logic]; _x call bin_fnc_initAISquad;} foreach (_content # 0 # 1);
			_logic setvariable ["bin_reinforcementsPoints",(_content # 0 # 4) select {typeof _x == "ReinforcementsPoint"}];

			_logic call compile preprocessfilelinenumbers "start.sqf";
			_logic call compile preprocessfilelinenumbers "spawn.sqf";
			_logic call compile preprocessfilelinenumbers "persistent.sqf";
			_logic call compile preprocessfilelinenumbers "editor.sqf";
			[_logic,"draw"] call bin_fnc_setSite;

			[_logic,"siteInit",[_content]] call bis_fnc_callscriptedeventhandler;
			[_logic,"siteSpawned",[_content]] call bis_fnc_callscriptedeventhandler;
			[missionnamespace,"siteSpawned",[_logic]] call bis_fnc_callscriptedeventhandler;
		};
	} foreach ("true" configclasses _cfg);
	//if !(_classFound) then {
	//	["Class %1 not found in CfgContact >> Sites!",_class] call bis_fnc_error;
	//};
};

//--- Get sites list
private _missionSites = getmissionconfigvalue ["sites",[objnull]];
if (_missionSites isequalto [objnull]/* || _isEditorSite*/) then {
	_missionSites = ("configname _x != missionname" configclasses _cfg); //--- When no sites are defined, use all available ones
} else {

	_missionSites = _missionSites apply {
		private _cfgSite = _cfg >> _x;
		if (isnull _cfgSite) then {["The mission lists site '%1', but it doesn't exist! Update sites[] in description.ext.",_x] call bis_fnc_error;};
		_cfgSite
	} select {
		!isnull _x
	};
};

//--- Regular process
private _directory = gettext (_cfg >> "directory");
private _defaultWorld = gettext (_cfg >> "defaultWorld");
private _logics = [];
{
	_class = tolower configname _x;
	_world = gettext (_x >> "world");
	if (_world == "") then {_world = _defaultWorld;};
	_path = format ["%1%2.%3\",_directory,_class,_world];

	#ifdef DEBUG
		_drawIcons = [];
		_drawEllipses = [];
	#endif

	//--- Initial spawn
	//_content = [["@start","@persistent"]] call compile preprocessfilelinenumbers (_path + "missionExported.sqf");
	_layersStart = getarray (_x >> "layersStart");
	_layersPersistent = getarray (_x >> "layersPersistent");
	if (_layersStart isequalto []) then {_layersStart = ["@start"];}; //--- Backward compatibility
	if (_layersPersistent isequalto []) then {_layersPersistent = ["@persistent"];}; //--- Backward compatibility
	_content = [_layersStart + _layersPersistent] call compile preprocessfilelinenumbers (_path + "missionExported.sqf");

	if !(isnil "_content") then {
		_logic = missionnamespace getvariable [_class,objnull];
		if !(isnull _logic) then {
			_area = [position _logic] + (_logic getvariable ["objectArea",[DEF_RADIUS,DEF_RADIUS,0,false]]);
			_logic setvariable ["areaIn",_area];
			_area = +_area;
			_area set [1,(_area # 1) AREA_BUFFER];
			_area set [2,(_area # 2) AREA_BUFFER];
			_logic setvariable ["areaOut",_area];

			_conditions = [];
			if (isarray (_x >> "layers")) then {
				{_conditions pushback [tolower (_x # 0),compile (_x # 1)];} foreach (getarray (_x >> "layers"));
			} else {
				{_conditions pushback [tolower configname _x,compile gettext _x];} foreach (configproperties [_x >> "Layers"]); //--- Backward compatibility
			};
			_logic setvariable ["#conditions",_conditions];
			_logic setvariable ["#class",_class];
			_logic setvariable ["#path",_path];
			_logic setvariable ["#contentInit",_content];
			_logic setvariable ["#index",_foreachindex];
			_logics pushback _logic;

			[_logic,"init"] call bin_fnc_setSite;
		} else {
			["Logic missing for site %1!",_class] call bis_fnc_error;
		};
	};
} foreach _missionSites;

//--- No ongoing functionality when playing specific site from the editor
if (_isEditorSite) exitwith {};

//--- Apply persistent data
//bin_sites = [["0602_firefight",[]],["089020_radiotower",[["#k",[3]],["#m",[13]]]]];
{
	_logic = (missionnamespace getvariable [_x # 0,objnull]);
	{
		_logic setvariable _x;
	} foreach (_x # 1);
} foreach (missionnamespace getvariable ["bin_sites",[]]);

//--- Mark weapon holders as changed, so they are not spawned again
player addeventhandler ["take",{(_this # 1) setvariable ["#changed",true];}];

//--- Initial spawn
private _pos = position player;
{
	private _logic = _x;
	if !(_logic getvariable ["#spawned",false]) then {
		if (_pos inarea (_logic getvariable ["areaIn",AREA_DEF])) then {
			[_logic,"spawn"] call bin_fnc_setSite;
		};
	};
} foreach _logics;

//--- Loop checking the proximity to sites
[_logics] spawn {
	scriptname "BIN_fnc_initSites: Loop";
	params ["_logics"];
	while {alive player} do {
		_entities = if (player == cameraon) then {[player]} else {[player,cameraon]};
		_positions = _entities apply {position _x};
		{
			_logic = _x;
			if !(_logic getvariable ["#spawned",false]) then {
				if !((_positions inareaarray (_logic getvariable ["areaIn",AREA_DEF])) isequalto []) then {
					_spawn = [_logic,"spawn"] spawn bin_fnc_setSite;
					waituntil {scriptdone _spawn};
					if !(_logic getvariable ["#spawned",false]) then {["Error when spawning site %1!",vehiclevarname _logic] call bis_fnc_error;};
				};
			} else {
				if ((_positions inareaarray (_logic getvariable ["areaOut",AREA_DEF])) isequalto []) then {
					_spawn = [_logic,"despawn"] spawn bin_fnc_setSite;
					waituntil {scriptdone _spawn};
					if (_logic getvariable ["#spawned",true]) then {["Error when despawning site %1!",vehiclevarname _logic] call bis_fnc_error;};
				};
			};
			sleep 0.1;
		} foreach _logics;
		sleep 1;
	};
};