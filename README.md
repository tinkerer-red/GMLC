# GMLC

GMLC is a GML compiler written in GML. It lets a GameMaker project compile and run GML source at runtime, for mod
support, live scripting and in-game consoles.

This is the `v2` branch, a rewrite of the library that is still in progress. The current release is on `master`.

## Requirements

GameMaker 2024.14 (runtime 2024.14.4.268) or LTS 2026. No other libraries are needed.

## Usage

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

A `GMLC_Env` holds everything compiled code can see. Compile once and call the result as often as needed;
`execute_string` exists for one-off code, but compiles the string again on every call.

- **Access:** the `GMLC_EXPOSURE` tiers limit which built-in functions compiled code may call. The `expose_*` methods
  add your own functions, constants and assets.
- **Multiple files:** `compile_batch` and `compile_project` compile files together, sharing macros, enums and global
  functions.
- **Extensions:** `enableExtension` turns on `let`, `const`, `closure`, `?.` and macro parameters.
- **Errors:** problems are reported as diagnostics with a code (`GMLC0001` and up). Warnings are returned with the
  result; errors stop the compile.

## How it works

Source passes through seven stages, each in its own script: lexer, preprocessor, parser, resolver, lowering,
optimizer and compiler. The compiler turns the final tree into GML functions that run directly.

## Project layout

Only the `GMLC` folder is part of the library. The rest of the project is for development: the test framework
(`_Libraries/xUnit`), the test suites (`Tests`) and a web demo. To run the tests, open `GMLC.yyp` and make
`rmGMLCTestFramework` the first room.

## Known limitations

- Runtime errors in compiled code are thrown as plain GML exceptions and do not yet match GameMaker's error format.
- `GM14Compatibility` is the only third-party script left in the library folder.
