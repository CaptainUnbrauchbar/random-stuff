{
	private _cfgRecord = configfile >> "CfgContact" >> "Diary" >> _x param [0,""];
	if (isclass _cfgRecord) then {
		[_cfgRecord,nil,nil,nil,nil,_x param [1,false]] call bin_fnc_setDiaryRecord;
	};
} foreach bin_diary;