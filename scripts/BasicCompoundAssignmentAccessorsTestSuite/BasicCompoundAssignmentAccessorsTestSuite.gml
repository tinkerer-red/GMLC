function BasicCompoundAssignmentAccessorsTestSuite() : TestSuite() constructor {
	#region Compound Assignment +=

	addFact("foo += 5", function() {
		compile_and_execute(@'
		var foo = 10;
		foo += 5;
		assert_equals(foo, 15, "foo += 5 failed.");
		')
	});

	addFact("foo.bar += 5", function() {
		compile_and_execute(@'
		var foo = { bar: 10 };
		foo.bar += 5;
		assert_equals(foo.bar, 15, "foo.bar += 5 failed.");
		')
	});

	addFact("foo[$ \"bar\"] += 5", function() {
		compile_and_execute(@'
		var foo = { "bar": 10 };
		foo[$ "bar"] += 5;
		assert_equals(foo[$ "bar"], 15, "foo[$ \"bar\"] += 5 failed.");
		')
	});

	addFact("foo[? \"bar\"] += 5", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 0;
		foo[? "bar"] += 5;
		assert_equals(foo[? "bar"], 5, "foo[? \"bar\"] += 5 failed.");
		')
	});

	addFact("foo[0] += 5", function() {
		compile_and_execute(@'
		var foo = array_create(1, 10);
		foo[0] += 5;
		assert_equals(foo[0], 15, "foo[0] += 5 failed.");
		')
	});

	addFact("foo[@ 0] += 5", function() {
		compile_and_execute(@'
		var foo = array_create(1, 10);
		foo[@ 0] += 5;
		assert_equals(foo[@ 0], 15, "foo[@ 0] += 5 failed.");
		')
	});

	addFact("foo[| 0] += 5", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 10;
		foo[| 0] += 5;
		assert_equals(foo[| 0], 15, "foo[| 0] += 5 failed.");
		')
	});

	addFact("foo[# 0, 0] += 5", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 10;
		foo[# 0, 0] += 5;
		assert_equals(foo[# 0, 0], 15, "foo[# 0, 0] += 5 failed.");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment -=

	addFact("Compound -= with direct variable", function() {
		compile_and_execute(@'
		var foo = 10;
		foo -= 3;
		assert_equals(foo, 7, "Direct variable -= failed");
		')
	});

	addFact("Compound -= with struct dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: 10 };
		foo.bar -= 3;
		assert_equals(foo.bar, 7, "Dot accessor -= failed");
		')
	});

	addFact("Compound -= with struct bracket accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": 10 };
		foo[$ "bar"] -= 3;
		assert_equals(foo[$ "bar"], 7, "Map accessor -= failed");
		')
	});

	addFact("Compound -= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 10;
		foo[? "bar"] -= 3;
		assert_equals(foo[? "bar"], 7, "Map accessor -= failed");
		')
	});

	addFact("Compound -= with array index", function() {
		compile_and_execute(@'
		var foo = [10];
		foo[0] -= 3;
		assert_equals(foo[0], 7, "Array index -= failed");
		')
	});

	addFact("Compound -= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [10];
		foo[@ 0] -= 3;
		assert_equals(foo[0], 7, "Typed array (@) accessor -= failed");
		')
	});

	addFact("Compound -= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 10;
		foo[| 0] -= 3;
		assert_equals(foo[| 0], 7, "List accessor (|) -= failed");
		')
	});

	addFact("Compound -= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 10;
		foo[# 0, 0] -= 3;
		assert_equals(foo[# 0, 0], 7, "Grid accessor -= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment *=

	addFact("Compound *= with direct variable", function() {
		compile_and_execute(@'
		var foo = 4;
		foo *= 2;
		assert_equals(foo, 8, "Direct variable *= failed");
		')
	});

	addFact("Compound *= with dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: 4 };
		foo.bar *= 2;
		assert_equals(foo.bar, 8, "Dot accessor *= failed");
		')
	});

	addFact("Compound *= with struct accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": 4 };
		foo[$ "bar"] *= 2;
		assert_equals(foo[$ "bar"], 8, "Map accessor *= failed");
		')
	});

	addFact("Compound *= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 4;
		foo[? "bar"] *= 2;
		assert_equals(foo[? "bar"], 8, "Map accessor *= failed");
		')
	});

	addFact("Compound *= with array index", function() {
		compile_and_execute(@'
		var foo = [4];
		foo[0] *= 2;
		assert_equals(foo[0], 8, "Array index *= failed");
		')
	});

	addFact("Compound *= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [4];
		foo[@ 0] *= 2;
		assert_equals(foo[0], 8, "Typed array (@) accessor *= failed");
		')
	});

	addFact("Compound *= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 4;
		foo[| 0] *= 2;
		assert_equals(foo[| 0], 8, "List accessor (|) *= failed");
		')
	});

	addFact("Compound *= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 4;
		foo[# 0, 0] *= 2;
		assert_equals(foo[# 0, 0], 8, "Grid accessor *= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment /=

	addFact("Compound /= with direct variable", function() {
		compile_and_execute(@'
		var foo = 8;
		foo /= 2;
		assert_equals(foo, 4, "Direct variable /= failed");
		')
	});

	addFact("Compound /= with dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: 8 };
		foo.bar /= 2;
		assert_equals(foo.bar, 4, "Dot accessor /= failed");
		')
	});

	addFact("Compound /= with struct accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": 8 };
		foo[$ "bar"] /= 2;
		assert_equals(foo[$ "bar"], 4, "Map accessor /= failed");
		')
	});

	addFact("Compound /= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 8;
		foo[? "bar"] /= 2;
		assert_equals(foo[? "bar"], 4, "Map accessor /= failed");
		')
	});

	addFact("Compound /= with array index", function() {
		compile_and_execute(@'
		var foo = [8];
		foo[0] /= 2;
		assert_equals(foo[0], 4, "Array index /= failed");
		')
	});

	addFact("Compound /= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [8];
		foo[@ 0] /= 2;
		assert_equals(foo[0], 4, "Typed array (@) accessor /= failed");
		')
	});

	addFact("Compound /= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 8;
		foo[| 0] /= 2;
		assert_equals(foo[| 0], 4, "List accessor (|) /= failed");
		')
	});

	addFact("Compound /= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 8;
		foo[# 0, 0] /= 2;
		assert_equals(foo[# 0, 0], 4, "Grid accessor /= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment %=

	addFact("Compound %= with direct variable", function() {
		compile_and_execute(@'
		var foo = 10;
		foo %= 3;
		assert_equals(foo, 1, "Direct variable %= failed");
		')
	});

	addFact("Compound %= with dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: 10 };
		foo.bar %= 3;
		assert_equals(foo.bar, 1, "Dot accessor %= failed");
		')
	});

	addFact("Compound %= with struct accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": 10 };
		foo[$ "bar"] %= 3;
		assert_equals(foo[$ "bar"], 1, "Map accessor %= failed");
		')
	});

	addFact("Compound %= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 10;
		foo[? "bar"] %= 3;
		assert_equals(foo[? "bar"], 1, "Map accessor %= failed");
		')
	});

	addFact("Compound %= with array index", function() {
		compile_and_execute(@'
		var foo = [10];
		foo[0] %= 3;
		assert_equals(foo[0], 1, "Array index %= failed");
		')
	});

	addFact("Compound %= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [10];
		foo[@ 0] %= 3;
		assert_equals(foo[0], 1, "Typed array (@) accessor %= failed");
		')
	});

	addFact("Compound %= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 10;
		foo[| 0] %= 3;
		assert_equals(foo[| 0], 1, "List accessor (|) %= failed");
		')
	});

	addFact("Compound %= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 10;
		foo[# 0, 0] %= 3;
		assert_equals(foo[# 0, 0], 1, "Grid accessor %= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment |=

	addFact("Compound |= with direct variable", function() {
		compile_and_execute(@'
		var foo = 0b0101;
		foo |= 0b1000;
		assert_equals(foo, 0b1101, "Direct variable |= failed");
		')
	});

	addFact("Compound |= with dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: 0b0101 };
		foo.bar |= 0b1000;
		assert_equals(foo.bar, 0b1101, "Dot accessor |= failed");
		')
	});

	addFact("Compound |= with struct accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": 0b0101 };
		foo[$ "bar"] |= 0b1000;
		assert_equals(foo[$ "bar"], 0b1101, "Map accessor |= failed");
		')
	});

	addFact("Compound |= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 0b0101;
		foo[? "bar"] |= 0b1000;
		assert_equals(foo[? "bar"], 0b1101, "Map accessor |= failed");
		')
	});

	addFact("Compound |= with array index", function() {
		compile_and_execute(@'
		var foo = [0b0101];
		foo[0] |= 0b1000;
		assert_equals(foo[0], 0b1101, "Array index |= failed");
		')
	});

	addFact("Compound |= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [0b0101];
		foo[@ 0] |= 0b1000;
		assert_equals(foo[0], 0b1101, "Typed array (@) accessor |= failed");
		')
	});

	addFact("Compound |= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 0b0101;
		foo[| 0] |= 0b1000;
		assert_equals(foo[| 0], 0b1101, "List accessor (|) |= failed");
		')
	});

	addFact("Compound |= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 0b0101;
		foo[# 0, 0] |= 0b1000;
		assert_equals(foo[# 0, 0], 0b1101, "Grid accessor |= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment &=

	addFact("Compound &= with direct variable", function() {
		compile_and_execute(@'
		var foo = 0b1101;
		foo &= 0b0101;
		assert_equals(foo, 0b0101, "Direct variable &= failed");
		')
	});

	addFact("Compound &= with dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: 0b1101 };
		foo.bar &= 0b0101;
		assert_equals(foo.bar, 0b0101, "Dot accessor &= failed");
		')
	});

	addFact("Compound &= with struct accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": 0b1101 };
		foo[$ "bar"] &= 0b0101;
		assert_equals(foo[$ "bar"], 0b0101, "Map accessor &= failed");
		')
	});

	addFact("Compound &= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 0b0101;
		foo[? "bar"] &= 0b0101;
		assert_equals(foo[? "bar"], 0b0101, "Map accessor &= failed");
		')
	});

	addFact("Compound &= with array index", function() {
		compile_and_execute(@'
		var foo = [0b1101];
		foo[0] &= 0b0101;
		assert_equals(foo[0], 0b0101, "Array index &= failed");
		')
	});

	addFact("Compound &= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [0b1101];
		foo[@ 0] &= 0b0101;
		assert_equals(foo[0], 0b0101, "Typed array (@) accessor &= failed");
		')
	});

	addFact("Compound &= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 0b1101;
		foo[| 0] &= 0b0101;
		assert_equals(foo[| 0], 0b0101, "List accessor (|) &= failed");
		')
	});

	addFact("Compound &= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 0b1101;
		foo[# 0, 0] &= 0b0101;
		assert_equals(foo[# 0, 0], 0b0101, "Grid accessor &= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment ^=

	addFact("Compound ^= with direct variable", function() {
		compile_and_execute(@'
		var foo = 0b1101;
		foo ^= 0b0101;
		assert_equals(foo, 0b1000, "Direct variable ^= failed");
		')
	});

	addFact("Compound ^= with dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: 0b1101 };
		foo.bar ^= 0b0101;
		assert_equals(foo.bar, 0b1000, "Dot accessor ^= failed");
		')
	});

	addFact("Compound ^= with struct accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": 0b1101 };
		foo[$ "bar"] ^= 0b0101;
		assert_equals(foo[$ "bar"], 0b1000, "Map accessor ^= failed");
		')
	});

	addFact("Compound ^= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = 0b1101;
		foo[? "bar"] ^= 0b0101;
		assert_equals(foo[? "bar"], 0b1000, "Map accessor ^= failed");
		')
	});

	addFact("Compound ^= with array index", function() {
		compile_and_execute(@'
		var foo = [0b1101];
		foo[0] ^= 0b0101;
		assert_equals(foo[0], 0b1000, "Array index ^= failed");
		')
	});

	addFact("Compound ^= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [0b1101];
		foo[@ 0] ^= 0b0101;
		assert_equals(foo[0], 0b1000, "Typed array (@) accessor ^= failed");
		')
	});

	addFact("Compound ^= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = 0b1101;
		foo[| 0] ^= 0b0101;
		assert_equals(foo[| 0], 0b1000, "List accessor (|) ^= failed");
		')
	});

	addFact("Compound ^= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = 0b1101;
		foo[# 0, 0] ^= 0b0101;
		assert_equals(foo[# 0, 0], 0b1000, "Grid accessor ^= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
	#region Compound Assignment ??=

	addFact("Compound ??= with direct variable", function() {
		compile_and_execute(@'
		var foo = undefined;
		foo ??= 42;
		assert_equals(foo, 42, "Direct variable ??= failed");
		')
	});

	addFact("Compound ??= with dot accessor", function() {
		compile_and_execute(@'
		var foo = { bar: undefined };
		foo.bar ??= 123;
		assert_equals(foo.bar, 123, "Dot accessor ??= failed");
		')
	});

	addFact("Compound ??= with struct accessor", function() {
		compile_and_execute(@'
		var foo = { "bar": undefined };
		foo[$ "bar"] ??= 99;
		assert_equals(foo[$ "bar"], 99, "Map accessor ??= failed");
		')
	});

	addFact("Compound ??= with map accessor", function() {
		compile_and_execute(@'
		var foo = ds_map_create();
		foo[? "bar"] = undefined;
		foo[? "bar"] ??= 77;
		assert_equals(foo[? "bar"], 77, "Map accessor ??= failed");
		')
	});

	addFact("Compound ??= with array index", function() {
		compile_and_execute(@'
		var foo = [undefined];
		foo[0] ??= 1;
		assert_equals(foo[0], 1, "Array index ??= failed");
		')
	});

	addFact("Compound ??= with typed array accessor @", function() {
		compile_and_execute(@'
		var foo = [undefined];
		foo[@ 0] ??= 2;
		assert_equals(foo[0], 2, "Typed array (@) accessor ??= failed");
		')
	});

	addFact("Compound ??= with List accessor |", function() {
		compile_and_execute(@'
		var foo = ds_list_create();
		foo[| 0] = undefined;
		foo[| 0] ??= 3;
		assert_equals(foo[| 0], 3, "List accessor (|) ??= failed");
		')
	});

	addFact("Compound ??= with grid accessor", function() {
		compile_and_execute(@'
		var foo = ds_grid_create(1, 1);
		foo[# 0, 0] = undefined;
		foo[# 0, 0] ??= 4;
		assert_equals(foo[# 0, 0], 4, "Grid accessor ??= failed");
		ds_grid_destroy(foo);
		')
	});

	#endregion
}
