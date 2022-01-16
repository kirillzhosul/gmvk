/// @description Debug.
// @author Kirill Zhosul (@kirillzhosul)

// Path to the log file of the debug system.
#macro DEBUG_PATH_LOG_FILE working_directory + "/debug/log.txt"

// Switchs writing to log file and debug messages (console).
#macro DEBUG_WRITE_CONSOLE true
#macro DEBUG_WRITE_LOG true

// Log file I/O stream.
global.DEBUG_LOG_FILE = variable_global_exists("DEBUG_LOG_FILE") ? global.DEBUG_LOG_FILE : file_text_open_write(DEBUG_PATH_LOG_FILE);

gml_pragma("global", "debug_init()"); if (false) debug_init(); // To call over all systems, before they called, and remove warning.
function debug_init(){
	// @description Initialises debug system.
	
	global.DEBUG_LOG_FILE = file_text_open_write(DEBUG_PATH_LOG_FILE);
}
function debug_free(){
	// @description Frees debug system.
	
	file_text_close(global.DEBUG_LOG_FILE)
}

function debug_print(message){
	// @description Prints message to the console and the log file.
	
	if (DEBUG_WRITE_LOG) file_text_write_string(global.DEBUG_LOG_FILE, message);
	if (DEBUG_WRITE_LOG) file_text_writeln(global.DEBUG_LOG_FILE);
	
	if (DEBUG_WRITE_CONSOLE) show_debug_message(message);
}