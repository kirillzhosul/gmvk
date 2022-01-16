/// @description  VK API Longpoll implementation.
// @author Kirill Zhosul (@kirillzhosul)

// Notice:
// This is offical VK, User Longpoll implementation.
// If you have some questions, releated to the implementation,
// Please send PR / create issue on the main GitHub repository:
// https://github.com/kirillzhosul/gamemaker-vk-client
// Otherwise, if your question is not releated to the implementation.
// Please read official VK, VK API documentation, which is located here:
// --- https://dev.vk.com/reference
// And here (Actually, longpoll reference):
// --- https://dev.vk.com/api/user-long-poll/getting-started

#region Useful links.

// Useful links:
// User Longpoll Documentation:
// --- https://dev.vk.com/api/user-long-poll/getting-started
// Third party longpoll documentation.
// --- https://github.com/danyadev/longpoll-doc

#endregion


// This mode will be used if you not specify mode.
// Actually, all mode flags.
#macro VK_API_LONGPOLL_DEFAULT_MODE (VK_API_LONGPOLL_MODE_FLAG.RETURN_ATTACHMENTS + VK_API_LONGPOLL_MODE_FLAG.EXTENDED_EVENT_SET + VK_API_LONGPOLL_MODE_FLAG.RETURN_PTS + VK_API_LONGPOLL_MODE_FLAG.FRIEND_ONLINE_RETURN_EXTRA + VK_API_LONGPOLL_MODE_FLAG.RETURN_RANDOM_ID)

// This version will be used if you not specify version.
#macro VK_API_LONGPOLL_DEFAULT_VERSION 3 // Latest (for 01.2022): 3

// May not be changed.
#macro VK_API_LONGPOLL_WAIT 25 // Max: 90, time in seconds which longpoll server will wait if there is no updates.


// VK API Longpoll provider.
// Provides simple interface to work with longpoll.
// 1. Subscribe on `on_update` publisher.
// 2. Call `start` method with your access_token.
// 3. All done, provider will query all, and notify `on_update`
function VkApiLongpollProvider() constructor{
	// Publisher, will be notified for every new longpoll update on server.
	self.on_update = new sPublisher();
	
	self.start = function(access_token, mode, version){
		// @description Starts longpoll, by requesting server and then requesting new updates.
		// @param {string} access_token Access token from auth.
		// @param {real} mode Mode as sum of the `VK_API_LONGPOLL_MODE_FLAG`.
		// @returns {bool} Started or not (If already started).
		
		if (not is_undefined(self.server)) return false;
		
		self.version = version ?? VK_API_LONGPOLL_DEFAULT_VERSION;
		self.mode = mode ?? VK_API_LONGPOLL_DEFAULT_MODE;
		self.access_token = access_token;
		
		self.request_server();
		
		return true;
	}
	
	#region Private.
	
	// Main longpoll server container.
	self.server = undefined;
	
	// Access token, hold here to query new server,
	// if there is failed flag (outdaten server).
	self.access_token = undefined;
	
	// Server settings.
	self.mode = VK_API_LONGPOLL_DEFAULT_MODE;
	self.version = VK_API_LONGPOLL_DEFAULT_VERSION;
	
	// If true, when getting server we also update ts,
	// If false, will not update ts.
	self.server_request_update_ts = true;
	self.server_request_ts = undefined;
	
	// HTTP Requests.
	self.server_request = undefined;
	self.updates_request = undefined;
	
	self.request_server = function(update_ts){
		// @description Requests new server.
		// @param {bool} updates_ts If false, will not update ts on response.
		
		self.server = undefined;
		self.server_request = vk_api_longpoll_request_server(self.access_token, self.version);
		self.server_request_update_ts = update_ts ?? true;
		self.server_request_ts = self.server_request_update_ts ? undefined : self.server.ts;
	}
	
	self.request_updates = function(new_ts){
		// @description Requests new updates.
		
		self.server.ts = new_ts ?? self.server.ts;
		self.updates_request = vk_api_longpoll_request_updates(self.server.server, self.server.key, self.server.ts, self.mode, self.version);
	}
	
	self.notify_updates = function(updates){
		// @description Notifies `on_update` callback, for all updates.
		// @param {array} updates Array of the all updates.
		
		if (is_undefined(updates)) return;
		
		var updates_count = array_length(updates);
		for (var update_index = 0; update_index < updates_count; update_index++){
			var update = updates[update_index];
				
			self.on_update.notify({
				update: update
			});
		}
	}
	
	self.http_server_request_callback = function(request_response){
		// @description HTTP callback, for server response.
		// @param {string} request_response Response from the HTTP.
		
		var response = json_parse(request_response);
		var server = response.response;
			
		var ts = self.server_request_update_ts ? server.ts : self.server_request_ts;
		self.server = new VkApiLongpollServerContainer(server.server, server.key, ts);
		self.request_updates(ts);
	}
	
	self.http_updates_request_process_failed = function(failed, response){
		// @description Processing failed flag of the updates response.
		// @param {real} failed Failed flag from the response.
		// @param {struct} response Response to get values if required.
		
		switch(failed){
			case VK_API_LONGPOLL_FAILED.HISTORY_OUTDATED:
				self.request_updates(response.ts);
			break;
			case VK_API_LONGPOLL_FAILED.KEY_EXPIRED:
				self.request_server(false);
			break;
			case VK_API_LONGPOLL_FAILED.SERVER_EXPIRED:
				self.request_server(true);
			break;
			case VK_API_LONGPOLL_FAILED.VERSION_INVALID:
				show_error("[VK API][Longpoll] VK API Longpoll server version is invalid! Please read documentation, and update `VK_API_LONGPOLL_VERSION`!", true); 
			break;
		}
	}
	
	self.http_updates_request_callback = function(request_response){
		// @description HTTP callback, for updates response.
		// @param {string} request_response Response from the HTTP.
		
		var response = json_parse(request_response);
		var failed = variable_struct_get(response, "failed");
		
		if (is_undefined(failed)){
			self.notify_updates(response.updates);
			self.request_updates(response.ts);
			return;
		}
		
		self.http_updates_request_process_failed(failed, response);
	}
	
	self.http_request_callback = function(request_id, request_response){
		// @description HTTP request callback.
		// @param {real} request_id Index of the request.
		// @param {string request_response Response of the request.
		
		if (request_id == self.server_request){
			self.http_server_request_callback(request_response)
			return true;
		}
		
		if (request_id == self.updates_request){
			self.http_updates_request_callback(request_response);
			return true;
		}
		
		return false;
	}
		
	#endregion
}

