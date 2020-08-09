//--- Register RSC layers in the correct order (they are not serialized)
{
	_x cuttext ["","plain"];
} foreach [
	"RscCompass",
	"BIS_fnc_cinemaBorder",
	"bin_spectrum", //--- Outro3
	"bin_black", //--- Outro3
	"bin_credits", //--- Outro3
	"BIS_fnc_blackOut", // BIS_fnc_blackOut
	"BIN_fnc_showSimpleNotification",
	"RscCurrentTask",
	"RscAdvancedHint",
	"RscVisionBackground",
	"RscVision",
	"BIS_fnc_playVideo",
	"BIS_skip", 
	"BIS_fnc_showSubtitle",
	"intro" //--- Intro1
];