-module(sender).
-export([start/3, loop/4]).

start(StartPort, ProcessNum, ReceiverNum) ->
  create(StartPort, ProcessNum, ReceiverNum, []).

loop(Socket, Packet, Count, ReceiverNum) ->
  BinCount = integer_to_binary(Count, 10),
  Port = 8080 + Count rem ReceiverNum,
  ok = gen_udp:send(
    Socket,
    {10,61,64,51},
    Port,
    <<Packet/binary, BinCount/binary>>
  ),
  case Count rem 1000 of
    0 -> timer:sleep(10);
    _ -> ok
  end,
  loop(Socket, Packet, Count + 1, ReceiverNum).

create(_, 0, ReceiverNum, SocketList) ->
  Packet = <<"No. ">>,
  send(SocketList, Packet, 1, ReceiverNum);
create(StartPort, ProcessNum, ReceiverNum, SocketList) ->
  {ok, Socket} = gen_udp:open(StartPort, [
    binary,
    inet,
    {active, false},
    {reuseaddr, true}
  ]),
  create(StartPort + 1, ProcessNum - 1, ReceiverNum, [Socket | SocketList]).

send([], _, _, _) ->
  io:fwrite("Done!~n");
send([Socket | Remain], Packet, Count, ReceiverNum) ->
  Pid = spawn(sender, loop, [Socket, Packet, Count, ReceiverNum]),
  {ok, _} = timer:exit_after(1000, Pid, "Time out"),
  send(Remain, Packet, Count, ReceiverNum).