#region Enums.

// Flags for mode for `VK_API_LONGPOLL_MODE`.
// Read more:
// --- https://dev.vk.com/api/user-long-poll/getting-started
enum VK_API_LONGPOLL_MODE_FLAG{ 
	RETURN_ATTACHMENTS = 2, // Will return attachments.
	EXTENDED_EVENT_SET = 8, // Will return more event types.
	RETURN_PTS = 32, // Will return pts field (to remove `messages.getLongPollHistory` limit in 256 last events).
	FRIEND_ONLINE_RETURN_EXTRA = 64, // Will return extra fields on event 8 (Friend online).
	RETURN_RANDOM_ID = 128 // Will return random_id field.
}

// Platform types.
// Read more:
// --- https://dev.vk.com/api/user-long-poll/getting-started#Платформы
enum VK_API_LONGPOLL_PLATFORM_TYPE{
	MOBILE = 1,
	IPHONE = 2,
	IPAD = 3,
	ANDROID = 4,
	WINDOWS_PHONE = 5,
	WINDOWS = 6,
	WEB_OR_UNKNOWN = 7
}
	
// Failed flag types. Not for user use!
// Read more:
// --- https://dev.vk.com/api/user-long-poll/getting-started
enum VK_API_LONGPOLL_FAILED{
	HISTORY_OUTDATED = 1, // Longpoll history is outdated, or lost, please get new `ts` from the response.
	KEY_EXPIRED = 2, // Key expired, please get new server, with saving `ts`.
	SERVER_EXPIRED = 3, // Server expired, please get new server.
	VERSION_INVALID = 4 // Version invalid (VK_API_LONGPOLL_VERSION).
}

#endregion

#region Structs.

// Server data container.
function VkApiLongpollServerContainer(server, key, ts) constructor{
	self.server = server;
	self.key = key;
	self.ts = ts;
}

// Parameters for updates request.
function VkApiLongpollParamsUpdates(key, ts, version, mode, wait, act) constructor{
	self.key = key;
	self.ts = ts;
	self.version = version;
	self.mode = mode;
	self.wait = wait;
	self.act = act;
}

// Parameters for server request.
function VkApiLongpollParamsServer(access_token, lp_version) constructor{
	self.access_token = access_token;
	self.lp_version = lp_version;
}

#endregion

#region Request functions.

function vk_api_longpoll_request_server(access_token, version){
	// @description Sends HTTP VK API request, to get longpoll server.
	// @param {string} access_token Auth VK token (access_token).
	// @param {real} version Version of the longpoll.
	// @returns {http_id} HTTP request.
	
	// Read more at the official docs:
	// --- https://dev.vk.com/api/user-long-poll/getting-started
	var params = new VkApiLongpollParamsServer(access_token, version);
	
	debug_print(format("[VK API][Longpoll] Requesting longpoll server for version {}...", version));
	return vk_api_method("messages.getLongPollServer", params);
}

function vk_api_longpoll_request_updates(server, key, ts, mode, version){
	// @description Sends HTTP VK API request, to get new longpoll updates.
	// @param {string} server Your longpoll server URL.
	// @param {string} key Auth key, acquired when requesting server.
	// @param {string} ts Index of the last longpoll request, acquired from the previous updates request, or when requesting server.
	// @param {real} mode Longpoll mode, sum of VK_API_LONGPOLL_MODE_FLAG that you need. 
	// @param {real} version Version of the longpoll.
	// @returns {http_id} HTTP request.
	
	// Read more at the official docs:
	// --- https://dev.vk.com/api/user-long-poll/getting-started
	var params = new VkApiLongpollParamsUpdates(key, ts, version, mode, VK_API_LONGPOLL_WAIT, "a_check");
	
	debug_print(format("[VK API][Longpoll] Requesting longpoll updates with `ts={}`...", ts));
	return http_request_simple(VK_API_URL_PROTOCOL + server, HTTP_METHOD_POST, params);
}

#endregion