private _data = missionnamespace getvariable ["BIN_PersistentObjects",[]];
for "_i" from 0 to (count _data  - 1) step 2 do {
	private _object = missionnamespace getvariable [_data # _i,objnull];
	if !(isnull _object) then {
		private _damage = getallhitpointsdamage _object param [2,[]];
		if ({_x > 0} count _damage == 0) then {_damage = [];}; //--- Save damage only when it's not 0
		_data set [_i + 1,[getposworld _object,[vectordir _object,vectorup _object],_damage]];
	};
};
_data