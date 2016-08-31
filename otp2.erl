%% coding: latin-1
-module(otp2).

-behaviour(supervisor).

% -compile(export_all).
-export([init/1]).

% cd("../../../universidad/2Master/PDA/Practicas").
% cd("d:/universidad/2Master/PDA/Practicas").
% c(otp2).
% {ok,PidSup} = supervisor:start_link(superv, ok).
% gen_server:cast(adrian, play).



init(NumberOfLevels) ->

	Options = {one_for_one, 1000, 1}, % Solo se reinicia el trabajador que falla, y se permite un máximo de 1000 reinicios por segundo.

	Child = {adrian, {musico, start, [adrian, bandurria]}, transient, 1, worker, [dynamic]} % transient indica que solo se reiniciará si muere por causas anormales. El valor 1 equivale a ls milisegundos que se espera tras la señal shutdown para matarlo
	Children = [Child],
	
	{
		ok,
		{
			Options,
			Children
		}
	}.








%init(_) -> % NumberOfLeaves, GenServerMFA
%
%	Options = {one_for_one, 1000, 1}, % Solo se reinicia el trabajador que falla, y se permite un máximo de 1000 reinicios por segundo.
%
%	Children = [{adrian, {musico, start, [adrian, bandurria]}, transient, 1, worker, [dynamic]}], % transient indica que solo se reiniciará si muere por causas anormales. El valor 1 equivale a ls milisegundos que se espera tras la señal shutdown para matarlo
%	
%	{
%		ok,
%		{
%			Options,
%			Children
%		}
%	}.
