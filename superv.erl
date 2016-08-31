-module(superv).

-behaviour(supervisor).

-export([init/1, start/0]).

start() -> supervisor:start_link(?MODULE, []).

init(_) -> 
  {ok, 
    {{rest_for_one, 2, 1}, 
     [
      {david, {musico, start, [david, trompeta]}, permanent, 5000, worker, [musico]},
      {laura, {musico, start, [laura, bateria]}, permanent, 5000, worker, [musico]},
      {sonia, {musico, start, [sonia, guitarra]}, permanent, 5000, worker, [musico]},
      {alberto, {musico, start, [alberto, flauta]}, permanent, 5000, worker, [musico]}
     ]
    }
  }.
