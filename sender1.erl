-module(sender1).
-export([start/4, loop/5]).

start(StartPort, ProcessNum, ReceiverNum, PacketNum) ->
  create(StartPort, ProcessNum, ReceiverNum, [], PacketNum).

loop(_, _, 0, _, StartTime) ->
  EndTime = erlang:timestamp(),
  io:fwrite("NowDiff: ~p~n", [timer:now_diff(EndTime, StartTime)]);
loop(Socket, Packet, Count, ReceiverNum, StartTime) ->
  BinCount = integer_to_binary(Count, 10),
  Port = 8080 + Count rem ReceiverNum,
  ok = gen_udp:send(
    Socket,
    {127,0,0,1},
    Port,
    <<Packet/binary, BinCount/binary>>
  ),
  loop(Socket, Packet, Count - 1, ReceiverNum, StartTime).

create(_, 0, ReceiverNum, SocketList, PacketNum) ->
  Packet = <<"No. ">>,
  send(SocketList, Packet, PacketNum, ReceiverNum);
create(StartPort, ProcessNum, ReceiverNum, SocketList, PacketNum) ->
  {ok, Socket} = gen_udp:open(StartPort, [
    binary,
    inet,
    {active, false},
    {reuseaddr, true}
  ]),
  create(StartPort + 1, ProcessNum - 1, ReceiverNum, [Socket | SocketList], PacketNum).

send([], _, _, _) ->
  io:fwrite("Done!~n");
send([Socket | Remain], Packet, Count, ReceiverNum) ->
  {ok, [{sndbuf, S}, {recbuf, R}]} = inet:getopts(Socket, [sndbuf, recbuf]),
  inet:setopts(Socket, [{buffer, max(S, R)}]),
  T1 = erlang:timestamp(),
  _Pid = spawn(?MODULE, loop, [Socket, Packet, Count, ReceiverNum, T1]),
  send(Remain, Packet, Count, ReceiverNum).
