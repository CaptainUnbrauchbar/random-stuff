private _result = [];
{
	private _revealValue = _x call bin_fnc_getAntennaRevealValue;
	if (_revealValue > 0) then {
		_result pushback [
			_x,
			-1, //--- Used to be antenna tracking, now obsolete (all antennas are shown by default)
			_revealValue,
			_x call bin_fnc_getAntennaScans
		];
	};
} foreach (true call bin_fnc_getAntennas);
_result