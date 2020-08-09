//#define SAVE_IN_PROFILE
#define SAVE_IN_CAMPAIGN

#define PREFIX	"BIN_"

params [["_mode","",[""]]];
private _cfgVariables = configfile >> "CfgContact" >> "Variables";

switch tolower _mode do {
	case "load": {

		//--- Load from profile to mission
		{
			private _var = PREFIX + configname _x;

			#ifdef SAVE_IN_CAMPAIGN
				if (isnil _var) then {missionnamespace setvariable [_var,[_x,"defaultValue"] call bis_fnc_returnconfigentry];};
			#endif
			#ifdef SAVE_IN_PROFILE
				private _value = [_x,"defaultValue"] call bis_fnc_returnconfigentry;
				if !(bin_isEditorSite) then {_value = profilenamespace getvariable [_var,_value];};
				if (_value isequaltype []) then {_value = +_value;};
				missionnamespace setvariable [_var,_value];
			#endif
		} foreach ("true" configclasses _cfgVariables);
	};
	case "save": {

		//--- Save from mission to profile
		{
			private _var = PREFIX + configname _x;
			private _onExit = gettext (_x >> "onExit");
			if (_onExit != "") then {
				private _value = call compile _onExit;
				if !(isnil "_value") then {missionnamespace setvariable [_var,_value];};
			};

			#ifdef SAVE_IN_CAMPAIGN
				savevar _var;
			#endif
			#ifdef SAVE_IN_PROFILE
				profilenamespace setvariable [_var,missionnamespace getvariable _var];
			#endif
		} foreach ("true" configclasses _cfgVariables);

		#ifdef SAVE_IN_PROFILE
			saveprofilenamespace;
		#endif
	};
	case "reset": {

		//--- Set all variables to default values
		{
			private _var = PREFIX + configname _x;

			#ifdef SAVE_IN_CAMPAIGN
				missionnamespace setvariable [_var,[_x,"defaultValue"] call bis_fnc_returnconfigentry];
			#endif
			#ifdef SAVE_IN_PROFILE
				profilenamespace setvariable [_var,[_x,"defaultValue"] call bis_fnc_returnconfigentry];
			#endif
		} foreach ("true" configclasses _cfgVariables);

		#ifdef SAVE_IN_PROFILE
			saveprofilenamespace;
		#endif
	};
	case "debug": {
		_output = "";
		{
			private _var = PREFIX + configname _x;
			private _value = missionnamespace getvariable _var;
			if (!isnil "_value") then {
				private _onExit = gettext (_x >> "onExit");
				if (_onExit != "") then {_value = call compile _onExit;};
				if (!isnil "_value") then {
					if (_value isequaltype "") then {_value = str _value;};
					_output = _output + format ["%1 = %2;",_var,_value] + endl;
				};
			};
		} foreach ("true" configclasses _cfgVariables);
		copytoclipboard _output;
	};
};