-module(musico).

-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3, start/2]).

-record(state, {name, instrument}).

start(N, I) -> gen_server:start_link({local, N}, ?MODULE, {N,I}, []).

init({N, I}) -> 
  process_flag(trap_exit, true),
  io:format("~w inicializado~n", [N]),
  {ok, #state{name = N, instrument = I}}.

handle_call(_, _, State) -> {reply, error, State}.

handle_cast(play, #state{name = N, instrument = I} = State) ->
  case random:uniform(5) of
    1 -> io:format("Oh! ~w se ha equivocado al tocar la ~w~n", [N, I]),
         {stop, {fallo, I}, State};
    _ -> io:format("~w toca la ~w~n", [N, I]),
         {noreply, State}
  end;
handle_cast(stop, State) -> {stop, normal, State}.
  
  
handle_info(Message, State) -> 
  io:format("Mensaje inesperado ~w: ~w~n", [State, Message]),
  {noreply, State}.
  
terminate(Reason, #state{name = N}) ->
  io:format("~w ha finalizado por la razón ~w~n", [N, Reason]).

code_change(PreviousVersion, State, _Extra) ->
  io:format("Cambio de código desde la versión ~w~n", [PreviousVersion]),
  {ok, State}.  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
         
