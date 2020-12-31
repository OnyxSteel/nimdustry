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

#files are included directly so all of this has to be depended upon right now
requires "https://github.com/treeform/staticglfw#d299a0d1727054749100a901d3b4f4fa92ed72f5"
requires "nimPNG >= 0.3.1"
requires "nimterop >= 0.6.13"
requires "chroma >= 0.2.1"
requires "https://github.com/treeform/flippy#badc4e3772ce93790d5b69e330c7f1fc2d354069"