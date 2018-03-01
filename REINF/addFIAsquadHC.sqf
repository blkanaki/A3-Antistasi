
if (player != Stavros) exitWith {hint "Only Commander Stavros has access to this function"};
//if (!allowPlayerRecruit) exitWith {hint "Server is very loaded. \nWait one minute or change FPS settings in order to fulfill this request"};
if (markerAlpha "respawn_guerrila" == 0) exitWith {hint "You cant recruit a new squad while you are moving your HQ"};
if (!([player] call hasRadio)) exitWith {hint "You need a radio in your inventory to be able to give orders to other squads"};
_chequeo = false;
{
	if (((side _x == muyMalos) or (side _x == malos)) and (_x distance petros < 500) and (not(captive _x))) then {_chequeo = true};
} forEach allUnits;

if (_chequeo) exitWith {Hint "You cannot Recruit Squads with enemies near your HQ"};

private ["_tipogrupo","_esinf","_tipoVeh","_coste","_costeHR","_exit","_formato","_pos","_hr","_resourcesFIA","_grupo","_roads","_road","_grupo","_camion","_vehicle","_mortero","_morty"];


_tipoGrupo = _this select 0;
_exit = false;

if (activeGREF) then
	{
	if (_tipoGrupo isEqualType objNull) then
		{
		if (_tipoGrupo == staticATbuenos) then {hint "AT trucks are disabled in RHS - GREF"; _exit = true};
		};
	};
if (_exit) exitWith {};

_esinf = false;
_tipoVeh = "";
_coste = 0;
_costeHR = 0;
_formato = [];
_format = "";

_hr = server getVariable "hr";
_resourcesFIA = server getVariable "resourcesFIA";

private ["_grupo","_roads","_camion"];

if (_tipoGrupo isEqualType []) then
	{
	//_tipoGrupo = if (random 20 <= skillFIA) then {_tipoGrupo select 1} else {_tipoGrupo select 0};
	//_formato = (cfgSDKInf >> _tipogrupo);
	//_unidades = [_formato] call groupComposition;
	{
	_tipoUnidad = if (random 20 <= skillFIA) then {_x select 1} else {_x select 0};
	_formato pushBack _tipoUnidad;
	_coste = _coste + (server getVariable _tipoUnidad); _costeHR = _costeHR +1
	} forEach _tipoGrupo;

	//if (_costeHR > 4) then {_tipoVeh = "B_G_Van_01_transport_F"} else {_tipoVeh = "B_G_Offroad_01_F"};
	//_coste = _coste + ([_tipoVeh] call vehiclePrice);
	_esinf = true;
	}
else
	{
	_coste = _coste + (2*(server getVariable (SDKMil select 0))) + ([_tipogrupo] call vehiclePrice);
	_costeHR = 2;
	//if (_tipoGrupo == SDKMortar) then {_coste = _coste + ([vehSDKBike] call vehiclePrice)} else {_coste = _coste + ([vehSDKTruck] call vehiclePrice)};
	if ((_tipoGrupo == SDKMortar) or (_tipoGrupo == SDKMGStatic)) then
		{
		_esInf = true;
		_formato = [staticCrewBuenos,staticCrewBuenos];
		}
	else
		{
		_coste = _coste + ([vehSDKTruck] call vehiclePrice)
		};
	};

if (_hr < _costeHR) then {_exit = true;hint format ["You do not have enough HR for this request (%1 required)",_costeHR]};

if (_resourcesFIA < _coste) then {_exit = true;hint format ["You do not have enough money for this request (%1 € required)",_coste]};

if (_exit) exitWith {};

_nul = [- _costeHR, - _coste] remoteExec ["resourcesFIA",2];

_pos = getMarkerPos "respawn_guerrila";

/*
while {true} do
	{
	_roads = _pos nearRoads _tam;
	if (count _roads > 0) exitWith {};
	_tam = _tam + 10;
	};
_road = _roads select 0;
*/
_roads = [];
_tam = 10;
_road = objNull;
while {isNull _road} do
	{
	_roads = _pos nearRoads _tam;
	if (count _roads > 0) then
		{
		{
		if ((surfaceType (position _x)!= "#GdtForest") and (surfaceType (position _x)!= "#GdtRock") and (surfaceType (position _x)!= "#GdtGrassTall")) exitWith {_road = _x};
		} forEach _roads;
		};
	_tam = _tam + 50;
	};
