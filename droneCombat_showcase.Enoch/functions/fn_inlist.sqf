params [
	["_object",objnull,[objnull]],
	["_triggerVar","",[""]],
	["_defValue",false,[false]]
];

private _trigger = missionnamespace getvariable [_triggerVar,objnull];
private _list = list _trigger;
if (isnil "_list") exitwith {_defValue};
_object in _list