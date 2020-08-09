if !(isserver || is3DEN) exitwith {};

container addAction ["Close Container", "closeContainer.sqf"];

"YourLayerName" cutRsc ["RscWeaponChemicalDetector", "PLAIN", 1, false]; //IGUI display on

private _ui = uiNamespace getVariable "RscWeaponChemicalDetector";
private _obj = _ui displayCtrl 101;

gate1 setVehicleLock "LOCKED";
gate2 setVehicleLock "LOCKED";

_obj ctrlAnimateModel ["Threat_Level_Source", 0.12, true];



/*boolInCont = false;

sleep 1;
hint format [call bin_fnc_moduleCBRN];
sleep 1;
hint format [[trigCont, ] call bin_fnc_CBRNContaminantAdd];
sleep 1;
hint format [[player] call bin_fnc_CBRNCharacterAdd];
sleep 1;

while {alive player} do {
	boolinCont = [player] call CBRNInContaminant;
	hintSilent format [boolinCont];
	sleep 1;
};