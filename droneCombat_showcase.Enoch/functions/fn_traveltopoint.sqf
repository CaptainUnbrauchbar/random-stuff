disableserialization;
params [
	["_point","",["",objnull]]
];
if (_point isequaltype "") then {_point = missionnamespace getvariable [_point,objnull];};
if (isnull _point) exitwith {["Travel point not found! Params: %1",_this] call bis_fnc_error; false};

private _isHub = _point getvariable ["isHub",true];

openmap [false,false];

uinamespace setvariable ["RscDisplayTravel_daytimeMin",(ceil (daytime * 2)) / 2 + 1]; //--- Travel always takes 1 hour, rounded up to nearest 1/2 hour
uinamespace setvariable ["RscDisplayTravel_destination",_point getvariable ["displayName","ERROR"]];
uinamespace setvariable [
	"RscDisplayTravel_onOK",
	{
		_display = ctrlparent (_this # 0);
		BIN_daytime = _display getvariable ["daytime",daytime];
		BIN_travelPoint = _display getvariable ["travelPoint",""];

		_point = missionnamespace getvariable [BIN_travelPoint,objnull];
		if (_point getvariable ["isHub",true]) then {"Hub" call bin_fnc_playMission;} else {"FreeRoam" call bin_fnc_playMission;};
	}
];
private _display = (finddisplay 46) createdisplay "RscDisplayTravel";
_display setvariable ["travelPoint",vehiclevarname _point];