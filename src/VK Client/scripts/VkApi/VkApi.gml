/// @description VK API implementation.
// @author Kirill Zhosul (@kirillzhosul)

// Notice:
// This is offical VK, VK API implementation.
// If you have some questions, releated to the implementation,
// Please send PR / create issue on the main GitHub repository:
// https://github.com/kirillzhosul/gamemaker-vk-client
// Otherwise, if your question is not releated to the implementation.
// Please read official VK, VK API documentation, which is located here:
// --- https://dev.vk.com/reference

#region Useful links.

// Useful links (Official documentation):
// Auth (This is code implements `Direct Auth`): 
// --- https://dev.vk.com/api/direct-auth
// --- https://dev.vk.com/api/access-token/getting-started
// Response format: 
// --- https://dev.vk.com/reference/json-schema
// --- https://dev.vk.com/reference/objects
// How API requests is sent: 
// --- https://dev.vk.com/api/api-requests
// List of the all VK API methods:
// --- https://dev.vk.com/method
// Overall information:
// --- https://dev.vk.com/reference

#endregion


// Version of the VK API (as HTTP param), that we calling,
// If changed, may cause potential breaking of some your features, 
// please read changes to new version, when updateing value below.
// Latest information is located here (official documentation).
// --- https://dev.vk.com/reference/versions
#macro VK_API_VERSION "5.131" // Latest (for 01.2022): 5.131

#macro VK_API_LANGUAGE "en"

#region URLs.

// If there is some problems with HTTPS,
// You may try to enter HTTP here.
// [I think this is will be not even used, but yea]
#macro VK_API_URL_PROTOCOL "https://"

// VK API Method call link,
// Send request to this URL, to call any VK API method.
// Example (of the request) `URL/{method}?params`
// See `vk_api_method` documentation for more information.
// Latest information is located here (official documentation).
// --- https://dev.vk.com/api/api-requests
#macro VK_API_URL_METHOD (VK_API_URL_PROTOCOL + "api.vk.com/method/")

#endregion


// VK API `provider` structure composition* that implements
// main features to work with VK as client.
function VkApi() constructor{
	// Providers.
	self.longpoll = new VkApiLongpollProvider();
	self.auth = new VkApiAuthProvider();

	// Publishers.
	self.on_result = new sPublisher();

	self.http_request_callback = function(request_raw){
		// @description HTTP request response callback.
		// @param {string} request_response HTTP request container.
		
		if (not ds_map_exists(request_raw, "result")) return;
		
		var request_id = ds_map_find_value(request_raw, "id");
		var request_response = ds_map_find_value(request_raw, "result");

		if (self.auth.http_request_callback(request_id, request_response)) return;
		if (self.longpoll.http_request_callback(request_id, request_response)) return;
		
		self.on_result.notify({
			request_id: request_id,
			request_response: request_response,
			request_raw: request_raw
		});
	}
}

function vk_api_method(method, params){
	// @description Sends HTTP request, to the VK API, that will call method that you given.
	// @description Currently, list of all VK API methods is located here (official documentation): 
	// @description --- https://dev.vk.com/method
	// @param {string} method One of the methods from the VK API documentation.
	// @param {struct_or_string} params HTTP params as string (without ?) or as struct, which will be concatenated with `http_concat_params`.
	// @returns {http_id} HTTP request.
	
	// VK API may require version.
	variable_struct_set(params, "v", VK_API_VERSION);
	variable_struct_set(params, "lang", VK_API_LANGUAGE);
	
	// HTTP Request is asynchronous.
	// request id should be returned as call identifier later.
	debug_print(format("[VK API] Calling API method `{}`, with params `{}`...", method, params));
	return http_request_simple(VK_API_URL_METHOD + method, HTTP_METHOD_POST, params);
}
