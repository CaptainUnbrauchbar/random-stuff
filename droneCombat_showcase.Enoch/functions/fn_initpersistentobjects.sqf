params [
	["_class","",[""]]
];

private _data = missionnamespace getvariable ["BIN_PersistentObjects",[]];
{
	if !(isnull _x) then {
		private _object = _x;
		private _varName = tolower vehiclevarname _object;
		if (_varName != "") then {
			_index = _data find _varName;
			if (_index >= 0) then {
				(_data # (_index + 1)) params ["_pos","_vector","_damage"];
				if !(isnil "_damage") then {

					//--- Restore saved properties
					_object setposworld _pos;
					_object setvectordirandup _vector;
					if !(_damage isequalto []) then {{_object sethitpointdamage [_x,_damage # _foreachindex];} foreach (getallhitpointsdamage _object # 0);};
				};
			} else {

				//--- Mark as persistent
				_data append [_varName,[]];
				missionnamespace setvariable ["BIN_PersistentObjects",_data];
			};
		} else {
			["Persistent object %1 cannot be initialized, variable name is missing!",_object] call bis_fnc_error;
		};
	};
} foreach ((missionnamespace getvariable [format ["%1_@Persistent",_class],[[]]]) # 0);