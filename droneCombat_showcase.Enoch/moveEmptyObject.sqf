/**

Arguments
1 - object to move (non player object etc)
2 - starting position (use an invisible helipad)
3 - ending position (use an invisible helipad)
4 - move distance (metres)
5 - timing, i.e. speed 

example : null = [this,posA,posB,1,0.001] execVM "move_object.sqf";

note : will not work with markers or physx enabled objects
**/

private ["_obj","_positionA","_positionB","_step","_timg","_x","_y","_i","_dis","_dir", "_alt"];

_obj = _this select 0;
_positionA = _this select 1;
_positionB = _this select 2;
_step = _this select 3;
_timg = _this select 4;


_startingAltitude = (getPosASL _obj) select 2;

_coordinatesA = getPos _positionA;
//_coordinatesA setPosATL [_coordinatesA select 0, _coordinatesA select 1, _startingAltitude];

_obj setPos _coordinatesA;				//sets the object to the first marker position

_x = ((getPos _positionB select 0)-(getPos _positionA select 0));
_y = ((getPos _positionB select 1)-(getPos _positionA select 1));

//trig
_dir = _x atan2 _y;
if (_dir < 0) then {_dir = _dir+360};		//direction from A to B

//pythagoras
_dis = sqrt(_x^2+_y^2);						//distance from A to B
_dis = _dis / 300;

for [{_i=0},{_i<_dis},{_i=_i+_step}] do {

_x = sin(_dir)*_i;
_y = cos(_dir)*_i;
_obj setPosASL [(getPos _positionA select 0) + _x,(getPos _positionA select 1) + _y, _startingAltitude];
sleep _timg;
};