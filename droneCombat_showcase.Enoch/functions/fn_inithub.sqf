if (!bin_isHub || bin_isEditorSite) exitwith {};

_refPos = bin_position;
if !(isnull get3dencamera) then {_refPos = position get3dencamera;};

//--- Spawn hub composition
_travelPoint = missionnamespace getvariable [BIN_travelPoint,objnull];
if (isnull _travelPoint) then {
[ (allmissionobjects "ModuleTravel_F") select {_x getvariable ["isHub",true]}] call bis_fnc_log;
	_points = (allmissionobjects "ModuleTravel_F") select {_x getvariable ["isHub",true]} apply {[position _x distance2d _refPos,_x]};
	_points sort true;
	_travelPoint = _points # 0 # 1;
};

_hubPos = getposatl _travelPoint;
_hubDir = direction _travelPoint;

[[],["@player"],_hubPos,_hubDir] call compile preprocessfilelinenumbers "\a3\Missions_F_Contact\Sites\hubSite.Enoch\missionExported.sqf";

//--- Move player to starting position
_starts = allmissionobjects "Sign_Arrow_Direction_F";
_start = selectrandom _starts;
player setposatl getposatl _start;
player setdir direction _start;
{deletevehicle _x} foreach _starts;

//--- Trigger for leaving
_trigger = createtrigger ["emptydetector",_hubPos];
_trigger settriggerarea [100,100,_hubDir,false];
_trigger settriggeractivation ["anyplayer","present",true];
_trigger settriggerstatements [
	"this",
	"",
	"[thistrigger] spawn (thisTrigger getvariable 'onDeactivate');"
];
_trigger setvariable [
	"onDeactivate",
	{
		params ["_trigger"];

		uinamespace setvariable ["RscDisplayTravel_daytimeMin",(ceil (daytime * 2)) / 2 + 0.5]; //--- Travel always takes 1 hour, rounded up to nearest 1/2 hour
		uinamespace setvariable ["RscDisplayTravel_destination","Leaving hub"];
		uinamespace setvariable [
			"RscDisplayTravel_onOK",
			{
				_display = ctrlparent (_this # 0);
				BIN_daytime = _display getvariable ["daytime",daytime];
				"FreeRoam" call bin_fnc_playMission;
			}
		];

		"bin_fnc_initHub" cuttext ["","black out"];
		sleep 1;
		"bin_fnc_initHub" cuttext ["","plain"];

		private _display = (finddisplay 46) createdisplay "RscDisplayTravel";
		player setpos (_trigger getpos [(triggerarea _trigger # 0) * 0.99,_trigger getdir player]);
	}
];