# Game Of Life (crazy) Katas, #1
##  Consul Series: getting to know Consul K/V store

## Description
Inaugurating the Game of Life (crazy) Katas, a GoL implementation using Consul K/V store. The goal
is to get to know the UX of this database, and specially one of its core features: long-polling
subscription to keys.

Featuring: Consul, Curl and Docker.

## Usage
### Start game
```console
$ cat examples/glider.large | ./start.sh
```

### Stop game
(Ctrl-C to exit game)
```console
$ ./stop.sh
```

## Installation
The only system dependency is docker-engine (GTFO if you don't have it installed). The ./start.sh
will take care of the rest.

## Afterthought
* A must feature (even for a real use-case IMHO) that is missing from Consul is the ability to atomically wait for non-existent keys.
* Consul K/V store lacks a nice feature that would be waiting for a whole group of keys to change. Currently it supports waiting in a prefix for any of its subkeys to change, but not all of them. 
* Consul behaves funny sporadically when under stress.
