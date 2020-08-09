private _ui = uiNamespace getVariable "RscWeaponChemicalDetector";
private _obj = _ui displayCtrl 101;

_obj ctrlAnimateModel ["Threat_Level_Source", 0.85, true]; //Displaying a threat level (value between 0.0 and 1.0)