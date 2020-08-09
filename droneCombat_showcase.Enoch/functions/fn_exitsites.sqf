_vars = [];
{
	_data = [_x,"exit"] call bin_fnc_setSite;
	if !(_data isequalto []) then {_vars pushback [_x getvariable ["#class","<ERROR>"],_data];};
} foreach entities "SiteCore";
_vars;