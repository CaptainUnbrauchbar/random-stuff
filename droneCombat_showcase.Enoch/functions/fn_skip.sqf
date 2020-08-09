//#define TIME_SKIP	1.4 // Apex
#define TIME_SKIP	0.5

params [
	["_skipNow",false,[false]]
];
if (_skipNow) exitwith {
	//playSound ["click", true];

	//--- Interrupt conversation
	bin_player call bis_fnc_kbSkip; //--- Skip the current conversation

	"BIN_cameraBlack" cuttext ["","black out",2];
	2 fadeSpeech 0;

	bin_skipped = true;
	sleep 2;
	waituntil {savingEnabled};

	"BIN_cameraBlack" cuttext ["","black in",2];
	"BIN_skip" cuttext ["","plain"];

	"" call bis_fnc_showSubtitle; //--- Hide subtitles
	1 fademusic 0;
	1 fadesound 1;
	0.5 fadeSpeech 1;

};

//disableserialization;
bin_cameraSkipTimer = 0;
bin_skipped = false;
if (isnil {(finddisplay 46) getvariable "BIN_skipKeyDown"}) then {
	{
		_x setvariable [
			"BIN_skipKeyDown",
			_x displayaddeventhandler [
				"keydown",
				{

					//--- Skipping disabled
					if !(isnil "BIN_disableSkip") exitwith {false};

					//--- Allowed keys
					_key = _this select 1;
					if (_key in (actionkeys "personView" + actionkeys "ingamePause")) exitwith {false};

					//--- Cutscene terminated, remove the handler
					if (bin_cameraSkipTimer < 0 || savingEnabled) exitwith {
							"EXIT" call bis_fnc_log;
						(_this select 0) displayremoveeventhandler ["keydown",(_this select 0) getvariable ["BIN_skipKeyDown",-1]];
						(_this select 0) setvariable ["BIN_skipKeyDown",nil];
						false;
					};

					//--- Show controls hint
					if (bin_cameraSkipTimer == 0) then {
						"BIN_skip" cuttext [ 
							format [ 
								"<t size='1.25'>%2 <t color = '%1'>%3</t> %4</t>", 
								(["GUI", "BCG_RGB"] call BIS_fnc_displayColorGet) call BIS_fnc_colorRGBtoHTML, 
								toupper localize "STR_A3_ApexProtocol_notification_Skip0", 
								toupper localize "STR_A3_ApexProtocol_notification_Skip1", 
								toupper localize "STR_A3_ApexProtocol_notification_Skip2" 
							], 
							"plain down", 
							1, 
							false, 
							true 
						];
					};

					//--- Action key pressed, skip
					if (_key in actionkeys "action") then {

						bin_cameraSkipTimer = (bin_cameraSkipTimer max 0) + 1 / diag_fps;
						if (bin_cameraSkipTimer > TIME_SKIP) then {
							bin_cameraSkipTimer = -1;
							"SKIP" call bis_fnc_log;
							true spawn bin_fnc_skip;
						};
					} else {
						bin_cameraSkipTimer = 0;
					};
					((_this select 1) != 1)
				}
			]
		];
	} foreach [
		finddisplay 46,
		uinamespace getvariable ["RscDisplayOrangeChoice",displaynull]
	];
};