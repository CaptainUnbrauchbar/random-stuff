params [
	["_site","",[""]],
	["_layer","",[""]]
];

if (bin_isEditorSite) then {
	getmissionlayerentities _layer
} else {
	missionnamespace getvariable [_site + "_" + _layer,[]]
};