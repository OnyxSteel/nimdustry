--path:"../"
--hints:off

when not defined(Android):
  --gc:arc

when not defined(debug):
  --passC:"-flto"
  --passL:"-flto"

if defined(emscripten):

  --os:linux
  --cpu:i386
  --cc:clang
  --clang.exe:emcc
  --clang.linkerexe:emcc
  --clang.cpp.exe:emcc
  --clang.cpp.linkerexe:emcc
  --listCmd

  --d:danger

  switch("passL", "-o build/web/index.html --shell-file fuse/res/shell_minimal.html -O3 -s LLD_REPORT_UNDEFINED -s USE_SDL=2 -s ALLOW_MEMORY_GROWTH=1")
else:

  when defined(Windows):
    switch("passL", "-static-libstdc++ -static-libgcc")

  when defined(MacOSX):
    switch("clang.linkerexe", "g++")
  else:
    switch("gcc.linkerexe", "g++")
