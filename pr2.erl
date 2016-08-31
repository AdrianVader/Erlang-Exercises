-module(pr2).
%-export([startClock/2, stopClock/0, qsort/1, startRing/3, startStar/3]).
-compile(export_all).

% cd("c:/hlocal/Erlang").
% cd("D:/Universidad/2Master/PDA/Practicas").
% c(pr2).



% pr2:startClock(1000, fun() -> io:format("reloj~n") end).
startClock(Time, Fun) ->
	case whereis(clock) == undefined of
		true -> register(clock, spawn(fun() -> tick(Time, Fun) end)), ok;
		false -> error
	end.
	
stopClock() -> clock ! stop.

tick(Time, Fun) ->
	receive
	stop ->
		void
	after Time ->
		Fun(),
		tick(Time, Fun)
	end.
	
	
	
% pr2:qsort([3,4,5,1,2,7,8,9]).
qsort(List) -> 
	qsort(self(), ok, List),
	receive
		{_Child, ok, Ordenado} -> ok
	end,
	Ordenado.

qsort(Parent, Flag, []) -> Parent ! {self(), Flag, []};
qsort(Parent, Flag, [X|Xs]) ->
	Me = self(),
	spawn(fun() -> qsort(Me, menor, [U || U <- Xs, U =< X]) end),
	spawn(fun() -> qsort(Me, mayor, [U || U <- Xs, U > X]) end),
	receive
		{_ChildMenor, menor, ListMenor} -> ok
	end,
	receive
		{_ChildMayor, mayor, ListMayor} -> ok
	end,
	Parent ! {self(), Flag, ListMenor ++ [X] ++	ListMayor}.
	
	
	
% pr2:startRing(3, 3, "Hola").
startRing(NumProcs, Loops, Msg) ->
	Me = self(),
	Partner = spawn(fun() -> createMessagePorcess(Me, NumProcs-1, Loops) end),
	Partner ! Msg,
	waitForMessagesAndSend(Loops-1, Partner).
	
createMessagePorcess(Root, 0, Loops) ->
	Partner = Root,
	waitForMessagesAndSend(Loops, Partner);
createMessagePorcess(Root, NumProcs, Loops) ->
	Partner = spawn(fun() -> createMessagePorcess(Root, NumProcs-1, Loops) end),
	waitForMessagesAndSend(Loops, Partner).

waitForMessagesAndSend(0, _Target) ->
	done;
waitForMessagesAndSend(Count, Target) ->
	receive
		Msg ->
			Target ! Msg,
			waitForMessagesAndSend(Count-1,Target)
	end.



% pr2:startStar(3, 3, "Hola").
startStar(NumProcs, Loops, Msg) ->
	ProcessList = createNProcess(NumProcs, starNode(Loops), []).%,
	%ProcessCounter = [Loops-1 || _X <- lists:seq(1, length(ProcessList))],
	%loopSnd(ProcessList, Msg),
	%loopRcv(ProcessList, ProcessCounter).

% ProcessList = pr2:createNProcess(3, fun() -> io:format("Asdf~n") end, []).
% ProcessList = pr2:createNProcess(3, fun() -> receive {Server, Msg} -> Server ! {self(), Msg} end, []).
% ProcessList = pr2:createNProcess(3, pr2:starNode(3), []). 
createNProcess(0, _Fun, ProcessList) ->
	ProcessList;
createNProcess(N, Fun, ProcessList) ->
	NewProcessList = ProcessList ++ [spawn(Fun)],
	createNProcess(N-1, Fun, NewProcessList).

starNode(0) -> done;
starNode(N) -> 
	receive
		{Server, Msg} ->
			Server ! {self(), Msg}
	end,
	starNode(N-1).

loopSnd([], _Msg) -> done;
loopSnd([Head|RestProcessList], Msg) ->
	Head ! {self(), Msg},
	loopSnd(RestProcessList, Msg).
	
loopRcv(_, []) -> done;
loopRcv(ProcessList, ProcessCounter) -> 
	receive
		{Client, Msg} ->
			case (Number = lists:nth(Index = indexOf(Client, ProcessList, 1), ProcessCounter)) > 0 of
				true -> 
					Client ! {self(), Msg},
					NewProcessCounter = lists:sublist(ProcessCounter,Index) ++ [Number-1] ++ lists:nthtail(Index,ProcessCounter),
					NewProcessList = ProcessList;
				false ->
					{HeadC, [_|TailC]} = lists:split(Index-1, ProcessCounter),
					NewProcessCounter = HeadC ++ TailC,
					{HeadL, [_|TailL]} = lists:split(Index-1, ProcessList),
					NewProcessList = HeadL ++ TailL
			end
	end,
	loopRcv(NewProcessList, NewProcessCounter).
	
indexOf(_, [], _)  -> -1;
indexOf(Item, [Item|_], Index) -> Index;
indexOf(Item, [_|Ls], Index) -> indexOf(Item, Ls, Index+1).