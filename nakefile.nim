import nake, os, strformat, strutils, sequtils, json
const
  app = "nimdustry"

  builds = [
    #musl would be nice
    #--gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc --passL:-static
    (name: "linux64", os: "linux", cpu: "amd64", args: ""),
    (name: "win32", os: "windows", cpu: "i386", args: "--gcc.exe:i686-w64-mingw32-gcc --gcc.linkerexe:i686-w64-mingw32-g++"),
    (name: "win64", os: "windows", cpu: "amd64", args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-g++"),
  ]

task "pack", "Pack textures":
  direshell &"fusepack -p:{getCurrentDir()}/assets-raw/sprites -o:{getCurrentDir()}/assets/atlas"

task "debug", "Debug build":
  runTask("pack")
  shell &"nim r -d:nimTypeNames -d:debug {app}"

task "release", "Release build":
  shell &"nim c -r -d:release -d:danger -o:build/{app} {app}"

task "web", "Deploy web build":
  createDir "build/web"
  shell &"nim c -d:emscripten -d:danger {app}.nim"

task "profile", "Run with a profiler":
  shell nimExe, "c", "-r", "-d:release", "-d:danger", "--profiler:on", "--stacktrace:on", "-o:build/" & app, app

task "deploy", "Build for all platforms":
  for name, os, cpu, args in builds.items:
    let
      exeName = &"{app}-{name}"
      dir = "build"
      exeExt = if os == "windows": ".exe" else: ""
      bin = dir / exeName & exeExt
      #win32 crashes when the release/danger flag is specified
      dangerous = if name == "win32": "" else: "-d:danger"

    createDir dir
    direShell &"nim --cpu:{cpu} --os:{os} --app:gui {args} {dangerous} -o:{bin} c {app}"
    direShell &"strip -s {bin}"
    direShell &"upx-ucl --best {bin}"

  createDir "build/web"
  shell &"nim c -d:emscripten -d:danger {app}.nim"

  cd "build"

  direShell(&"zip -9r {app}-web.zip web/*")
