import tables, math, random, common, sequtils, world, worldmesh

#pack sprites on launch
static: echo staticExec("faupack -p:../assets-raw/sprites -o:../assets/atlas")

#include core modules for ECS construction
include logic
include rendering

launchFau("Nimdustry")
