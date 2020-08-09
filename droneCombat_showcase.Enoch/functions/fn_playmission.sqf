//--- Disabled, campaign is now configured as traditional campaign
if (true) exitwith {};

disableserialization;

params [
	["_mission","",[""]],
	["_resetVariables",false,[false]]
];

//--- In editor, simply end the mission
if (!isnull (finddisplay 313)) exitwith {
	(finddisplay 46) closedisplay 2;
};

private _restart = true;
if (_resetVariables) then {
	"reset" call bin_fnc_persistentVariables;
	_mission = configname (("true" configclasses (configfile >> "CfgMissions" >> "Contact")) param [0,confignull]);
} else {

	//--- Continue previously played mission (or start the first one if undefined)
	if (_mission == "") then {
		_mission = profilenamespace getvariable ["BIN_currentMission",configname (("true" configclasses (configfile >> "CfgMissions" >> "Contact")) param [0,confignull])];
		_restart = false;
	};
};
//--- Save the variables persistently
BIN_currentMission = _mission;
profilenamespace setvariable ["BIN_currentMission",_mission];
saveprofilenamespace;
if (bin_isContact) then {[] call bin_fnc_exit;};

//--- Proceed in onEachFrame - normal script would cause CTD
BIN_restartMission = _restart;
oneachframe {
	_mission = BIN_currentMission;
	_restart = BIN_restartMission;

	//--- Open mission list and pick the mission
	private _display = (finddisplay 0) createMissionDisplay ["","Contact"];
	private _ctrlTree = _display displayctrl 101;
	private _cursel = -1;

	for "_i" from 0 to ((_ctrlTree tvcount []) - 1) do {
		if ((_ctrlTree tvdata [_i]) == _mission) exitwith {_cursel = _i;};
	};
	if (_cursel < 0) exitwith {["Mission '%1' not found in CfgMissions >> Contact!",_mission] call bis_fnc_error; false};
	_ctrlTree tvSetCurSel [_cursel];

	//--- Hit PLAY button
	private _ctrlRestart = _display displayctrl 105;
	if (ctrlshown _ctrlRestart && _restart) then {
		ctrlactivate _ctrlRestart;
		private _displayMsgBox = uinamespace getvariable "RscMsgBox";
		ctrlactivate (_displayMsgBox displayctrl 1);
	} else {
		ctrlactivate (_display displayctrl 1);
	};
	_display closedisplay 2;
	oneachframe {};
};