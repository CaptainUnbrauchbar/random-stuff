private _input = +(missionnamespace getvariable ["bin_createDiaryRecord_list",[]]);
private _records = [];
for "_i" from 0 to (count _input - 1) step 2 do {
	_records pushback [_input # _i,(_input # (_i + 1)) param [5,false]];
};
_records