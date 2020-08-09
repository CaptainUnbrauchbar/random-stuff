if !(cheatsenabled) exitwith {};
[
	"bin_diagQuests",
	"Quests",
	bin_quests apply {[_x # 0,(missionNamespace getVariable [(_x # 0) + "_state",[0,"N/A"]]) # 1]},
	[0.75,0.5,1,1]
] call bin_fnc_debugText;