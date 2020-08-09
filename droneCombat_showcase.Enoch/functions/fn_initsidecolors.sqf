#define FORMAT "Map_%1_%2"
{
	private _side = _x;
	private _overload = getmissionconfigvalue ["color" + _side,""];
	if (_overload != "") then {
		{
			missionnamespace setvariable [format [FORMAT,_side,_x],profilenamespace getvariable [format [FORMAT,_overload,_x],1]];
		} foreach ["R","G","B","A"];
	};
} foreach ["BLUFOR","OPFOR","Independent","Civilian","Unknown"];