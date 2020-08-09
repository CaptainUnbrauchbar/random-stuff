params[""];

_object = bin_drone;

_fsm = _object getVariable ["#bLoop",0];
_fsm setFSMVariable ["terminate",1];

systemChat "restart started";
diag_resetFSM;
waitUntil {completedFSM _fsm};
systemChat "restart completed";

_behaviorLoop = _object execFSM "a3\Functions_F_Contact\Behavior\behaviorLoop.fsm";
_object setVariable ["#bLoop",_behaviorLoop];