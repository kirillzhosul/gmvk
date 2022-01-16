/// @description VK API Auth implementation.
// @author Kirill Zhosul (@kirillzhosul)

// Notice:
// This is offical (or, close to it) VK, User Auth implementation.
// If you have some questions, releated to the implementation,
// Please send PR / create issue on the main GitHub repository:
// https://github.com/kirillzhosul/gamemaker-vk-client
// Otherwise, if your question is not releated to the implementation.
// Please read official VK, VK API documentation, which is located here:
// --- https://dev.vk.com/reference
// And here (Actually, auth reference):
// --- https://dev.vk.com/api/access-token/getting-started


// Our client settings (ID, Secret).
#macro VK_API_AUTH_CLIENT_ID (VK_API_AUTH_CLIENT_ANDROID_ID)
#macro VK_API_AUTH_CLIENT_SECRET (VK_API_AUTH_CLIENT_ANDROID_SECRET)

// If true, will send `v` param when authorizing.
#macro VK_API_AUTH_SEND_VERSION false

#region URLs.

// VK API OAUTH link.
// Base link for auth methods (Direct Auth, Implicit Flow, Authorization Code Flow, Client Credentials Flow).
// Read more at the official documentation.
// --- https://dev.vk.com/api/access-token/getting-started
#macro VK_API_URL_OAUTH (VK_API_URL_PROTOCOL + "oauth.vk.com/")

// VK API `Direct Auth` auth type.
// For now, main auth type.
// Read more at the official documentation.
// --- https://dev.vk.com/api/direct-auth
#macro VK_API_URL_AUTH_DIRECT (VK_API_URL_OAUTH + "token")

// VK API Any `Flow` auth type.
// May be used for:  `Implicit Flow`, `Authorization Code Flow`, `Client Credentials Flow`.
// Read more at the official documentation.
// --- https://dev.vk.com/api/access-token/getting-started
#macro VK_API_URL_AUTH_FLOW (VK_API_URL_OAUTH + "authorize")

#endregion

#region Other clients.

// Android client settings.
#macro VK_API_AUTH_CLIENT_ANDROID_ID 2274003
#macro VK_API_AUTH_CLIENT_ANDROID_SECRET "hHbZxrka2uZ6jB1inYsH"

#endregion


// VK API auth provider that implements
// main features to work with VK auth.
function VkApiAuthProvider() constructor{
	// Publisher, will be notified for auth failed / success.
	self.on_auth = new sPublisher();

	self.auth_direct = function (login, password){
		// @description Auth direct with your login and password.

		self.auth_request = vk_api_request_auth(login, password);
	}
	
	self.auth_external = function (access_token, user_id, expires_in){
		// @description Auth with already acquired auth data.
		// @param {string} access_token Access token.
		// @param {real} user_id User index.
		// @param {real} expires_in Expires in.
		
		debug_print(format("[VK API][Auth] Auth for external: `{}, {}, {}`...", access_token, user_id, expires_in));
		self.auth_with_notify(access_token, user_id, expires_in);
	}
	
	self.params = function(params){
		// @description Pushes access token in to the given params, may used as wrapper for params when calling `vk_api_method`.
		
		if (is_undefined(self.auth)) return;
		
		variable_struct_set(params, "access_token", self.auth.access_token);
		return params;
	}
	
	#region Private.
	
	// Main auth data container.
	self.auth = undefined;
	
	// HTTP request for auth.
	self.auth_request = undefined;

	self.auth_with_notify = function (access_token, user_id, expires_in){
		// @description Creates auth data from arguments, and notifies `on_auth`, used as final auth step.
		
		self.auth = new VkApiAuthContainer(access_token, user_id, expires_in);
		
		self.on_auth.notify({
			status: true,

			access_token: access_token,
			user_id: user_id,
			expires_in: expires_in
		});
	}
	
	self.http_auth_request_callback = function(request_response){
		// @description HTTP auth request callback.
		// @param {string request_response Response of the request.
		
		var response = json_parse(request_response);
		
		if (variable_struct_exists(response, "error")){
			self.on_auth.notify({
				status: false,
				error: response,
				
				access_token: response.access_token,
				user_id: response.user_id,
				expires_in: response.expires_in
			});
			return;
		}
		
		self.auth_with_notify(response.access_token, response.user_id, response.expires_in);
	}
	
	self.http_request_callback = function(request_id, request_response){
		// @description HTTP request callback.
		// @param {real} request_id Index of the request.
		// @param {string request_response Response of the request.
		
		if (request_id == self.auth_request){
			self.http_auth_request_callback(request_response)
			return true;
		}
		
		return false;
	}
	
	#endregion
}

#region Structs.

// Auth data container.
function VkApiAuthContainer(access_token, user_id, expires_in) constructor{
	self.access_token = access_token;
	self.user_id = user_id;
	self.expires_in = expires_in;
}

// Direct auth request params.
function VkApiAuthParamsDirect(username, password, client_id, client_secret, grant_type) constructor{
	self.username = username;
	self.password = password;
	
	self.client_id = client_id;
	self.client_secret = client_secret;
	self.grant_type = grant_type // MUST be `password` as docs said.
	
	variable_struct_set(self, "2fa_supported", false);
	if (VK_API_AUTH_SEND_VERSION) variable_struct_set(self, "v", VK_API_VERSION);
}

#endregion

#region Request functions.

function vk_api_request_auth(username, password){
	// @description Sends auth HTTP request, to the VK API, that will return auth information if all OK.
	// @description for now this is `Direct Auth` auth type.
	// @description Read more at:
	// @description --- https://dev.vk.com/api/direct-auth
	// @description --- https://dev.vk.com/api/access-token/getting-started
	// @param {string} username Auth login.
	// @param {string} password Auth password.
	// @returns {http_id} HTTP request.
	
	// TODO: Support more types of the auth?
	return vk_api_request_direct_auth(username, password, VK_API_AUTH_CLIENT_ID, VK_API_AUTH_CLIENT_SECRET);
}

function vk_api_request_direct_auth(username, password, client_id, client_secret){
	// @description Sends `direct-auth` HTTP request, to the VK API, that will return auth information if all OK.
	// @description --- https://dev.vk.com/api/direct-auth
	// @description --- https://dev.vk.com/api/access-token/getting-started
	// @param {string} username Auth login.
	// @param {string} passwrod Auth password.
	// @param {real} client_id Client id.
	// @param {string} client_secret Client secret.
	// @returns {http_id} HTTP request.
	
	var params = new VkApiAuthParamsDirect(username, password, client_id, client_secret, "password");

	debug_print(format("[VK API][Direct Auth] Requesting auth for `{}:{}`...", username, password));
	return http_request_simple(VK_API_URL_AUTH_DIRECT, HTTP_METHOD_POST, params)
}

#endregion