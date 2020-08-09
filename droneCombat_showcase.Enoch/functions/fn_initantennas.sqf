#include "\a3\Functions_F_Contact\EM_Core\defines.inc"

[
	missionnamespace,
	"antennaAdded",
	{
		params ["_antenna"];
		private _id = BIN_AntennaScans findif {(_x # 0) == _antenna};
		if (_id >= 0) then {
			(BIN_AntennaScans # _id) params ["","","_revealValue","_scans"];
			[_antenna,_revealValue] call bin_fnc_setAntennaRevealValue;
			[_antenna,_scans] call bin_fnc_setAntennaScans;

			private _source = GET_DRAW_SOURCE(GET_SCAN_DRAW(_scans));
			if !(_source isequalto []) then {
				_setScanPolygon = "biext_txscan" callExtension ["setScanPolygon",[_antenna] + _source];
				if (_setScanPolygon call BIN_fnc_isExtensionError) then {["Setting scan polygon of '%1' failed! Polygon: %2",_antenna,GET_SCAN_DRAW(_scans)] call bis_fnc_error;};
			};
		};
	}
] call bis_fnc_addscriptedeventhandler;