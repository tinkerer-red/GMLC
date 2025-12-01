# 🎮 **GMLC v1.0.0 – Initial Public Release**

## 📘 **Overview**

The first full public release of **GMLC**, a runtime compiler and interpreter that lets GameMaker projects load, compile, and execute real GML code at runtime, enabling **mod support**, **live scripting**, and **scratchpad experimentation** directly inside GameMaker.


## ⚙️ **Core Features**

* **Runtime Compilation:** Parse and evaluate GML source strings during gameplay.  
* **Sandboxed Execution:** Tiered capability profiles (`pure`, `safe`, `moderate`, `unsafe`) for secure script isolation.  
* **Hook System:** Functions defined in a compile can be referenced back in native runtime (`main()`, `create()`, `step()`, etc.).  
* **Environment Support:** Correct handling of `self`, `other`, `global`, and static scopes.  
* **Constructor & Function Parity:** Full support for `static`, `constructor`, and `method` semantics.  
* **AST-Driven Architecture:** Real GML syntax parsing with tokenization and abstract syntax trees.  
* **Error Diagnostics:** Structured compile/runtime error messages with caret and line reporting.  
* **Namespace Management:** Mods and scratchpad sessions can run in isolated namespaces with safe reloads.  


## 🧩 **Setup & Installation**

Importing GMLC into your project works exactly like any other GameMaker library:

1. Download the latest `.yymps` package from the repository or itch.io page.
2. In the GameMaker IDE, select **Tools → Import Local Package**.
3. Choose the `.yymps` file and confirm import.
4. The GMLC scripts will appear under your project’s resource tree and are immediately ready to use.

No special initialization is required after imported, you can begin creating and compiling GML code directly in runtime.

## 🚀 **Quickstart**

GMLC allows you to compile and execute GML source code strings at runtime.
Here’s the most minimal example possible:

```gml
var env = new GMLC_Env();
var program = env.compile("return 42;");
var result = program();        // Executes the compiled code
show_debug_message(result);    // Prints: 42
```

A compiled **program** behaves similarly to a native gm script. It’s callable, but can also contain other callable functions.

For example, fetching a specific function such as `main`, `step`, or `draw` from a compiled program:

```gml
var env = new GMLC_Env();
var program = env.compile(@'
function foo() {
    return "bar";
}
');

var _foo = env.get("foo");
show_debug_message(_foo());    // Prints: bar
```

If the user declares a constant named `global` or uses GameMaker’s built-in `global`, functions can also be accessed directly via `global.foo`.

## ⚠️ **Note on `execute_string()`**

GMLC also includes a legacy style helper named `execute_string(_code)`.
It compiles and runs a code string immediately **without caching or environment reuse**.
This makes it **significantly slower** than using a `GMLC_Env`, but it can be convenient for quick, throwaway tests or debugging.

Example:

```gml
execute_string(@'show_debug_message("quick test");');
```

Use this only for temporary experimentation; for any real runtime scripting, always prefer creating an environment and compiling once.

## 🧠 **Additional Notes**

That’s all you need for a first run, but you may want to:

* Read about **sandbox profiles** `GMLC_EXPOSURE` enum if you plan to expose runtime functions safely.
* Use **hooks** if you want your compiled code to integrate into native events (`create`, `step`, `draw`, etc.).
* Special thanks to Juju Adams for use SNAP's XML parser until a stand alone design is finished.
* Special thanks to TabularElf for the many talks about his GMLSpeak, and improvements and design changes. Much of our work is shared between the projects.

## ❓ **FAQ**

**Q: Can I use GMLC outside of GameMaker?**  
No; GMLC runs entirely inside the GameMaker runtime and is intended for in engine use.

**Q: Is this compatible with both LTS and Monthly builds?**  
_Yes._\* GMLC targets standard GML syntax and should work in both, however I can not ensure that every feature will work as testing the entire runtime on multiple versions is an insermountable task, if you have issues please submit a bug report or feature request.

**Q: Why is `execute_string()` so slow?**  
It does not reuse or cache the compiler environment, it recompiles the string every call.  
Use `GMLC_Env` for anything persistent.

**Q: Can I give my modders access to built-in GameMaker functions?**  
Yes. Use the sandbox capability system (`pure`, `safe`, `moderate`, `unsafe`) to control what functions are exposed.

**Q: Can I expose my own functions?**  
Yes. Yes please see the variety of `expose_*` in `GMLC_Env`.


## 🔀 **Alternatives**

[catspeak-lang](https://github.com/katsaii/catspeak-lang) - Catsaii: An extremely robust modding toolset with long term support.
[gmlspeak](https://github.com/tabularelf/GMLspeak) - TabularElf: An extension to catspeak-lang, which allows for gml like code to be parsed for use inside catspeak
[TXR](https://yellowafterlife.itch.io/gamemaker-txr) - YellowAfterLife: A lightweight and simple expression parser.
[SNAP](https://github.com/JujuAdams/SNAP) - JujuAdams: SNAP contains a module for parsing and executing simple GML.
[RunGML](https://github.com/sdelaughter/RunGML) - sdelaughter: A lisp structured GML executer, very unique!

---

inspiration from neerikiffu: https://discord.com/channels/724320164371497020/724320751624257646/1178721426983882915
