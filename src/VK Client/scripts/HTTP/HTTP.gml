/// @description HTTP Simple utils implementation.
// @author Kirill Zhosul (@kirillzhosul)


// HTTP Methods.
// To make CRUD interfaces.
#macro HTTP_METHOD_GET  "GET"
#macro HTTP_METHOD_POST "POST"
#macro HTTP_METHOD_PUT "PUT"
#macro HTTP_METHOD_DELETE "DELETE"

// DS map with all global headers,
// removes additional temporary ds_map creation,
// which is useless in that situation.
// used in `http_request_simple`.
global.HTTP_GLOBAL_HEADERS_MAP = ds_map_create();

function http_concat_params(params){
	// @param {struct} params HTTP params that should be concatenated, as struct.
	// @returns {string} Concatenated HTTP params string.
	
	var concatenated_params = "";
	
	var params_names = variable_struct_get_names(params);
	var params_count = array_length(params_names);
	for (var param_index = 0; param_index < params_count; param_index++){
		var param_name = array_get(params_names, param_index);
		var param_value = string(variable_struct_get(params, param_name));
		concatenated_params += param_name + "=" + param_value + (param_index == (params_count - 1) ? "" : "&");
	}
	
	return concatenated_params;
}

function http_request_simple(url, method, params){
	// @description Wrapper for the `http_request`.
	// @param {string} url URL address to send request.
	// @param {string} method HTTP method as string, or one from HTTP_METHOD.
	// @returns {http_request} HTTP request ID.
	
	params = is_string(params) ? params : http_concat_params(params);
	method = method ?? HTTP_METHOD_GET;
	return http_request(url, method , global.HTTP_GLOBAL_HEADERS_MAP, params)
}