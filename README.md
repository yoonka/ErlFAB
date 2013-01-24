ErlFAB
======

Erlang File Access Benchmark

This is a simple benchmark to test file access time of Erlang functions. It was written to test access time to files within Zotonic modules, so the examples refer to Zotonic sources, but the code itself is generic and can be used with any directory structure.

To start the benchmark call `erlfab:start/0` or `erlfab:start/4`. Function `start/0` invokes `start/4` with default parameters (see https://github.com/yoonka/ErlFAB/blob/master/src/erlfab.erl). There are three Makefile targets to help with executing the test:

* `compile:` just compile
* `shell:` start Erlang shell with binary path pointing to ebin
* `all:` compile and execute with default parameters

For example, to execute benchmark in interactive mode:

    gmake shell
    1>file:set_cwd("/local/path/to/zotonic/modules").
    ok
    2>erlfab:start().

The procedure:
----------

#### 1. Starting in `StartDir` folder descent `Descent` amount of sub-folders collecting so called top folders.

For example, assume the following directory structure:

    DirA/SubDirA/File1
    DirA/SubDirB/File2
    DirB/SubDirC/SubDirD/File3

* If `Descent` is 1 top folders are `DirA` and `DirB`.
* If `Descent` is 2 top folders are `DirA/SubdirA`, `DirA/SubDirB`, and `DirB/SubDirC`.
* If `Descent` is 3 there is just one top folder `DirB/SubDirC/SubDirD`.

Files in sub-folders while the procedure is descending are ignored.

#### 2. After descending the specified amount of sub-folders recursively create a list of all files in all subfolders.

For example if `Descent` is 1 the procedure will collect files: `SubDirA/File1`, `SubDirB/File2`, and `SubDirC/SubDirD/File3`.

#### 3. Randomly select `Pick` amount of files from the created list.

#### 4. For each file try to access that file relatively to each top folder until it has been found.

For example if `SubDirC/SubDirD/File3` has been selected the procedure will try to access the file relatively to:

    DirA/SubDirC/SubDirD/File3 -> miss
    DirB/SubDirC/SubDirD/File3 -> hit

#### 5. For each file count hits and misses and measure the execution time, then repeat the procedure `Repeat` times.

#### 6. Once benchmark of a particular Erlang function has been repeated the desired amount of times calculate and print summary, then perform the same benchmark for another Erlang function.

Benchmark example:
----------
(running FreeBSD in a VirtualBox VM on Intel Core i7 and SSD hard disk)

    Recursively listing files in: /some/path/to/zotonic/modules/
    Found 44 top directories and 2581 files.

    Benchmarking function filelib:is_regular...
    Benchmarking access to 500 files in 44 folders repeated 20 times...
    Finished!
    Times:
     Range: 264554 - 314428 mics, Median: 273025 mics, Average: 275148 mics
     Total: 5502966 mics (5.50 secs)
    Access totals:
     Hits: 10000, Misses: 239360
    Averages:
     Microseconds per request: 22.07
     Requests per millisecond: 45.31

    Benchmarking function filelib:last_modified...
    Benchmarking access to 500 files in 44 folders repeated 20 times...
    Finished!
    Times:
     Range: 268175 - 322419 mics, Median: 280864 mics, Average: 282448 mics
     Total: 5648953 mics (5.65 secs)
    Access totals:
     Hits: 10000, Misses: 239360
    Averages:
     Microseconds per request: 22.65
     Requests per millisecond: 44.14

    Benchmarking function file:read_file_info...
    Benchmarking access to 500 files in 44 folders repeated 20 times...
    Finished!
    Times:
     Range: 270679 - 292621 mics, Median: 272959 mics, Average: 274926 mics
     Total: 5498520 mics (5.50 secs)
    Access totals:
     Hits: 10000, Misses: 239360
    Averages:
     Microseconds per request: 22.05
     Requests per millisecond: 45.35
    ok
