//--- Debug
_draw = [];
{
	if (count _x > 1) then {
		_posPrev = _x # 0;
		for "_i" from 0 to 1 step (1 / 64) do {
			_pos = _i bezierinterpolation _x;
			_draw pushback [_posPrev,_pos,[1,0,0,1]];
			_posPrev = _pos;
		};
	};
} foreach getarray (missionconfigfile >> "CfgIDWMap" >> "staticDataLayers");
["bin_diagProbeMap","network","line",_draw] call bin_fnc_debugDraw;

//--- Probe mapping not enabled
if (getnumber (missionconfigfile >> "CfgContact" >> "isProbeMapping") == 0 && !bin_isEditorSite) exitwith {};

//--- Init pre-defined measure points
_time = time + 5;
waituntil {BIN_ProbeMap isequalto [] || time > _time}; //--- Wait for BIN_fnc_drawProbeMap to be initialized first (timeout in case something fails)
if (call bin_fnc_allIDWMapMeasurementPoints isequalto []) then {
	{_x call BIN_fnc_addIDWMapMeasurementPoint;} foreach getarray (missionconfigfile >> "CfgIDWMap" >> "defaultMeasurementPoints");//bin_probeMapMeasurements;
	[] spawn BIN_fnc_updateIDWMapDrawData;
};

//--- Loop
_step = 40^2;
_posLast = position cameraon;
_timeLast = time;
_valueLast = 0;
while {alive player} do {
	_posCurrent = position cameraon;
	if (
		_posCurrent distancesqr _posLast > _step
		&&
		{backpack player == "B_UGV_02_Science_backpack_F" || {typeof cameraon == "B_UGV_02_Science_F"}}
	) then {
		_value = _posCurrent call BIN_fnc_addIDWMapMeasurementPoint;
		if (_value > _valueLast && time > _timeLast + 30) then {
			["probeMap",[_value,_valueLast]] spawn bin_fnc_showSimpleNotification;
			_timeLast = time;
		};
		if (visiblemap) then {[] spawn BIN_fnc_updateIDWMapDrawData;};
		_posLast = _posCurrent;
		_valueLast = _value;
	};

	sleep 1;
};