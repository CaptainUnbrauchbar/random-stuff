{
	missionnamespace setvariable [
		"BIN_" + configname _x,
		_x call bis_fnc_returnConfigEntry
	];
} foreach configproperties [configfile >> "CfgContact" >> "Constants"];