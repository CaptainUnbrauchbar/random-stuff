private _grp = creategroup civilian;
{
	private _var = gettext (_x >> "variable");
	if (_var != "" && {isnil _var}) then {
		private _actor = _grp createunit ["C_man_1",[5697.67,3759,20],[],0,"can_collide"]; //--- The position is HQ's pos
		_actor hideobject true;
		_actor allowdamage false;
		_actor stop true;
		_actor setidentity configname _x;
		_actor linkitem "itemRadio";
		_actor setvehiclevarname _var;
		//_actor setvariable ["bis_fnc_kbTell_antenna","Home"];
		missionnamespace setvariable [_var,_actor];
	};
} foreach ("isclass _x" configclasses (configfile >> "CfgIdentities"))