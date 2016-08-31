-module(pract).
-export([impares/1, ack/2, mismoConjunto/2, normal/1, interseccion/2, esta/2, nNodos/1, mapTree/2, sonMultiplos/2, h/1]).



% 1

impares([]) -> [];
impares([X|Xs]) -> [X|impares(eliminaCabeza(Xs))].

eliminaCabeza([]) -> [];
eliminaCabeza([_]) -> [];
eliminaCabeza([_|Xs]) -> Xs.


% 2

ack(M,N) when M =:= 0 -> N+1;
ack(M,N) when M > 0 , N =:= 0 -> ack(M-1, 1);
ack(M,N) when M > 0 , N > 0 -> ack(M-1, ack(M, N-1)).


% 3.1

mismoConjunto([],[]) -> true;
mismoConjunto([X|[]],[Y|[]]) -> X =:= Y;
mismoConjunto(X,Y) -> contenido(X,Y) and contenido(Y,X).

%contenido([],Y) -> true;
%contenido([X|Xs],Y) -> list:member(X,Y) and contenido(Xs,Y).

contenido(X,L) -> lists:all(fun(E) -> lists:member(E,L)end,X).


% 3.2

normal([]) -> [];
normal([X|Xs]) -> case lists:member(X,Xs) of
	true -> normal([X|lists:delete(X,Xs)]);
	false -> [X|normal(Xs)]
	end.

	
% 3.3

interseccion([],_) -> [];
interseccion([X|Xs],Y) -> normal(
	case lists:member(X,Y) of
	true -> [X|interseccion(Xs,Y)];
	false -> interseccion(Xs,Y)
	end
).

% 4.1

esta(_, {}) -> false;
esta(E, {Elem,A1,A2}) -> case E =:= Elem of 
	true -> true;
	false -> esta(E, A1) or esta(E, A2)
	end.
	
% 4.2

nNodos({}) -> 0;
nNodos({_, A1, A2}) -> 1 + nNodos(A1) + nNodos(A2).

% 4.3

%pract:mapTree(fun(X)->X+1end, {1,{2,{3,{},{}},{}},{4,{},{}}}).
mapTree(_,{}) -> {};
mapTree(F,{Elem,A1,A2}) -> {F(Elem),{mapTree(F,A1)},{mapTree(F,A2)}}.

% 5

sonMultiplos(0,_) -> true;
sonMultiplos(_,0) -> true;
sonMultiplos(X,X) -> true;
sonMultiplos(X,Y) -> ((X rem Y) =:= 0) or ((Y rem X) =:= 0).

% 6

h(X) -> fun(Y) -> 0 =:= (X rem Y) end.
