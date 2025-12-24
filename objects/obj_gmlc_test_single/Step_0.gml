/// @description Insert description here
// You can write your code in this editor
env.tokenizer.initialize(@'
a[2] = 10;
show_debug_message(a);

var b;
b[2] = 20;
show_debug_message(b);
');
var t = get_timer();
var tokens = env.tokenizer.parseAll();
show_debug_message($"{(get_timer()-t)/1000}ms");
