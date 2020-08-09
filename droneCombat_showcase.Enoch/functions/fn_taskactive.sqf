/*
	Author: Karel Moricky

	Description:
		Return if task is active, i.e., added to player, but not yet completed.
		Only in this state can player assign it.

	Parameter(s):
		0: STRING - task ID

	Returns:
		BOOL

	Example:
		if ("q_schnobble" call bin_fnc_taskActive) then {hint "ACTIVE!";};
*/

params [
	["_taskID","",[""]]
];

!(_taskID call bis_fnc_taskCompleted) && {((player call bis_fnc_tasksUnit) + (BIN_Tasks apply {_x # 0})) findif {_taskID == _x} >= 0}