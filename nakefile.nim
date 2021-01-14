import nake, os, strformat, strutils, sequtils, tables
const
  app = "nimdustry"

  builds = [
    #linux builds don't work due to glibc issues. musl doesn't work because of x11 headers, and the glibc hack doesn't work due to depedencies on other C(++) libs
    #workaround: wrap all functions and use asm symver magic to make it work
    #(name: "linux64", os: "linux", cpu: "amd64", args: ""),
    (name: "win32", os: "windows", cpu: "i386", args: "--gcc.exe:i686-w64-mingw32-gcc --gcc.linkerexe:i686-w64-mingw32-g++"),
    (name: "win64", os: "windows", cpu: "amd64", args: "--gcc.exe:x86_64-w64-mingw32-gcc --gcc.linkerexe:x86_64-w64-mingw32-g++"),
  ]

task "pack", "Pack textures":
  direshell &"fusepack -p:{getCurrentDir()}/assets-raw/sprites -o:{getCurrentDir()}/assets/atlas"

task "debug", "Debug build":
  shell &"nim r -d:debug src/{app}"

task "release", "Release build":
  direshell &"nim r -d:release -d:danger -d:noFont -o:build/{app} src/{app}"

task "web", "Deploy web build":
  createDir "build/web"
  direshell &"nim c -f -d:emscripten -d:danger src/{app}.nim"
  writeFile("build/web/index.html", readFile("build/web/index.html").replace("$title$", capitalizeAscii(app)))

task "profile", "Run with a profiler":
  shell nimExe, "c", "-r", "-d:release", "-d:danger", "--profiler:on", "--stacktrace:on", "-o:build/" & app, app

task "deploy", "Build for all platforms":
  runTask("web")

  for name, os, cpu, args in builds.items:
    let
      exeName = &"{app}-{name}"
      dir = "build"
      exeExt = if os == "windows": ".exe" else: ""
      bin = dir / exeName & exeExt
      #win32 crashes when the release/danger/optSize flag is specified
      dangerous = if name == "win32": "" else: "-d:danger"

    createDir dir
    direShell &"nim --cpu:{cpu} --os:{os} --app:gui -f {args} {dangerous} -o:{bin} c src/{app}"
    direShell &"strip -s {bin}"
    direShell &"upx-ucl --best {bin}"

  cd "build"

  direShell(&"zip -9r {app}-web.zip web/*")
