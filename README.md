# GMLC v2

GMLC compiles and runs GML source at run time inside GameMaker. Branch `v2` is a full overhaul of the library in
progress; `master` keeps v1. v2 starts from v1 commit `de25e48`. Only the `GMLC` IDE folder ships (the release
workflow packages it); the rest of the project is tooling: the test framework (`_Libraries/xUnit`), the test
suites (`Tests`), debug helpers (`print_progress`, `log`) and the web demo.

## Setup

1. Copy `GmlSpec.xml` from your installed runtime into this project's `datafiles/` folder, for example
   `C:/ProgramData/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/GmlSpec.xml` to `datafiles/GmlSpec.xml`.
   The file belongs to YoYo Games, is git-ignored and must never be committed. This step goes away when the JSON
   spec loader replaces the XML loader.
2. Open `GMLC.yyp` in GameMaker, or compile it headlessly:
   `npx --yes @gamemaker/gm-cli@2.4.1 compile --toolchain GMS2@2024.14.4 --errors-only`.
3. The first room in the room order runs: `rmGMLCTestFramework` runs the test framework (the GMLC suites plus the
   suites in `datafiles/__TESTS`, compiled through GMLC); `rmGMLCTestSingle`, `rmGMLCTestGithub` and
   `rmGMLCWebDemo` are the other harnesses.

## Quickstart (current API)

```gml
var env = new GMLC_Env();
var program = env.compile("return 42;");
show_debug_message(program());   // 42

env.compile(@'
function foo() {
    return "bar";
}
');
var foo = env.get("foo");
show_debug_message(foo());       // bar
```

`execute_string(code)` compiles and runs a string without caching; use a `GMLC_Env` for anything that runs more
than once. Exposure tiers (`GMLC_EXPOSURE`) decide which built-in functions compiled code may call; the `expose_*`
methods of `GMLC_Env` add your own functions, constants and assets.

## Known limitations of this branch

- `compile_project` and `__compile_object_asset` find files with gumshoe and `parseAsync` uses the Promise library;
  both are replaced by original code later in the overhaul.
- Test framework run of 2026-10-04 (runtime 2024.14.4): 2,009 passed, 79 failed, 10 expired, 16 skipped, the same
  as v1. 18 of the failures are in the GMLC suites (`DotChainPerformanceTestSuite` 8,
  `BasicCompoundAssignmentAccessorsTestSuite` 8, `BasicConstructorTestSuit` 2): `new` on a constructor inside
  compiled code stops with "static_set argument 1 cannot be an instance", and a bare `undefined` on the right of an
  assignment is read as a variable.
- The built-in table is still read from `GmlSpec.xml` at boot.
- The overhaul replaces the single-pass design with separate lexer, preprocessor, parser, semantic analysis,
  lowering, optimizer and backend stages; until then the code is v1's.
