//--- Obsolete, replace dby BIN_fnc_initQuests
if (true) exitwith {};


//BIN_Tasks = [["civ_radiotower_investigate","CREATED"],["mil_firefight_investigate","SUCCEEDED"]];

params ["_stage"];

if (_stage == 0) then {

	//--- Create tasks (before sites, so they won't assign them incorrectly)
	_tasks = [];
	{
		_tasks pushback [
			getnumber (_x >> "priority"),
			gettext (_x >> "type"),
			gettext (_x >> "title"),
			gettext (_x >> "description"),
			gettext (_x >> "parent"),
			tolower configname _x
		];
		if ((bin_isEditorSite || bin_isSitesTest) && {getnumber (_x >> "editor") > 0 && {(configname _x) find missionname >= 0}}) then {BIN_Tasks pushback [tolower configname _x,"CREATED"]};
	} foreach ("true" configclasses (configfile >> "CfgContact" >> "Tasks"));
	_tasks sort false;
	{
		_x params ["_priority","_type","_title","_description","_parent","_class"];
		[[_class,_parent],nil,[_description,_title,""],nil,nil,_priority,nil,nil,_type] call bis_fnc_setTask;
	} foreach _tasks;

} else {

	//--- Position tasks (only after site objects were created)
	{
		_class = configname _x;

		_destination = if (istext (_x >> "destination")) then {gettext (_x >> "destination")} else {getarray (_x >> "destination")};
		if (_destination isequaltype "") then {
			if (_destination == "") then {
				_destination = objnull;
			} else {
				_destination = call compile _destination;
				if (isnil "_destination") then {_destination = objnull;};
			};
		} else {
			if (_destination isequaltypearray ["",0] || _destination isequaltypearray [""]) then {
				_destination = [missionnamespace getvariable (_destination # 0),if ((_destination param [1,0]) > 0) then {true} else {false}];
			} else {
				if !(_destination isequaltypearray [0,0,0]) then {_destination = objnull};
			};
		};

		_taskIndex = BIN_Tasks findif {(_x # 0) == _class};
		_target = objnull;
		_state = "CREATED";
		if (_taskIndex >= 0) then {
			_target = player;
			_state = BIN_Tasks # _taskIndex # 1;
		};

		[_class,_target,nil,_destination,_state,nil,false] call bis_fnc_setTask;

	} foreach ("true" configclasses (configfile >> "CfgContact" >> "Tasks"));
};