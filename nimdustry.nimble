version       = "0.0.1"
author        = "Anuken"
description   = "Nim version of Mindustry"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nimdustry"]
binDir        = "build"

requires "nim >= 1.4.2"
requires "https://github.com/rlipsc/polymorph#551eafab0738f61701b09384159d174e88a1a0e7"
requires "https://github.com/Anuken/nake#master"
#depend on submodule
requires "https://github.com/Anuken/fuse#" & staticExec("git -C fuse rev-parse HEAD")