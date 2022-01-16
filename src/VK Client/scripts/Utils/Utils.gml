/// @description Utils.
// @author Kirill Zhosul (@kirillzhosul)

// `format` will replace that string with arguments.
#macro UTILS_FORMAT_STRING "{}"

function print(message){
	// @description Prints message to the console.
	// @param {string} message Message to show.
	
	debug_print(message);
}

function format(){
	// @description Formats string with `UTILS_FORMAT_STRING`

	var formatted_string = string(argument[0]);
	
	for (var argument_index = 1; argument_index < argument_count; argument_index++) {
	    formatted_string = string_replace(formatted_string, UTILS_FORMAT_STRING, string(argument[argument_index]));
	}
	
	return formatted_string;
}