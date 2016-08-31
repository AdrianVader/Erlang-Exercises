-module(server).
% -export([start/0]).
-compile(export_all).

% En la consola de Windows, para cambiar de disco duro "d:".
% Comando en Windows para iniciar un nodo: erl -sname NomrbeDelNodo.
% Ejemplo de mensaje de un nodo cualquiera a otro: {PIDProceso, NombreNodo}  ! {self(), Mensaje}.
% cd("d:universidad/2Master/PDA/Practicas").



start() -> register(serv, spawn(?MODULE, gameLoop, [[], null])), serv.

gameLoop(Players, CurrentWord) -> 
	receive
		play -> 
			NewWord = createNewWord(),
			io:format("Write: ~p~n", [NewWord]),
			sendMulticastMessage({self(), {word, NewWord}}, Players),
			gameLoop(Players, NewWord);
		players -> 
			io:format("Players: ~p~n", [Players]),
			gameLoop(Players, CurrentWord);
		stop -> 
			sendMulticastMessage(stop, Players),
			exit;
		{Player, join} -> 
			io:format("New player: ~p~n", [Player]),
			Player ! connected,
			gameLoop([Player | Players], CurrentWord);
		{Player, {word, Word}} -> 
			if 
				Word == CurrentWord -> 
					io:format("Gana ~p~n", [Player]),
					sendMulticastMessage({self(), {Player, wins}}, Players),
					serv ! play; % haciendo esto puede que gane mas de uno, por el retardo de proceso entre mensajes del buzon (lo permitiremos como empate).
				true -> 
					Player ! incorrect
			end,
			gameLoop(Players, CurrentWord);
		Any ->
			io:format("No entiendo el mensaje: ~p~n", [Any]),
			gameLoop(Players, CurrentWord)
	end.
	
createNewWord() ->
	PossibleWords = ["hola", "adios"],
	RandomNumber = random:uniform(length(PossibleWords)),
	lists:nth(RandomNumber, PossibleWords).


sendMulticastMessage(_Msg, []) -> 
	ok;
sendMulticastMessage(Msg, [Player | Rest]) -> 
	Player ! Msg,
	sendMulticastMessage(Msg, Rest).
	
	
