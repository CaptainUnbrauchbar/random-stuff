/*
	Author: Hedrik Offenberg

	Description: Sets EMP parameters to a vehicle. Destroys lights and optionally prevents vehicle from starting

	Parameter(s):
		0: OBJECT - Vehicle that will get destroyed electronics
		1: (Optional): BOOL - Sets engine destroyed - true = engine destroyed, false = engine operating (default: true)
		2: (Optional): BOOL - Handle AI in EMP vehicle - true = AI will exit vehicle and not enter new vehicles, false = AI will remain in vehicle (default: true)

	Note that the player has to be defined as bin_player for the voice lines to be spoken

	Examples:

		[bin_vehicle,true,true] call bin_fnc_empVehicle; //Destroys lights and prevents vehicle from starting, AI will exit vehicle after it has stopped

		[bin_vehicle,false,false] call bin_fnc_empVehicle; //Destroys lights, but engine can still start and vehicle can be driven, AI will remain in vehicle
*/

params 
[	
	["_vehicle",objnull,[objnull]],
	["_noStart",true,[true]],
	["_handleAI",true,[true]]
];
scriptName "EMP Vehicle";

_vehicle setVariable ["bin_aiHandler",_handleAI];

_lightsIndex = [];
{
    if (_x find "#" >= 0) then {_lightsIndex pushBack _foreachIndex};
} foreach ((getAllHitPointsDamage _vehicle) # 0);
{
    if (_x find "light" >= 0) then {_lightsIndex pushBack _foreachIndex};
} foreach ((getAllHitPointsDamage _vehicle) # 0);
{_vehicle setHitIndex [_x,1]} foreach _lightsIndex;

_fuel = fuel _vehicle;

if ((_vehicle isKindOf "Van_02_base_F") || (_vehicle isKindOf "Offroad_01_base_F") || 
	(_vehicle isKindOf "Van_01_base_F") || (_vehicle isKindOf "Tractor_01_base_F") || 
	(_vehicle isKindOf "Truck_02_base_F")) then 
	{
		_vehicle animateSource ["Hide_Dashboard",1,true]
	};

_vehicle removeWeapon (currentWeapon _vehicle);

if (_noStart) then 
{
	_engineHandler = _vehicle addEventHandler 
	[
		"Engine",
		{
			params ["_vehicle","_engineState"];
			if (_engineState) then 
			{
				_fuel = fuel _vehicle;
				_vehicle engineOn false;
				_vehicle setFuel 0;
				
				[_vehicle,_fuel] spawn 
				{
					params ["_vehicle","_fuel"];

					if (!isNull driver _vehicle) then {(driver _vehicle) say3D ["Sfx_Engine_Dead_01",10,1,true]};
					sleep 1.5;
					if (((!isnil "bin_player") && {driver _vehicle == bin_player}) && (!isNull driver _vehicle)) then 
					{
						if (speed _vehicle > 0) then 
						{
							_voiceLine =
							[
								"in_vehicle_broken_emp_var2",
								"in_vehicle_broken_emp_var3"
							];

							[selectRandom _voiceLine,"freeroam1",nil,"DIRECT"] call BIS_fnc_kbTell;
						}

						else 
						{
							_voiceLine =
							[
								"in_vehicle_broken_emp_var1",
								"in_vehicle_broken_emp_var2",
								"in_vehicle_broken_emp_var3"
							];

							[selectRandom _voiceLine,"freeroam1",nil,"DIRECT"] call BIS_fnc_kbTell;
						};
					};

					if ((_vehicle getVariable "bin_aiHandler") && {(!isNull driver _vehicle) && {driver _vehicle != player}}) then 
					{
						waitUntil {speed _vehicle < 5};
						_crew = [];
						{
							unassignVehicle _x;
							_crew pushBack _x;
						} foreach crew _vehicle;
						_crew allowGetIn false;
					};

					waitUntil {isNull driver _vehicle};

					_vehicle setFuel _fuel;
				};
			}
		}
	];
	_vehicle setVariable ["bin_engineHandler",_engineHandler];
};

if ((!_noStart) && (isEngineOn _vehicle)) then 
{
	[_vehicle,_noStart,_fuel] spawn 
	{
		params ["_vehicle","_noStart","_fuel"];
		_vehicle setFuel 0;

		sleep 5;

		_vehicle setFuel _fuel;
	}
};

if ((_noStart) && (isEngineOn _vehicle)) then {_vehicle engineOn false};