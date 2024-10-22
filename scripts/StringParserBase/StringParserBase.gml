

/// @ignore
function StringParserBase() : FlexiParseBase() constructor {
    static initialize = function(_input) {
        inputString = _input;
		inputCharLength = string_length(_input);
		inputLineArray = string_split(string_replace_all(_input, "\r", ""), "\n");
		
		inputByteLength = string_byte_length(_input);
		charPos = 0;
		bytePos = 0;
		
		
        currentIndex = 0;
    };

    /// Fetches the next token from the string input
    static nextToken = function() {
        if (currentIndex < string_length(inputString)) {
            var token = string_char_at(inputString, currentIndex);
            currentIndex++;
            return token;
        }
        return undefined;  // No more tokens
    };
}

/// @ignore
function FlexiParseArray() : FlexiParseBase() constructor {
    static initialize = function(_input) {
        inputArray = _input;
        currentIndex = 0;
    };

    /// Fetches the next token from the array input
    static nextToken = function() {
        if (currentIndex < array_length(inputArray)) {
            var token = inputArray[currentIndex];
            currentIndex++;
            return token;
        }
        return undefined;  // No more tokens
    };
}

/// @ignore
function FlexiParseStruct() : FlexiParseBase() constructor {
    static initialize = function(_input) {
        inputStruct = _input;
        
    };

    /// Fetches the next token from the struct input
    static nextToken = function() {
        if (currentIndex < ds_list_size(keys)) {
            var key = ds_list_find_value(keys, currentIndex);
            var token = { key: key, value: inputStruct[key] };
            currentIndex++;
            return token;
        }
        return undefined;  // No more tokens
    };
}
