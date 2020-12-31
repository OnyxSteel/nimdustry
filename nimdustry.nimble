version       = "0.0.1"
author        = "Anuken"
description   = "Nim version of Mindustry"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["nimdustry"]
binDir        = "build"

#TODO only depend on fuse
requires "nim >= 1.4.2"
requires "https://github.com/rlipsc/polymorph#58b95b623e812e570194ce3ed140308041576321"
requires "fuse"