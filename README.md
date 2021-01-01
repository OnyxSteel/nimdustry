# Nimdustry

A Nim version of Mindustry. Not intended to be a complete game. Partially made as a learning experience.

[The Webassembly version can be seen here.](https://anuken.github.io/nimdustry/) Don't expect anything playable yet.

## Objectives

- Experiment with ECS design, multithreading and various optimization techniques
- Try to have a cleaner codebase than Mindustry *(which isn't saying much)*
- Reimplement many mechanics, simplify others
- Create a more deterministic transportation system
- Experiment with RTS mechanics, like direct unit control and true fog of war
- Learn more about Nim and lower-level programming
- Return to pixel art, simplify the drawing process
- See if it's feasible to avoid all text and UI *(both as a challenge and for technical reasons)*

# Compiling

1. Install Nim.
2. `nimble build`
3. `nake debug`

Builds are only tested on Linux. Windows is unlikely to work at this time.
