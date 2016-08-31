-module(pr3).
-compile(export_all).

% cd("../../../universidad/2Master/PDA/Practicas").

% pr3:my_spawn(pr3, mensajes, []).
my_spawn(Mod, Func, Args) -> 
	PidMonitor = spawn(?MODULE, my_monitor, [Mod, Func, Args, self()]),
	receive
		{PidMonitor, Pid} -> Pid
	end,
	Pid.
	
my_spawn_OnExit(Mod, Func, Args) -> 
	PidMonitor = spawn(?MODULE, my_monitor_OnExit, [Mod, Func, Args, self()]),
	receive
		{PidMonitor, Pid} -> Pid
	end,
	Pid.

my_monitor(Mod, Func, Args, Parent) ->
	process_flag(trap_exit, true),
	Pid = spawn_link(Mod, Func, Args),
	Parent ! {self(), Pid},
	Time = os:system_time(),
	receive
		{'EXIT', Pid, Reason} -> io:format("~p: ~p~n",[Reason, os:system_time() - Time])
	end.

my_monitor_OnExit(Mod, Func, Args, Parent) ->
	Pid = spawn(Mod, Func, Args),
	Parent ! {self(), Pid},
	Time = os:system_time(),
	on_exit(Pid, fun(Why) -> io:format("Se ha muerto por: ~p, ha vivido: ~p.~n", [Why, os:system_time() - Time]) end).
	
on_exit(Pid, Fun) ->
	spawn(fun() ->
		Ref = monitor(process, Pid),
		receive
			{'DOWN', Ref, process, Pid, Why} ->
				Fun(Why)
		end
	end).
	
on_kill(Pid, Fun) ->
	spawn(fun() ->
		Ref = monitor(process, Pid),
		receive
			{'DOWN', Ref, process, Pid, killed} ->
				Fun(killed);
			{'DOWN', Ref, process, Pid, normal} ->
				ok
		end
	end).
	
mensajes() ->
	receive
		{_Client, stop} ->
			ok;
		{Client, A} ->
			io:format("~p~n",[A]),
			Client ! {self(), A},
			mensajes()
	end.
	
% Pid = pr3:my_spawn(pr3, mensajes, [], 5000).
my_spawn(Mod, Func, Args, Time) -> 
	PidMonitor = spawn(?MODULE, my_monitor_TimeOut, [Mod, Func, Args, self(), Time]),
	receive
		{PidMonitor, Pid} -> Pid
	end,
	Pid.
	
my_monitor_TimeOut(Mod, Func, Args, Parent, TimeOut) ->
	process_flag(trap_exit, true),
	Pid = spawn_link(Mod, Func, Args),
	Parent ! {self(), Pid},
	Time = os:system_time(),
	receive
		{'EXIT', Pid, Reason} -> io:format("~p: ~p~n",[Reason, os:system_time() - Time])
	after TimeOut ->
		io:format("TimeOut!~n"),
		exit(Pid, kill)
	end.
	
% Name = pr3:spawn_invencible_process(pesado).
spawn_invencible_process(Name) -> 
	my_monitor_InvencibleProcess(?MODULE, im_alive, [], Name),
	Name.

my_monitor_InvencibleProcess(Mod, Func, Args, Name) ->
	register(Name, Pid = spawn(Mod, Func, Args)),
	on_exit(Pid, fun(_Why) -> my_monitor_InvencibleProcess(Mod, Func, Args, Name) end).
	
my_monitor_InvencibleProcess(Func) ->
	Pid = spawn(Func),
	on_kill(Pid, fun(_Why) -> my_monitor_InvencibleProcess(Func) end).
	
im_alive() ->
	receive
	after 5000 -> ok
	end,
	io:format("Estoy vivo~n"),
	im_alive().
	
% pr3:start_and_lookAfter([fun() -> pr3:mensajes() end, fun() -> pr3:mensajes() end]).
start_and_lookAfter([]) -> ok;
start_and_lookAfter([Func|Funcs]) -> 
	my_monitor_InvencibleProcess(Func),
	start_and_lookAfter(Funcs).
	
% pr3:start_NoOneDies([fun() -> pr3:mensajes() end, fun() -> pr3:mensajes() end]).
start_NoOneDies(Funcs) ->
	PidMonitor = spawn(?MODULE, crate_workers, [Funcs]),
	on_kill(PidMonitor, fun(_Why) -> start_NoOneDies(Funcs) end),
	ok.
	
crate_workers([]) ->
	receive
	after infinity -> ok
	end;
crate_workers([Func|Funcs]) ->
	spawn_link(Func),
	crate_workers(Funcs).
