#define VAR		"BIN_PersistentObjects"

if (is3DEN) exitwith {};
params [
	["_input",objnull,[objnull,true]]
];

private _data = missionnamespace getvariable [VAR,[]];

//--- Initialize object
if (_input isequaltype objnull) exitwith {
	private _object = _input;

	private _varName = tolower vehiclevarname _object;
	if (_varName == "") exitwith {["Persistent object %1 cannot be initialized, variable name is missing!",_object] call bis_fnc_error;};

	_index = _data find _varName;
	if (_index >= 0) then {
		(_data # (_index + 1)) params ["_pos","_vector","_damage"];
		if (isnil "_pos") exitwith {};
		_object setposatl _pos;
		_object setvectordirandup _vector;
		if !(_damage isequalto []) then {{_object sethitpointdamage [_x,_damage # _foreachindex];} foreach (getallhitpointsdamage _object # 0);};
	} else {
		_data append [_varName,[]];
		missionnamespace setvariable [VAR,_data];
	};
};

//--- Save all objects
for "_i" from 0 to (count _data  - 1) step 2 do {
	private _object = missionnamespace getvariable [_data # _i,objnull];
	if !(isnull _object) then {
		private _damage = (getallhitpointsdamage _object) param [2,[]];
		if ({_x > 0} count _damage == 0) then {_damage = [];}; //--- Save damage only when it's not 0
		_data set [_i + 1,[getposatl _object,[vectordir _object,vectorup _object],_damage]];
	};
};
_data