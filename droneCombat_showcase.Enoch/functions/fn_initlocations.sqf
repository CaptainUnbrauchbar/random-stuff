{
	if (bin_isFreeRoam || getnumber (_x >> "isFreeRoam") == 0) then {
		_loc = createlocation [gettext (_x >> "type"),getarray (_x >> "position"),getnumber (_x >> "sizeA"),getnumber (_x >> "sizeB")];
		_loc settext gettext (_x >> "text");
	};
} foreach ("true" configclasses (configfile >> "CfgContact" >> "Locations"));