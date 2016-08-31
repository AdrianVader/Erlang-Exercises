-module(prac3).
-export([funcion/1, lexico/1, solutions/3, eval/1, amistad/2]).

funcion(X) -> if 
	X =:= 0 -> adios;
	X =:= 1 -> hola;
	true -> nose end.
	
% 1)

lexico([]) -> null;
lexico([L|Ls]) -> lexicoaux(Ls,L).

lexicoaux([], Min) -> Min;
lexicoaux([{NuevoX,NuevoY}|Ls], {MinX,MinY}) -> case (NuevoX < MinX) or ((NuevoX =:= MinX) and (NuevoY < MinY)) of
	true -> lexicoaux(Ls, {NuevoX, NuevoY});
	false -> lexicoaux(Ls, {MinX, MinY}) 
	end.


% 2)

solutions(F, Min, Max) -> solAux(F, [{X,Y} || X <- lists:seq(Min,Max), Y <- lists:seq(Min,Max)]).

solAux(_, []) -> [];
solAux(F, [{X,Y}|Ls]) -> case F(X,Y) =:= 0 of
	true -> [{X,Y}|solAux(F, Ls)];
	false -> solAux(F, Ls) end.
	
	
% 3)

eval({Tipo, X}) -> if
	Tipo =:= int -> X;
	true -> error end;
eval({Op, E1, E2}) ->
	EV1 = eval(E1),
	EV2=  eval(E2),
	if 
	Op =:= suma, EV1 =/= error, EV2 =/= error -> suma(E1,E2);
	Op =:= resta, EV1 =/= error, EV2 =/= error -> resta(E1,E2);
	Op =:= multiplica, EV1 =/= error, EV2 =/= error -> multiplica(E1,E2);
	Op =:= divide, EV1 =/= error, EV2 =/= error -> divide(E1,E2);
	true -> error end.

suma(X,Y) -> X + Y.
resta(X,Y) -> X - Y.
multiplica(X,Y) -> X * Y.
divide(X,Y) -> X / Y.

% 4)

% {edad, genero, aficiones}
% FiltroGenero -> mismo | diferente | indiferente
% Al menos una aficion en comun || los 2 entre la media +-10 || los 2 fuera de la media +-10
% IDEA: Generar lo primero una lista con parejas e ir mirando todas.
% prac3:amistad([{12,hombre,[a,b,c]},{13,mujer,[c,d]},{40,hombre,[c,e]}], indiferente).
% prac3:amistad([{12,hombre,[a,b,c]},{13,mujer,[a,b]},{40,hombre,[c,e]}], indiferente).

amistad(L, FiltroGenero) -> 
	MediaEdad = generaMediaEdad(L), Lparejas = generaParejas(L), Lfiltradas = eliminaPorFiltro(Lparejas, FiltroGenero), restricciones(Lfiltradas, MediaEdad).
	

generaMediaEdad(Ps) -> sumaEdades(Ps)/cuentaEdades(Ps).

sumaEdades([]) -> 0;
sumaEdades([{E,_,_}|Ps]) -> E+sumaEdades(Ps).

cuentaEdades([]) -> 0;
cuentaEdades([_|Ps]) -> 1+cuentaEdades(Ps).

generaParejas([]) -> [];
generaParejas([_|[]]) -> [];
generaParejas([P1,P2|Ps]) -> lists:append([{P1,P2}|generaParejas([P1|Ps])], generaParejas([P2|Ps])).

eliminaPorFiltro([], _) -> [];
eliminaPorFiltro([{{E1,S1,A1},{E2,S2,A2}}|Ps], FiltroGenero) -> if
	S1 =:= S2, FiltroGenero =:= mismo -> [{{E1,S1,A1},{E2,S2,A2}}|eliminaPorFiltro(Ps, FiltroGenero)];
	S1 =/= S2, FiltroGenero =:= diferente -> [{{E1,S1,A1},{E2,S2,A2}}|eliminaPorFiltro(Ps, FiltroGenero)];
	FiltroGenero =:= indiferente -> [{{E1,S1,A1},{E2,S2,A2}}|eliminaPorFiltro(Ps, FiltroGenero)];
	true -> eliminaPorFiltro(Ps, FiltroGenero)
	end.
	
restricciones([], _) -> [];
restricciones([{{E1,S1,A1},{E2,S2,A2}}|Ps], M) -> case 
	(interseccion(A1,A2) =/= [])
	or 
	(((M+10) >= E1) and ((M-10) =< E1)) and (((M+10) >= E2) and ((M-10) =< E2))
	or 
	(((M+10) < E1) or ((M-10) > E1)) and (((M+10) < E2) or ((M-10) > E2))
	of
	true -> [{{E1,S1,A1},{E2,S2,A2}}|restricciones(Ps, M)];
	false -> restricciones(Ps,M)
	end.

interseccion([],_) -> [];
interseccion([A|As], B) -> case lists:member(A,B) of
	true -> [A|interseccion(As,B)];
	false -> interseccion(As,B)
	end.
