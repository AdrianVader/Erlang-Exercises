-module(prac1Server).
-export([iniciar/0, nuevo_trabajo/1, obtener_trabajo/1, trabajo_terminado/2, mostrar_trabajos/0, init/1, handle_call/3, handle_cast/2, code_change/3, handle_info/2, terminate/2]).

-behaviour(gen_server).



% cd("D:/Universidad/2Master/PDA/Practicas").
% c(prac1Server).
% prac1Server:iniciar().
% exit(pid(0,0,0), kill).
% prac1Server:nuevo_trabajo(a).
% {Ref, F} = prac1Server:obtener_trabajo(self()).



% Lista con funciones.
% Lista con funciones que ya han sido asignadas a clientes. Lista de tuplas: {Ref, Pid}.
% 
% Posibles mensajes:
% {nuevo_trabajo, F} <- F es una funcion (lambda abstraccion)
%  Solo aniade una funcion a la lista.
% obtener_trabajo
%  envia al cliente que es el emisor del mensaje {Ref, F}.
% {trabajo_terminado, Ref} <- Ref es una referencia univoca, mirar make_ref
%  Envia al emisor del mensaje uno de los atomos "ok" o "error". Pista: keyfind/3 y keydelete/3 del modulo lists.


iniciar() -> 
	gen_server:start({local, server}, ?MODULE, {[], []}, []). % Iniciamos el servidor generico y lo registramos con el nombre "servidor".



nuevo_trabajo(Funcion) -> 
	gen_server:cast(server, {nuevaFuncion, Funcion}).



obtener_trabajo(Pid) -> 
	{Ref, Funcion} = gen_server:call(server, {obtenerTrabajo, Pid}),
	{Ref, Funcion}.



trabajo_terminado(Ref, Pid) -> 
	gen_server:cast(server, {trabajoTerminado, {Ref, Pid}}).



mostrar_trabajos() ->
	gen_server:cast(server, mostrarTrabajos).



% Esta funcion debe devolver alguno de los siguientes resultados:
% 	{ok, State}
% 	{ok, State, Timeout}
% 	{ok, State, hibernate}
% 	{stop, Reason}
% 	ignore
init(State) -> 
	io:format("init ejecutado con ~p~n", [State]),
	{ok, State}.



% handle_call devuelve:
% 	{reply, Response, NewState}

% Devuelve el trabajo mas antiguo de la lista del servidor.
handle_call({obtenerTrabajo, Pid}, _From, {Lejecutando, Lpendiente}) -> 
	TrabajoViejo = dameUltimoLista(Lpendiente),
	NuevaListaPendiente = lists:sublist(Lpendiente, 1, length(Lpendiente)-1),
	Ref = make_ref(),
	io:format("handle call ha devuelto la ultima funcion aniadida:   ~p y queda ~p ~n", [TrabajoViejo, NuevaListaPendiente]),
	{reply, {Ref, TrabajoViejo}, {[{Ref, Pid} | Lejecutando], NuevaListaPendiente}};

handle_call(_Msg, _From, State) -> 
	{reply, error, State}.



% handle_cast devuelve:
% 	{noreply, NewState}

% Aniade una nueva funcion al servidor de funciones.
handle_cast({nuevaFuncion, Funcion}, {ListaEjecutando, ListaPendiente}) -> 
	io:format("handle cast nueva funcion aniadida:   ~p ~n", [Funcion]),
	{noreply, {ListaEjecutando, [Funcion | ListaPendiente]}};
	
% Elimina de el trabajo pendiente del servidor de funciones la tarea que ha sido terminada por el correspondiente host.
handle_cast({trabajoTerminado, {Ref, Pid}}, {ListaEjecutando, ListaPendiente}) -> 
	{Ref, PidProc} = lists:keyfind(Ref, 1, ListaEjecutando),
	if 
		Pid == PidProc -> 
			Ok = ok;
		true -> 
			Ok = error
	end,
	io:format("handle cast trabajo terminado:   ~p ~n", [{Ok, {Ref, PidProc}}]),
	NuevaLista = lists:keydelete(Ref, 1, ListaEjecutando),
	{noreply, {NuevaLista, ListaPendiente}};

handle_cast(mostrarTrabajos, State) -> 
	io:format("handle cast trabajos registrados:   ~p ~n", [State]),
	{noreply, State};
	
handle_cast(_Request, State) -> 
	io:format("handle cast error ~n"),
	{noreply, State}.



% Funcion para cambiar la version, actualmente se conserva el estado igual.
code_change(_OldVsn, State, _Extra) -> 
	{ok, State}.



% Recoge otros mensajes que no casan con el pattern matching.
handle_info(Msg, State) -> 
	io:format("handle info: unknown ~p   current state: ~p ~n", [Msg, State]), 
	{noreply, State}.



% Funcion que limpia lo necesario, en nuestro caso nada.
terminate(shutdown, _State) -> 
	ok.


% Funcion que devuelve el ultimo elemento de una lista.
dameUltimoLista([]) -> error;
dameUltimoLista([Cabeza | []]) -> Cabeza;
dameUltimoLista([_Cabeza | Lista]) -> dameUltimoLista(Lista).


