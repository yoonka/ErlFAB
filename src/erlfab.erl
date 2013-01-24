-module(erlfab).

-export([void/0, start/0, start/4]).

%%% Internal exports
-export([benchmark/6]).

void()->
    ok.

start() ->
    %% e.g. start("/path/to/zotonic/modules", 1, 500, 20).
    {ok, Cwd} = file:get_cwd(),
    start(Cwd, 1, 500, 20).

start(StartDir, Descent, Pick, Repeat) ->
    Cwd = StartDir ++ "/",
    io:format("Recursively listing files in: ~s\n", [Cwd]),
    {TopDirs, Files} = get_all(Cwd, Descent, "", [], []),
    io:format("Found ~B top directories and ~B files.\n", [length(TopDirs), length(Files)]),
    Random = pick_files(Pick, length(Files), Files, []),
    BCwd = list_to_binary(Cwd),
    benchmark_is_file(BCwd, TopDirs, Random, Repeat),
    benchmark_last_modified(BCwd, TopDirs, Random, Repeat),
    benchmark_read_file_info(BCwd, TopDirs, Random, Repeat).

benchmark_is_file(Cwd, TopDirs, Files, Repeat) ->
    io:format("\nBenchmarking function filelib:is_regular...\n"),
    Fun = fun(File) -> filelib:is_regular(File) end,
    benchmark(Cwd, TopDirs, Files, Fun, Repeat).

benchmark_last_modified(Cwd, TopDirs, Files, Repeat) ->
    io:format("\nBenchmarking function filelib:last_modified...\n"),
    Fun = fun(File) ->
                  case filelib:last_modified(File) of
                      0 -> false;
                      _ -> true
                  end
          end,
    benchmark(Cwd, TopDirs, Files, Fun, Repeat).

benchmark_read_file_info(Cwd, TopDirs, Files, Repeat) ->
    io:format("\nBenchmarking function file:read_file_info...\n"),
    Fun = fun(File) ->
                  case file:read_file_info(File) of
                      {error, _} -> false;
                      {ok, _} -> true
                  end
          end,
    benchmark(Cwd, TopDirs, Files, Fun, Repeat).

get_all(Cwd, Desc, Base, Tops, Acc) ->
    list_cwd(Cwd, Desc, Base, Tops, Acc, file:list_dir(Cwd)).

get_sub_dir(Cwd, Desc, Base, Tops, Acc, Dir) ->
    get_all(Cwd ++ Dir ++ "/", new_desc(Desc), base_dir(Base, Dir), Tops, Acc).

list_cwd(Cwd, 0, "", Tops, Acc, List) ->
    list_cwd(Cwd, undefined, "", Tops, Acc, List);
list_cwd(Cwd, 0, Base, Tops, Acc, List) ->
    list_cwd(Cwd, undefined, "", [list_to_binary(Base)|Tops], Acc, List);
list_cwd(_Cwd, _Desc, _Base, Tops, Acc, {ok, []}) ->
    {Tops, Acc};
list_cwd(Cwd, undefined, Base, Tops, Acc, {ok, Filenames}) ->
    Files = [X || X <- Filenames, filelib:is_regular(Cwd ++ X)],
    NAcc = [list_to_binary(base_dir(Base, X)) || X <- Files] ++ Acc,
    check_dirs(Cwd, undefined, Base, Tops, NAcc, Filenames);
list_cwd(Cwd, Desc, Base, Tops, Acc, {ok, Filenames}) ->
    check_dirs(Cwd, Desc, Base, Tops, Acc, Filenames).

check_dirs(Cwd, Desc, Base, Tops, Acc, Filenames) ->
    Dirs = [X || X <- Filenames, filelib:is_dir(Cwd ++ X)],
    get_dirs(Cwd, Desc, Base, Tops, Acc, Dirs).

get_dirs(_Cwd, _Desc, _Base, Tops, Acc, []) ->
    {Tops, Acc};
get_dirs(Cwd, Desc, Base, Tops, Acc, [Dir|T]) ->
    {NTops, NAcc} = get_sub_dir(Cwd, Desc, Base, Tops, Acc, Dir),
    get_dirs(Cwd, Desc, Base, NTops, NAcc, T).

base_dir("", Dir) ->
    Dir;
base_dir(Base, Dir) ->
    Base ++ "/" ++ Dir.

new_desc(undefined) ->
    undefined;
new_desc(0) ->
    undefined;
new_desc(Desc) ->
    Desc - 1.

pick_files(0, _Len, _Files, Acc) ->
    Acc;
pick_files(Pick, Len, Files, Acc) ->
    File = lists:nth(random:uniform(Len), Files),
    pick_files(Pick - 1, Len, Files, [File|Acc]).

benchmark(Cwd, Dirs, Files, Fun, Repeat) ->
    Params = [length(Files), length(Dirs), Repeat],
    io:format("Benchmarking access to ~B files in ~B folders repeated ~B times...\n", Params),

    {Hit, Miss, L} = test_loop(Cwd, Dirs, Files, Fun, Repeat, 0, 0, []),
    Length = length(L),
    Min = lists:min(L),
    Max = lists:max(L),
    Med = lists:nth(round((Length / 2)), lists:sort(L)),
    Sum = lists:foldl(fun(X, Sum) -> X + Sum end, 0, L),
    Avg = round(Sum / Length),
    Sec = Sum/1000000,
    MicsPerReq = Sum / (Hit + Miss),
    ReqsPerMs = (Hit + Miss) / (Sum/1000),

    io:format("Finished!\nTimes:\n"),
    io:format(" Range: ~b - ~b mics, Median: ~b mics,", [Min, Max, Med]),
    io:format(" Average: ~b mics\n Total: ~b mics (~.2f secs)\n", [Avg, Sum, Sec]),
    io:format("Access totals:\n Hits: ~b, Misses: ~b\n", [Hit, Miss]),
    io:format("Averages:\n Microseconds per request: ~.2f\n", [MicsPerReq]),
    io:format(" Requests per millisecond: ~.2f\n", [ReqsPerMs]).

test_loop(_Cwd, _Dirs, _Files, _Fun, 0, Hit, Miss, List) ->
    {Hit, Miss, List};
test_loop(Cwd, Dirs, Files, Fun, Repeat, Hit, Miss, List) ->
    {Time, {NHit, NMiss}} = timer:tc(?MODULE, benchmark, [Cwd, Dirs, Files, Fun, Hit, Miss]),
    test_loop(Cwd, Dirs, Files, Fun, Repeat - 1, NHit, NMiss, [Time|List]).

benchmark(Cwd, Dirs, [File|T], Fun, Hit, Miss) ->
    {NHit, NMiss} = benchmark_one(Cwd, Dirs, File, Fun, Hit, Miss),
    benchmark(Cwd, Dirs, T, Fun, NHit, NMiss);
benchmark(_Cwd, _Dirs, [], _Fun, Hit, Miss) ->
    {Hit, Miss}.

benchmark_one(Cwd, [Dir|T], File, Fun, Hit, Miss) ->
    case Fun(<<Cwd/binary, Dir/binary, <<"/">>/binary, File/binary>>) of
        true ->
            {Hit + 1, Miss};
        false ->
            benchmark_one(Cwd, T, File, Fun, Hit, Miss + 1)
    end.
