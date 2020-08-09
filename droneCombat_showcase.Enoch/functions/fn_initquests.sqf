//if !(bin_isFreeRoam || bin_isHub) exitwith {};

params ["_stage"];
private _cfg = configfile >> "CfgContact" >> "Quests";

//--- Get quests list
private _missionQuests = getmissionconfigvalue ["quests",[objnull]];
if (_missionQuests isequalto [objnull] || bin_isEditorSite) then {
	_missionQuests = ("configname _x != missionname" configclasses _cfg); //--- When no sites are defined, use all available ones
} else {
	_missionQuests = _missionQuests apply {_cfg >> _x};
};

if (_stage == 0) then {

	BIN_allTasks = [];
	{
		private _quest = tolower configname _x;

		//--- Register
		private _questIndex = BIN_Quests findif {(_x # 0) == _quest};
		if (_questIndex < 0) then {
			_questIndex = BIN_Quests pushback [_quest,"Start"];
		};

		//--- Add parent task
		[
			_quest,
			nil,
			[gettext (_x >> "description"),gettext (_x >> "title"),gettext (_x >> "antenna")],
			nil,
			nil,
			getnumber (_x >> "priority"),
			nil,
			nil,
			["A","B","C"] select (getnumber (_x >> "priority") max 0 min 3)
		] call bis_fnc_setTask;
		BIN_allTasks pushback _quest;

		//--- Add sub-tasks
		{
			private _task = tolower (_quest + "_" + configname _x);
			[
				[_task,_quest],
				nil,
				[gettext (_x >> "description"),gettext (_x >> "title"),""],
				nil,
				nil,
				getnumber (_x >> "priority"),
				nil,
				nil,
				gettext (_x >> "type")
			] call bis_fnc_setTask;
			missionnamespace setvariable [format ["%1.isHub",_task],getnumber (_x >> "isHub") > 0];
			BIN_allTasks pushback _task;
		} foreach ("true" configclasses (_x >> "Tasks"));

		//--- Simulate specific state in site editor preview
		if (bin_isEditorSite || bin_isSitesTest) then {
			{
				if (configname _x == missionname) then {(BIN_Quests # _questIndex) set [1,gettext _x];};
			} foreach (configproperties [_x >> "DebugSites"]);
		};
	} foreach _missionQuests;

} else {

	{
		//--- Restore task state
		_quest = configname _x;
		_taskIndex = BIN_Tasks findif {(_x # 0) == _quest};
		_target = objnull;
		_state = "CREATED";
		if (_taskIndex >= 0) then {
			_target = player;
			_state = BIN_Tasks # _taskIndex # 1;
		};
		[_quest,_target,nil,nil,_state,nil,false] call bis_fnc_setTask;

		{
			private _task = _quest + "_" + configname _x;

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

			_taskIndex = BIN_Tasks findif {(_x # 0) == _task};
			_target = objnull;
			_state = "CREATED";
			if (_taskIndex >= 0) then {
				_target = player;
				_state = BIN_Tasks # _taskIndex # 1;
			};

			[_task,_target,nil,_destination,_state,nil,false] call bis_fnc_setTask;
		} foreach ("true" configclasses (_x >> "Tasks"));

		//--- Execute quest FSM
		if !(_quest call bis_fnc_taskCompleted) then {
			_questIndex = BIN_Quests findif {(_x # 0) == _quest};
			_questState = if (_questIndex >= 0) then {BIN_Quests # _questIndex # 1} else {"Start"};
			missionnamespace setvariable [
				format ["%1_fsm",_quest],
				[_questState] execvm format ["%1\flow.fsm",gettext (_x >> "directory")]
			];
		};

	} foreach _missionQuests;
};