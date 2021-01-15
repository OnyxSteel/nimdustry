version       = "0.0.1"
author        = "Anuken"
description   = "Nim version of Mindustry"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nimdustry"]
binDir        = "build"

requires "nim >= 1.4.2"
requires "https://github.com/rlipsc/polymorph#0241b43d60ae37aea881f4a0a550705741b28dc0"
requires "https://github.com/Anuken/nake#master"
#depend on submodule
requires "https://github.com/Anuken/fau#" & staticExec("git -C fau rev-parse HEAD")