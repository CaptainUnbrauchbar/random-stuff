(player call bis_fnc_tasksUnit) apply {[tolower _x,_x call bis_fnc_taskState]}

/*
private _tasks = [];
{
	_tasks pushback [
		tolower _x,
		_x call bis_fnc_taskState
	];
} foreach (player call bis_fnc_tasksUnit);
_tasks
*/