if (_esinf) then
	{
	_pos = [(getMarkerPos "respawn_guerrila"), 30, random 360] call BIS_Fnc_relPos;
	if (_tipoGrupo isEqualType []) then
		{
		_grupo = [_pos, buenos, _formato,true] call spawnGroup;
		if (_tipogrupo isEqualTo gruposSDKSquad) then {_format = "Squd-"};
		if (_tipogrupo isEqualTo gruposSDKmid) then {_format = "Tm-"};
		if (_tipogrupo isEqualTo gruposSDKAT) then {_format = "AT-"};
		if (_tipogrupo isEqualTo gruposSDKSniper) then {_format = "Snpr-"};
		if (_tipogrupo isEqualTo gruposSDKSentry) then {_format = "Stry-"};
		}
	else
		{
		_grupo = [_pos, buenos, _formato,true] call spawnGroup;
		_grupo setVariable ["staticAutoT",false,true];
		if (_tipogrupo == SDKMortar) then {_format = "Mort-"};
		if (_tipoGrupo == SDKMGStatic) then {_format = "MG-"};
		[_grupo,_tipoGrupo] spawn MortyAI;
		};
	_format = format ["%1%2",_format,{side (leader _x) == buenos} count allGroups];
	_grupo setGroupId [_format];
	}
else
	{
	_pos = position _road findEmptyPosition [1,30,vehSDKTruck];
	_vehicle = if ((_tipoGrupo ==staticAABuenos) and (activeGREF)) then {[_pos, 0,"rhsgref_ins_g_ural_Zu23", buenos] call bis_fnc_spawnvehicle} else {[_pos, 0,vehSDKTruck, buenos] call bis_fnc_spawnvehicle};
	_camion = _vehicle select 0;
	_grupo = _vehicle select 2;
	//_mortero attachTo [_camion,[0,-1.5,0.2]];
	//_mortero setDir (getDir _camion + 180);

	if ((!activeGREF) or (_tipogrupo == staticATBuenos)) then
		{
		_pos = _pos findEmptyPosition [1,30,SDKMortar];
		_morty = _grupo createUnit [staticCrewBuenos, _pos, [],0, "NONE"];
		_mortero = _tipogrupo createVehicle _pos;
		_nul = [_mortero] call AIVEHinit;
		_mortero attachTo [_camion,[0,-1.5,0.2]];
		_mortero setDir (getDir _camion + 180);
		_morty moveInGunner _mortero;
		};
	if (_tipogrupo == staticATBuenos) then {_grupo setGroupId [format ["M.AT-%1",{side (leader _x) == buenos} count allGroups]]};
	if (_tipogrupo == staticAABuenos) then {_grupo setGroupId [format ["M.AA-%1",{side (leader _x) == buenos} count allGroups]]};

	driver _camion action ["engineOn", vehicle driver _camion];
	_nul = [_camion] call AIVEHinit;
	};

{[_x] call FIAinit} forEach units _grupo;
//leader _grupo setBehaviour "SAFE";
Stavros hcSetGroup [_grupo];
petros directSay "SentGenReinforcementsArrived";
hint format ["Group %1 at your command.\n\nGroups are managed from the High Command bar (Default: CTRL+SPACE)\n\nIf the group gets stuck, use the AI Control feature to make them start moving. Mounted Static teams tend to get stuck (solving this is WiP)\n\nTo assign a vehicle for this group, look at some vehicle, and use Vehicle Squad Mngmt option in Y menu", groupID _grupo];

if (!_esinf) exitWith {};

if (count _formato == 2) then
	{
	_tipoVeh = vehSDKBike;
	}
else
	{
	if (count _formato > 4) then
		{
		_tipoVeh = vehSDKTruck;
		}
	else
		{
		_tipoVeh = vehSDKLightUnarmed;
		};
	};

_coste = [_tipoVeh] call vehiclePrice;
private ["_display","_childControl"];
if (_coste > server getVariable "resourcesFIA") exitWith {};

_nul = createDialog "veh_query";

sleep 1;
disableSerialization;

_display = findDisplay 100;

if (str (_display) != "no display") then
	{
	_ChildControl = _display displayCtrl 104;
	_ChildControl  ctrlSetTooltip format ["Buy a vehicle for this squad for %1 €",_coste];
	_ChildControl = _display displayCtrl 105;
	_ChildControl  ctrlSetTooltip "Barefoot Infantry";
	};

waitUntil {(!dialog) or (!isNil "vehQuery")};

if ((!dialog) and (isNil "vehQuery")) exitWith {};

//if (!vehQuery) exitWith {vehQuery = nil};

vehQuery = nil;
//_resourcesFIA = server getVariable "resourcesFIA";
//if (_resourcesFIA < _coste) exitWith {hint format ["You do not have enough money for this vehicle: %1 € required",_coste]};
_pos = position _road findEmptyPosition [1,30,"B_G_Van_01_transport_F"];
_mortero = _tipoVeh createVehicle _pos;
_nul = [_mortero] call AIVEHinit;
_grupo addVehicle _mortero;
_mortero setVariable ["owner",_grupo,true];
_nul = [0, - _coste] remoteExec ["resourcesFIA",2];
leader _grupo assignAsDriver _mortero;
{[_x] orderGetIn true; [_x] allowGetIn true} forEach units _grupo;
hint "Vehicle Purchased";
petros directSay "SentGenBaseUnlockVehicle";
