-module(player).
% -export([start/1]).
-compile(export_all).

% En la consola de Windows, para cambiar de disco duro "d:".
% Comando en Windows para iniciar un nodo: erl -sname NomrbeDelNodo.
% Ejemplo de mensaje de un nodo cualquiera a otro: {PIDProceso, NombreNodo}  ! {self(), Mensaje}.
% cd("d:universidad/2Master/PDA/Practicas").



start(NodeName) -> 
	Pid = spawn_link(?MODULE, recieveMesagesFromServer,[]),
	{serv, NodeName} ! {Pid, join},
	gameLoop(NodeName, Pid).

	
gameLoop(NodeName, Pid) -> 
	W0 = io:get_line("> "),
	% quitamos la "\n" del final
	W1 = string:substr(W0,1,string:len(W0)-1),
	{serv, NodeName} ! {Pid, {word, W1}},
	gameLoop(NodeName, Pid).


recieveMesagesFromServer() -> 
	receive
		connected -> 
			io:format("Connected!~n"),
			recieveMesagesFromServer();
		stop -> 
			exit(self(), kill);
		{_Server, {word, Word}} -> 
			io:format("Write ~p~n", [Word]),
			recieveMesagesFromServer();
		incorrect -> 
			io:format("Incorrect Try again~n"),
			recieveMesagesFromServer();
		{_Server, {Player, wins}} -> 
			if 
				Player == self() -> 
					io:format("Good you win!~n");
				true -> 
					io:format("~p wins!~n",[Player])
			end,
			recieveMesagesFromServer();
		Any -> 
			io:format("I don't understad: ~p~n", [Any]),
			recieveMesagesFromServer()
	end.
	
	
