addmissioneventhandler [
	"HandleAccTime",
	{
		params ["_current","_prev","_scripted"];
		if (_scripted) exitwith {};

		if ([] call bin_fnc_inDangerZone) then {
			setacctime 1;
			if (time > missionnamespace getvariable ["bin_fnc_initAcctime_time",-1]) then {
				["dangerzone",["acctime"]] call bin_fnc_showSimpleNotification;
				bin_fnc_initAcctime_time = time + 10;
			};
			true //--- Disable notification
		} else {
			playsound [["border_out","border_in"] select (_current > _prev),true];
			false
		};
	}
];

if (true) exitwith {};


// Increase time multiplier when simulation time is accelerated
//#define TIME_MULTIPLIER

#ifdef TIME_MULTIPLIER
bin_acctime = acctime;
if (isnil "bin_fnc_initAcctime_radialblur") then {
	bin_fnc_initAcctime_radialblur = ppeffectcreate ["radialBlur",178];
	bin_fnc_initAcctime_radialblur ppeffectadjust [0,0,0.1,0.2];
	bin_fnc_initAcctime_radialblur ppeffectcommit 0;
	bin_fnc_initAcctime_radialblur ppeffectenable true;
};
#endif

removemissioneventhandler ["eachframe",missionnamespace getvariable ["bin_fnc_initAcctime_eachframe",-1]];
missionnamespace setvariable [
	"bin_fnc_initAcctime_eachframe",
	addmissioneventhandler [
		"eachframe",
		{
			if (acctime > 1 && {[] call bin_fnc_inDangerZone}) exitwith {setacctime 1;};
			if (acctime > 1 && {cameraview == "gunner"}) then {setacctime 1;};

			#ifdef TIME_MULTIPLIER
			if (acctime != bin_acctime) then {
				//--- Limit acctime to only 1x and 4x as opposed to default 1x, 2x and 4x
				//if (bin_acctime < acctime) then {setacctime 4;} else {setacctime 1;};

				//--- Set world time acceleration
				settimemultiplier ((acctime^3) min 32); // 1x = 1, 2x = 16, 4x = 32

				_standardTime = acctime == 1;
				_hud = shownhud;
				_hud set [1,_standardTime]; //--- Info
				_hud set [6,_standardTime]; //--- Group
				_hud set [7,_standardTime && !visiblemap]; //--- Group
				_hud set [8,_standardTime]; //--- Cursors
				showhud _hud;

				0.4 fadesound ([0.3,1] select _standardTime);

				if (acctime == 1 || bin_acctime == 1) then {
					playsound [["border_out","border_in"] select (acctime > bin_acctime),true];
				};

				_blurStrength = ((acctime min 4) - 1) * 0.002;
				bin_fnc_initAcctime_radialblur ppeffectadjust [_blurStrength,_blurStrength,0.1,0.2];
				bin_fnc_initAcctime_radialblur ppeffectcommit 0.4;

				bin_acctime = acctime;
			};
			#endif
		}
	]
];

{
	player removeeventhandler [_x,player getvariable ["bin_fnc_initAcctime_" + _x,-1]];
	player setvariable [
		"bin_fnc_initAcctime_" + _x,
		player addeventhandler [_x,{setacctime 1;}]
	];
} foreach ["fired","hit"];

