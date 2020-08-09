#define BLEED_TIME		160
#define BLINK_DELAY_MAX		20
#define BLINK_TIME		0.75

params [
	["_object",objnull,[objnull]]
];

_object removeeventhandler ["dammaged",_object getvariable ["bin_fnc_initRevive_dammaged",-1]];
private _dammaged = _object addeventhandler [
	"dammaged",
	{
		params ["_object","_selection","_damage","_hitIndex","_hitPoint","_shooter","_projectile"];
		if (_hitPoint == "incapacitated" && lifestate _object != "INCAPACITATED") then {
			_object setUnconscious true;
			_object setvariable ["bin_fnc_initGroup_timeHit",time];
			if (isnil "bin_reviveObjects") then {bin_reviveObjects = [];};
			bin_reviveObjects pushback _object;
			_object directsay "SentHealthCritical";

			//--- Soldier moaning while incapacitated
			_index = 0;
			_speaker = speaker _unit;
			_cfg = configfile >> "CfgVehicles" >> typeof _object >> "SoundInjured";
			{
				_array = getarray _x;
				_identities = _array param [0,[]];
				if ({_x == _speaker} count _identities > 0) exitwith {
					_index = _foreachindex;
				};
			} foreach configProperties [_cfg];
			_moans = [];
			_array = getarray (_cfg select _index);
			for "_i" from 1 to 3 do { // 0 - Identity, 1 - Low, 2 - Mid, 3 - Max
				_sounds = _array param [_i,[]];
				if (count _sounds > 0) then {
					_soundData = (selectrandom _sounds) param [0,[]];
					_sound = _soundData param [0,""];
					_volume = 2;
					_pitch = _soundData param [2,""];
					_distance = _soundData param [3,""];
					_moans pushback [_sound + ".wss",_object,false,[0,0,0],_volume,_pitch,_distance * 1.5];
				};
			};

			//--- Heal action
			_actionID = [
				_object,
				localize "STR_A3_Revive",
				"\A3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\u100_ca.paa",
				"\A3\Ui_f\data\IGUI\Cfg\HoldActions\holdAction_revive_ca.paa",
				"lifestate _target == 'INCAPACITATED' && {player distance _target < 1.75}",
				"lifestate _target == 'INCAPACITATED'",
				{
					player playActionnow "medicStart";
				},
				{},
				{
					player playActionnow "medicStop";
					_target setUnconscious false;
				},
				{
					player playActionnow "medicStop";
				},
				[_object],
				6,
				1000
			] call bis_fnc_holdActionAdd;

			//--- Incapacitation loop
			[_object,_moans,_actionID] spawn {
				params ["_object","_moans","_actionID"];
				scriptname format ["BIN_fnc_initRevive: %1 moaning",_object];
				_sound = [];

				//--- Draw icon
				bin_colorIncapacitated = (configfile >> "CfgInGameUI" >> "Bar" >> "colorRed") call bis_fnc_colorConfigToRGBA;
				_draw3d = addmissioneventhandler [
					"draw3d",
					{
						{
							if ((_x getvariable ["bis_fnc_initGroup_draw3d",-1]) == _thisEventhandler && {lifestate _x == "INCAPACITATED"}) then {
								_icons = [
									"\a3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\u100_ca.paa",
									"\a3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\u75_ca.paa",
									"\a3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\u50_ca.paa",
									"\a3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\d50_ca.paa",
									"\a3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\d75_ca.paa",
									"\a3\Ui_f\data\IGUI\Cfg\Revive\overlayIcons\d100_ca.paa"
								];
								_timeBlink = _x getvariable ["bin_fnc_initGroup_timeBlink",0];
								_timeHit = _x getvariable ["bin_fnc_initGroup_timeHit",-1];
								if (time > _timeBlink + BLINK_TIME) then {
									_timeBlink = time + linearconversion [_timeHit,_timeHit + BLEED_TIME * 0.9,time,BLINK_DELAY_MAX,0,true];
									_x setvariable ["bin_fnc_initGroup_timeBlink",_timeBlink];
								};
								_index = linearconversion [-1,+1,cos linearconversion [_timeBlink,_timeBlink + BLINK_TIME,time,0,360,true],5,0,true];
								drawicon3d [
									_icons # _index,
									bin_colorIncapacitated,
									unitAimPositionVisual _x,
									1.3,
									1.3,
									0,
									"",
									2
								];
							};
						} foreach bin_reviveObjects;
					}
				];
				_object setvariable ["bis_fnc_initGroup_draw3d",_draw3d];

				sleep (2 + random 2);
				_timeHit = _object getvariable ["bin_fnc_initGroup_timeHit",time];
				_timeMoan = time + 5;
				while {lifestate _object == "INCAPACITATED" && {time < _timeHit + BLEED_TIME}} do {

					//--- Moan while waiting to be revived
					if (time > _timeMoan) then {
						_sound = +selectrandom (_moans - [_sound]);
						_sound set [3,agltoasl (_object modeltoworld (_object selectionposition "head"))]; //--- Update the position (using object directly makes the sound too faint)
						playsound3d _sound;
						_timeMoan = time + (5 + random 5);
					};
				};

				//--- Clean up
				if (time >= _timeHit + BLEED_TIME) then {

					//--- Kill on timeout
					_object setdamage 1;
				} else {

					//--- Heal when incapacitated state passed
					_object setdamage 0;
				};
				bin_reviveObjects = bin_reviveObjects - [_object];
				[_object,_actionID] call bis_fnc_holdActionRemove;
				removemissioneventhandler ["draw3d",_draw3d];
				_object setvariable ["bis_fnc_initGroup_draw3d",nil];
				_object setvariable ["bin_fnc_initGroup_hitTime",nil];
			};
		};
	}
];
_object setvariable ["bin_fnc_initRevive_dammaged",_dammaged];
true