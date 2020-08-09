/*
	Author: Karel Moricky

	Description:
		Return if task was added to player.
		Includes both finished and unfinished tasks.

	Parameter(s):
		0: STRING - task ID

	Returns:
		BOOL

	Example:
		if ("q_schnobble" call bin_fnc_taskAdded) then {hint "ADDED!";};
*/

params [
	["_taskID","",[""]]
];

((player call bis_fnc_tasksUnit) + (BIN_Tasks apply {_x # 0})) findif {_taskID == _x} >= 0