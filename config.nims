--path:"fau"
--hints:off
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

  #extra flags for smaller sizes:
  # -s ASSERTIONS=0 -DNDEBUG -s MALLOC=emmalloc
  #add '--preload-file assets' for sound support later.
  switch("passL", "-o build/web/index.html --shell-file fau/res/shell_minimal.html -O3 -s LLD_REPORT_UNDEFINED -s USE_SDL=2 -s ALLOW_MEMORY_GROWTH=1 --closure 1 --preload-file assets")
else:

  when defined(Windows):
    switch("passL", "-static-libstdc++ -static-libgcc")

  when defined(MacOSX):
    switch("clang.linkerexe", "g++")
  else:
    switch("gcc.linkerexe", "g++")
