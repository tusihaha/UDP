-module(receiver).
-export([start/1, loop/2]).

start(ProcessNum) ->
  create(ProcessNum).

create(0) ->
  io:fwrite("Done!~n");
create(ProcessNum) ->
  Port = 8080 + ProcessNum - 1,
  {ok, Socket} = gen_udp:open(Port, [
    binary,
    inet,
    {active, false},
    {reuseaddr, true}
  ]),
  spawn(receiver, loop, [Socket, 0]),
  create(ProcessNum - 1).

loop(Socket, 0) ->
  {ok, {_, _, _}} = gen_udp:recv(Socket, 0),
  loop(Socket, 1);
loop(Socket, Count) ->
  case gen_udp:recv(Socket, 0, 500) of
    {ok, {_, _, _}} ->
      loop(Socket, Count + 1);
    {error, Reason} ->
      io:fwrite("Error - Count: ~p - ~p~n", [Reason, Count]),
      loop(Socket, 0)
  end.
