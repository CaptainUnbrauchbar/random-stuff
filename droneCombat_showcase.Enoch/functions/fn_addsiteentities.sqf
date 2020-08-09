/*
	Author: Karel Moricky

	Description:
		Register entities to a site, so they can be despawned with the rest when player leaves the area.

	Parameter(s):
		0: OBJECT - site logic. The site must be spawned for the function to work.
		1: ARRAY - entities to be added. Types can be mixed, the system will sort them out itself.

	Returns:
		BOOL - true if added
*/

#define ADD(ID)\
	(_entities select ID) pushback _x;\
	(_entityIDs select ID) pushback -1;

params [
	["_logic",objnull,[objnull]],
	["_newEntities",[],[[]]]
];

private _content = _logic getvariable "#content";
if (isnil "_content") exitwith {["Cannot add entities, site %1 is not spawned!",_logic] call bis_fnc_error; false};
_content params ["_entities","_entityIDs"];

{
	if (_x isequaltype objnull) then {
		if (_x iskindof "emptydetector") then {
			ADD(2)
		} else {
			if (side _x == sidelogic) then {
				ADD(4)
			} else {
				ADD(0)
			};
			if (vehiclevarname _x != "") then {_x setvariable ["BIN_Site",_logic];};
		};
	} else {
		if (_x isequaltype "") then {
			ADD(5)
		} else {
			if (_x isequaltype grpnull) then {
				ADD(1)
				_x setvariable ["BIN_Site",_logic];
			};
		};
	};
} foreach _newEntities;

true