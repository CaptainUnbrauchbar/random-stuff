//--- Ignored in missions without special description.ext property
if (getnumber (missionconfigfile >> "CfgContact" >> "loadInventory") == 0 && !bin_isEditorSite && !bin_isSitesTest) exitwith {};

//--- Restore persistent inventory
if (
	!(BIN_Inventory isequalto []) //--- Persistent inventory exists
	//&&
	//{!bin_isSitesTest && !bin_isEditorSite} //--- Not when testing in the editor
) then {
	BIN_Inventory params ["_primary","","","_uniform","_vest","_backpack"];

	//--- No weapon, add black MX
	if (_primary isequalto []) then {
		_primary = ["arifle_MX_Black_F","","acc_flashlight","",["30Rnd_65x39_caseless_black_mag",30],[],""];
		BIN_Inventory set [0,_primary];
	};

	//--- Get compatible magazines
	_magazines = [_primary # 0] call bis_fnc_compatibleMagazines;

	//--- Refill ammo in the current magazine
	if ((_primary # 4 # 0) != "") then {(_primary # 4) set [1,1000];};

	//--- Count compatible magazines
	_mags = 0;
	{
		if !(_x isequalto []) then {
			{
				if (count _x == 3) then {
					_x set [2,1000];
					if (tolower (_x # 0) in _magazines) then {["OK",_x] call bis_fnc_log;_mags = _mags + 1;};
				};
			} foreach (_x # 1);
		};
	} foreach [_uniform,_vest,_backpack];

	//--- Apply inventory
	player setUnitLoadout BIN_Inventory;

	//--- Refill ammo in container magazines
	_magDef = _magazines # 0;
	for "_i" from _mags to 3 do {player addmagazine _magDef;};
};

//--- Remove spectrum device components from containers (i.e., uniform, vest and backpack)
{
	player removeitem _x;
} foreach [
	"hgun_esd_01_F",
	"hgun_esd_01_antenna_01_F",
	"hgun_esd_01_antenna_02_F",
	"hgun_esd_01_antenna_03_F",
	"muzzle_antenna_01_f",
	"muzzle_antenna_02_f",
	"muzzle_antenna_03_f",
	"acc_esd_01_flashlight"
];

//--- Add spectrum analyzer in case it's missing
if !(handgunweapon player iskindof ["hgun_esd_01_base_f",configfile >> "Cfgweapons"]) then {
	player addweapon "hgun_esd_01_F";
	player addhandgunitem "acc_esd_01_flashlight";
	player addhandgunitem "muzzle_antenna_01_f";
};


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//--- Obsolete, pistol slot is now fully disabled
if (true) exitwith {};

#define IS_PISTOL(ITEM)			(ITEM iskindof ["pistolcore",configfile >> "Cfgweapons"])
#define IS_ANALYZER_WEAPON(ITEM)	(ITEM iskindof ["hgun_esd_01_base_f",configfile >> "Cfgweapons"])
#define IS_ANALYZER_ANTENNA(ITEM)	(ITEM iskindof ["muzzle_antenna_base_01_f",configfile >> "Cfgweapons"])
#define IS_ANALYZER_FLASHLIGHT(ITEM)	(ITEM iskindof ["acc_esd_01_flashlight",configfile >> "Cfgweapons"])

player removeeventhandler ["put",player getvariable ["bin_fnc_initInventory_put",-1]];
player setvariable [
	"bin_fnc_initInventory_put",
	player addeventhandler [
		"Put",
		{
			params ["_unit","_box","_item"];

			//--- Moving within unit's container, ignore
			if (_box == _unit) exitwith {};

			//--- Dropping the analyzer
			if (IS_ANALYZER_WEAPON(_item)) exitwith {
				player addweapon _item;
				_weaponCargo = weaponcargo _box;
				clearweaponcargo _box;
				{
					if !(IS_ANALYZER_WEAPON(_x)) then {_box addweaponcargo [_x,1];};
				} foreach _weaponCargo;
			};

			//--- Dropping an antenna
			if (IS_ANALYZER_ANTENNA(_item)) exitwith {
				if (IS_ANALYZER_WEAPON(handgunweapon player) && (handgunItems player) # 0 == "") then {player addhandgunitem _item} else {player additem _item;};
				_itemCargo = itemcargo _box;
				clearitemcargo _box;
				{
					if !(IS_ANALYZER_ANTENNA(_x)) then {_box additemcargo [_x,1];};
				} foreach _itemCargo;
			};

			//--- Dropping a flashlight
			if (IS_ANALYZER_FLASHLIGHT(_item)) exitwith {
				if (IS_ANALYZER_WEAPON(handgunweapon player) && (handgunItems player) # 1 == "") then {player addhandgunitem _item} else {player additem _item;};
				_itemCargo = itemcargo _box;
				clearitemcargo _box;
				{
					if !(IS_ANALYZER_FLASHLIGHT(_x)) then {_box additemcargo [_x,1];};
				} foreach _itemCargo;
			};
		}
	]
];

player removeeventhandler ["take",player getvariable ["bin_fnc_initInventory_put",-1]];
player setvariable [
	"bin_fnc_initInventory_take",
	player addeventhandler [
		"Take",
		{
			params ["_unit","_box","_item"];

			//--- Moving within unit's container, ignore
			if (_box == _unit || {_unit distance2d _box == 0}) exitwith {

				//--- Manually changing the antenna, notify about shortcut
				if (_item in ["muzzle_antenna_01_f","muzzle_antenna_02_f"]) then {
					[["ElectronicWarfare","SDAntennas","Hint"],nil,nil,nil,nil,nil,true,true] call bis_fnc_advHint;
				};
			};

			//--- Taking a handgun
			if (IS_PISTOL(_item) && !(IS_ANALYZER_WEAPON(_item))) exitwith {
				player removeweapon _item;
				_weaponCargo = weaponcargo _box;
				clearweaponcargo _box;
				{
					if !(IS_ANALYZER_WEAPON(_x)) then {_box addweaponcargo [_x,1];};
				} foreach _weaponCargo;
				_box addweaponcargo [_item,1];

				player addweapon "hgun_esd_01_F";
				{
					_acc = _x;
					if (items player findif {_x == _acc} < 0) then {player addhandgunitem _x;};
				} foreach ["muzzle_antenna_01_f","muzzle_antenna_02_f","acc_esd_01_flashlight"];
			};
		}
	]
];