_newCont = createVehicle ["CBRNContainer_01_closed_yellow_F", getPosATLVisual container];

deleteVehicle container;
deleteVehicle inner;
deleteVehicle lid;
deleteVehicle ((smokeContainer getVariable "effectEmitter") select 0);

hint "The Gas is disappearing... I should check my Chemical Detector (o key)";

private _ui = uiNamespace getVariable "RscWeaponChemicalDetector";
private _obj = _ui displayCtrl 101;

for [{_i = 0.80},{_i>0.2},{_i=_i-0.01}] do {
	_obj ctrlAnimateModel ["Threat_Level_Source", _i, true]; 
	sleep _i*0.3;
};


"YourLayerName" cutText ["", "PLAIN"]; //IGUI display off