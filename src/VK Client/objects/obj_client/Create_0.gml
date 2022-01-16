/// @description Initialiastion.
// @author Kirill Zhosul (@kirillzhosul)

// WARNING!
// WARNING!

// This code is not refactored,
// THIS IS CODE IS NOT SAFE FOR READING.
// PLEASE MOVE KIDS AWAY FROM THE SCREEN.

// WARNING!
// WARNING

// WARNING!
// WARNING!

// This code is not refactored,
// THIS IS CODE IS NOT SAFE FOR READING.
// PLEASE MOVE KIDS AWAY FROM THE SCREEN.

// WARNING!
// WARNING

#region Macros.

#region Links.

#macro LINK_GITHUB "https://github.com/gamemaker-vk-client/"
#macro LINK_AUTHOR "https://kirillzhosul.github.io"

#endregion

#region Paths.

#macro AUTH_CACHE_FILE_PATH working_directory +  "/cache/auth.cache"
#macro IMAGES_CACHE_FILE_PATH working_directory +  "/cache/images/"

#endregion

#region Interface.

#macro INTERFACE_STYLE true

#macro INTERFACE_COLOR_DEFAULT INTERFACE_STYLE ? $FFFFFF : c_black
#macro INTERFACE_COLOR_ERROR $2131ff 
#macro INTERFACE_COLOR_MUTED INTERFACE_STYLE ? $848484 : c_dkgray

#macro INTERFACE_COLOR_BACKGROUND INTERFACE_STYLE ? $0a0a0a : c_white
#macro INTERFACE_COLOR_FOREGROUND INTERFACE_STYLE ? $1a1919 : c_ltgray
#macro INTERFACE_COLOR_HOVERED $FFFFFF
#macro INTERFACE_COLOR_SIDEBAR_OUTLINE INTERFACE_COLOR_MUTED
#macro INTERFACE_COLOR_SIDEBAR_BODY INTERFACE_STYLE ? $1F1F1F : $D1D1D1


#macro INTERFACE_FONT_SMALL fnt_client_small
#macro INTERFACE_FONT_DEFAULT fnt_client_default
#macro INTERFACE_TEXT_OFFSET 25

#macro INTERFACE_SIDEBAR_WIDTH 192
#macro INTERFACE_CENTER_X (room_width - INTERFACE_SIDEBAR_WIDTH) / 2
#macro INTERFACE_CENTER_Y room_height / 2

#endregion

#macro CACHE_FULLNAMES_REQUIRED_DELTA_TIME 100
#macro USERS_GET_DEFAULT_FIELDS "counters,photo_200,photo_50,online,last_seen,status,first_name,last_name"

#macro LONGPOLL_EVENT_CODE_NEW_MESSAGE 4
#macro LONGPOLL_EVENT_FLAGS_MESSAGE_OUTBOX +2

#endregion

#region Functions.

#region Auth caching.

function auth_cache_try_load(){
	// @description Tries to load auth cache from the file.
	// @returns {struct_or_undefined} Auth struct or undefined if failed to load.
	
	print("Trying to load auth cache from the file...");
	if (not file_exists(AUTH_CACHE_FILE_PATH)) return undefined;
	var file = file_text_open_read(AUTH_CACHE_FILE_PATH);
	if (file == -1) return undefined;
	
	var auth_token = file_text_read_string(file); file_text_readln(file);
	var auth_user_id = file_text_read_real(file); file_text_readln(file);
	var auth_expires_in = file_text_read_real(file); file_text_readln(file);
	
	if (string_length(auth_token) != 85) return undefined;
	
	if (auth_expires_in != 0){
		// TODO: Auth expires in checking.
		show_message("Your token expires_in not 0. Please auth again.");
		return undefined;
	}
	
	print("Sucessfully loaded auth cache from the file!");
	file_text_close(file);
	return {
		auth_token: auth_token,
		auth_user_id: auth_user_id,
		auth_expires_in: auth_expires_in
	}
}

function auth_cache_save(auth_token, auth_user_id, auth_expires_in){
	// @description Saves auth cache to the file.
	// @param {string} auth_token Authorization token from client.
	// @param {real} auth_user_id Authorization user index from client.
	// @param {real} auth_expires_in Authorization date when auth cache should be removed (or -1 if should not be removed) from client.
		
	print("Trying to save auth cache to the file...");
	var file = file_text_open_write(AUTH_CACHE_FILE_PATH);
	if (file == -1) return;
	
	file_text_write_string(file, auth_token); file_text_writeln(file);
	file_text_write_string(file, auth_user_id); file_text_writeln(file);
	file_text_write_real(file, auth_expires_in); file_text_writeln(file);
	
	file_text_close(file);
	print("Sucessfully saved auth cache to the file!");
}

#endregion

#region Client.

#region Events (callbacks).

function client_on_longpoll(args){
	
	var update = args.update;
	var code = update[0];
	
	switch(code){
		case LONGPOLL_EVENT_CODE_NEW_MESSAGE:
			//var message_id = update[1];
			var message_flags = update[2];

			if (not (message_flags & LONGPOLL_EVENT_FLAGS_MESSAGE_OUTBOX)){
				// Inbox flag.
				
				var message_peer_id = update[3];
				//var message_timestamp = update[4];
				var message_text = update[5];
				//var message_attachments = update[6];

				show_message_async("New message from: " + message_text + " from " + get_user_fullname_cached(message_peer_id));
			};
		break;
	};
}

function client_on_auth(args){
	// @description Event (callback) for auth from client.
	// @param {struct} args Arguments from client. (args.status, optional: (args.auth_token, args.auth_user_id, auth.expires_in))
	
	if (not args.status){
		self.cache_auth.write("in_process", false);
		print("Got error on auth, error:" + json_encode(args.error));
		
		var error_description = args.error[? "error_description"];
		page.cache.write("last_auth_error", "Can`t auth!\n" + error_description);
		
		return;
	}
	
	self.cache_auth.write("in_process", true);
	self.cache_auth.write("auth_token", args.access_token);
	self.cache_auth.write("auth_user_id", args.user_id);
	self.cache_auth.write("auth_expires_in", args.expires_in);
	auth_cache_save(args.access_token, args.user_id, args.expires_in);
	print("Auth completed for user_id " + string(args.user_id) + "!");
	
	// TODO: Check access token also via "secure.checkToken".
	cache_api_request_callback("auth_online_verification_request", "account.setOnline", {voip: 0, access_token: args.access_token}, function (result, is_error){
		self.cache_auth.write("in_process", false);
		
		if (is_error){
			// TODO: result error parsing is unsafe.
			var error_msg = result[? "error"][? "error_msg"];
			page.cache.write("last_auth_error", "Can`t verify authorization! Access token is not valid?\n`auth_online_verification_request`\n" + error_msg);
			return;
		}
		
		// TODO: Review.
		self.api.longpoll.start( self.cache_auth.read("auth_token"));
		
		client_request_user();
	
		self.page.cache.write("profile_user_id", self.cache_auth.read("auth_user_id"));
		self.page.change(ePAGE.CLIENT_MESSENGER);
	});
}

function client_on_result(args){
	// @description Event (callback) for API call HTTP result from client.
	// @param {struct} args Arguments from client. (args.result, args.call_id).
	var call_id = args.request_id;
	var result = json_decode(args.request_response);
	var is_error = ds_exists(result, ds_type_map) and ds_map_exists(result, "error");
	
	if (is_error){
		print("Got error on API result, error:" + json_encode(result[? "error"]));
	}

	cache_handle_callbacks_result(call_id, result, is_error);
	cache_handle_fullnames_result(call_id, result, is_error);
}

function client_on_raw(args){
	// @description Event (callback) for raw HTTP result from client.
	// @param {struct} args Arguments from client.
	
	if (args.status == 0){
		cache_handle_image_download_raw(args.call_id, args.status, args.result);
	}
}

#endregion

function client_request_user(){
	// @description Requests user data for first authorization.
	
	if (not cache_auth.exists("auth_user_id")) return;
	if (cache_main.exists("req_client_user")) return;
	
	var user_id = string(cache_auth.read("auth_user_id"));
	var params = {fields: USERS_GET_DEFAULT_FIELDS, user_id: user_id}
	
	print("Requested current client user (users.get)...");
	cache_api_request_callback("client_user", "users.get", params, function(result, is_error){
		if (is_error) return;
		result = result[? "response"][| 0];
		
		var photo = ds_map_find_value(result, "photo_50");
		if (not is_undefined(photo)) cache_download_image("user_photo_icon", photo);
		
		print("Successfully loaded current client user (users.get)...");
		cache_main.write("client_user", result);
		return result;
	});
}

function client_register_callbacks(){
	// @description Subscribes all methods to client.
	
	self.api.auth.on_auth.subscribe(client_on_auth);
	self.api.on_result.subscribe(client_on_result);
	self.on_raw = new sPublisher();
	self.on_raw.subscribe(client_on_raw);
	self.api.longpoll.on_update.subscribe(client_on_longpoll);
	print("Successfully subscribed on event callbacks!");
}

function client_try_auth_via_cache(){
	// @description Tries to auth client with values from cache.
	
	var loaden_auth_cache = auth_cache_try_load();
	if (is_undefined(loaden_auth_cache)) return;
	
	print("Requesting auth with external token (cache file)...");
	api.auth.auth_external(
		loaden_auth_cache.auth_token, 
		loaden_auth_cache.auth_user_id,
		loaden_auth_cache.auth_expires_in,
	);
}
	
function client_init(){
	// @description Initialises client.
	
	self.api = new VkApi();
	self.client_register_callbacks();
	self.client_try_auth_via_cache();
	print("Client successfully initialised!");
}

#endregion

#region GML events.

function event_draw(){
	// @description Draw event GML callback.

	draw_clear(INTERFACE_COLOR_BACKGROUND);
	draw_page();
	draw_sidebar();
}

function event_step(){
	// @description Step event GML callback.
	
	update_page();
	update_hotkeys();
	
	if (mouse_wheel_up()){
		self.page.scroll += 32;
	}else{
		if (mouse_wheel_down()){
			self.page.scroll -= 32;
		}
	}
	self.page.scroll = self.page.scroll > 0 ? 0 : self.page.scroll;
}

function event_http(){
	// @description HTTP event GML callback.
	
	var http_data = async_load;
	api.http_request_callback(http_data);
}

#endregion

#region Draw.

function draw_page(){
	// @description Draws current page.
	
	draw_reset();
	
	switch(page.current_index){
		case ePAGE.AUTH_LOGIN:
			page_auth_login_draw();
		break;
		case ePAGE.CLIENT_USER_PROFILE:
			page_client_user_profile_draw();
		break;
		case ePAGE.CLIENT_MESSENGER:
			page_client_mesenger_draw();
		break;
	}
}

function draw_sidebar(){
	// @description Draws sidebar.
	
	var user_icon = get_image_cached("user_photo_icon");
	var user = cache_main.try_read("client_user", undefined);
	
	draw_reset();
	
	draw_rectangle_outline(room_width - INTERFACE_SIDEBAR_WIDTH, 0, room_width, room_height, INTERFACE_COLOR_SIDEBAR_BODY, INTERFACE_COLOR_SIDEBAR_OUTLINE);
	
	var text_app = "VK Client (Windows)";
	var text_version = "!DEVELOPER VERSION!";
	var text_github = "Source Code";
	var text_author = "Author";
	
	var text_x = room_width - INTERFACE_SIDEBAR_WIDTH / 2;
	var text_y = room_height - 8;
	
	draw_set_color(INTERFACE_COLOR_MUTED);
	draw_set_halign(fa_right);
	draw_set_valign(fa_bottom);
	draw_text(text_x + string_width(text_app) / 2, text_y - floor(INTERFACE_TEXT_OFFSET * 3.5), text_app);
	
	draw_text(text_x + string_width(text_version) / 2, text_y - floor(INTERFACE_TEXT_OFFSET * 2.5), text_version);
	draw_set_color(INTERFACE_COLOR_DEFAULT);
	var button_github = draw_button_text_aligned(text_x + string_width(text_github) / 2, text_y - INTERFACE_TEXT_OFFSET * 1, text_github, INTERFACE_COLOR_HOVERED, -string_width(text_github), -string_height(text_github));
	var button_author = draw_button_text_aligned(text_x + string_width(text_author) / 2, text_y - INTERFACE_TEXT_OFFSET * 0, text_author, INTERFACE_COLOR_HOVERED, -string_width(text_author), -string_height(text_author));
	
	if (button_github) url_open(LINK_GITHUB);
	if (button_author) url_open(LINK_AUTHOR);
	
	var separator_y = text_y - floor(INTERFACE_TEXT_OFFSET * 4.5) - 8;
	draw_set_color(INTERFACE_COLOR_MUTED);
	draw_line(room_width - INTERFACE_SIDEBAR_WIDTH, separator_y, room_width, separator_y);
	
	draw_set_halign(fa_right);
	draw_set_valign(fa_top);
	draw_set_color(INTERFACE_COLOR_DEFAULT);
	
	text_y = room_height / 2 - INTERFACE_TEXT_OFFSET * 5;
	if (page.current_index != ePAGE.AUTH_LOGIN){
		var avatar_offset = 8;
		var avatar_x = room_width - avatar_offset - (is_undefined(user_icon) ? 50 : sprite_get_width(user_icon));
		var avatar_image_offset = (is_undefined(user_icon) ? 50 : sprite_get_height(user_icon));
		
		if (not is_undefined(user_icon)){
			draw_sprite_rounded(user_icon, 0, avatar_x, avatar_offset);
		}
		
		if (not is_undefined(user)){
			var fullname = get_user_fullname_cached(cache_auth.read("auth_user_id"));
			draw_text(avatar_x, avatar_offset + avatar_image_offset / 2 - string_height(fullname) / 2, fullname);
		}
		
		separator_y = avatar_offset * 2 + avatar_image_offset;
		draw_set_color(INTERFACE_COLOR_MUTED);
		draw_line(room_width - INTERFACE_SIDEBAR_WIDTH, separator_y, room_width, separator_y);
		draw_set_color(INTERFACE_COLOR_DEFAULT);
		// TODO: Add separators on each button.
		
		text_y = separator_y;
		
		var profile_text = "My Profile";
		var button_profile = draw_button_text_aligned(text_x + string_width(profile_text) / 2, text_y  + INTERFACE_TEXT_OFFSET * 0, profile_text, INTERFACE_COLOR_HOVERED, -string_width(profile_text), string_height(profile_text));
		
		var messenger_text = "Messenger";
		var button_messenger = draw_button_text_aligned(text_x + string_width(messenger_text) / 2, text_y  + INTERFACE_TEXT_OFFSET * 1, messenger_text, INTERFACE_COLOR_HOVERED, -string_width(messenger_text), string_height(messenger_text));
		
		var exit_text = "Exit";
		var button_exit = draw_button_text_aligned(text_x + string_width(exit_text) / 2, text_y  + INTERFACE_TEXT_OFFSET * 2, exit_text, INTERFACE_COLOR_HOVERED, -string_width(exit_text), string_height(exit_text));
		
		if (button_profile) page.change(ePAGE.CLIENT_USER_PROFILE);
		if (button_messenger) page.change(ePAGE.CLIENT_MESSENGER);
		if (button_exit){
			page.cache.clear();
			cache_main.clear();
			cache_fullnames.clear();
			cache_images.clear();
			cache_auth.clear();
			page.change(ePAGE.AUTH_LOGIN);
		}
	}
}

function draw_reset(){
	// @description Resets draw settings.
	
	draw_set_font(INTERFACE_FONT_DEFAULT);
	draw_set_color(INTERFACE_COLOR_DEFAULT);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

#endregion

#region Update.

function update_page(){
	// @description Updates page.
	
	switch(page.current_index){
		case ePAGE.CLIENT_USER_PROFILE: 
			page_client_user_profile_update();
		break;
		case ePAGE.CLIENT_MESSENGER: 
			page_client_messenger_update();
		break;
	}
}

function update_hotkeys(){
	// @description Updates hotkeys, should be called from step-event (or event_step).
	
	// Cache clear hotkey.
	if (keyboard_check_pressed(vk_f5)){
		if (keyboard_check(vk_control)){
			// CTRL + F5.
			// Total cache clearing (except auth cache).
			
			page.cache.clear();
			cache_main.clear();
			cache_fullnames.clear();
			cache_images.clear();
			// Auth cache shouldn`t be cleared!.
			//cache_auth.clear();
			
			client_request_user();
			print("Successfully cleared total cache (page, main, fullnames, images)!");
		}else{
			// F5.
			// Page cache clearing.
			
			page.cache.clear();
			print("Successfully cleared page cache!");
		}
	}
	
	if (keyboard_check_pressed(vk_f3)){
		if (keyboard_check(vk_control)){
			// CTRL + F3.
			// Dump caches.
			
			print("Cache Main:\n" + cache_main.__cached.toString());
			print("Cache Page:\n" + page.cache.__cached.toString());
			print("Cache Auth:\n" + cache_auth.__cached.toString());
			print("Successfully shown caches!");
		}
	}
}

#endregion

#region Requests / Actions caching.

#region Initiate request.

function cache_download_image(name, url){
	// @description Downloads image, then loads it as sprite and places in cache.
	// @param {string} name Name of the image to later query with `get_image_cached`.
	// @param {string} url URL to downloading.
	
	if (cache_images.sprites.exists(name)) return;
	print("Downloading image `" + name + "` from `" + url + "`...");
	
	var image_file_request = http_get_file(url, IMAGES_CACHE_FILE_PATH + name);
	cache_images.requests.write(image_file_request, name);
}

function cache_api_request(cache, name, method, params){
	// @decription Caches request with given name.
	// @param {sCache} cache Cache struct.
	// @param {string name for request, should be unique for cached requests.
	// @param {string} method Method for client to call.
	// @param {string} params Param for client to call.
	
	if (cache.exists(name)) return;
	if (cache.exists("req_" + name)) return;
	
	print("Caching API request with name `" + name + "` for method `" + method + "` with params `" + params.toString() + "`");
	
	var request = vk_api_method(method, api.auth.params(params));
	cache.write("req_" + name, request);
}

function cache_api_request_callback(name, method, params, callback){
	// @decription Caches request with given name and calls callback when it`s done.
	// @param {string name for request, should be unique for cached requests.
	// @param {string} method Method for client to call.
	// @param {string} params Param for client to call.
	// @param {function} callback Function to call when request is done.
	
	// TODO: Pass which cache to use?
	if (page.cache.exists(name)) return;
	if (cache_callbacks.functions.exists(name)) return;
	print("Caching API request with callback name `" + name + "` for method `" + method + "` with params `" + string(params)  + "`");

	var request = vk_api_method(method, api.auth.params(params));
	cache_callbacks.requests.write(request, name);
	cache_callbacks.functions.write(name, callback);
}

function cache_request_callback(name, url, callback){
	
	// TODO: Pass which cache to use?
	if (page.cache.exists(name)) return;
	if (cache_callbacks.functions.exists(name)) return;
	print("Caching HTTP request with callback name `" + name + "` for url `" + url + "`");

	var request = http_get(url);
	cache_callbacks.requests.write(request, name);
	cache_callbacks.functions.write(name, callback);
}


#endregion

#region Getters.

function get_user_fullname_cached(user_id_r){
	// @description Returns user fullname, or if it not yet cached, returns mention, and requests to cache.
	// @param {real_or_string} user_id User index to get fullname for.
	// @returns {string} Mention or fullname.
	
	user_id = string(user_id_r);
	
	// Already cached.
	if (cache_fullnames.fullnames.exists(user_id)){
		return cache_fullnames.fullnames.read(user_id);
	}
	
	// Should be requested.
	if (not cache_fullnames.requested_user_ids.exists(user_id)){
		var last_request_delta_time = current_time - cache_fullnames.last_request_time;
		if (last_request_delta_time > CACHE_FULLNAMES_REQUIRED_DELTA_TIME){
			print("Requesting fullname for user with id `" + user_id + "`");
			if (user_id < 0){
				var request = vk_api_method("groups.getById", api.auth.params({group_id: string(abs(user_id_r))}));
			}else{
				var request = vk_api_method("users.get", api.auth.params({user_id: user_id}));
			}
			cache_fullnames.requests.write(request, user_id);
			cache_fullnames.requested_user_ids.write(user_id, request);
			cache_fullnames.last_request_time = current_time;
		}
	}
	
	return "@id" + user_id;
}

function get_image_cached(name){
	// @description Gets downloaded image from cache or undefined if not found.
	// @param {string} name Name that you used in `cache_download_image`.
	// @returns {sprite_or_undefined} Image or undefined if not found.

	return cache_images.sprites.try_read(name, undefined);
}

function get_user_icon_cached(user_id){
	// @description Returns cached user icon or send request to get it.
	// @param {real} user_id USER index (<2000000000).
	// @returns {sprite_or_undefined} Icon.


	var icon = get_image_cached("profile_user_icon_" + string(user_id));
	if (is_undefined(icon)){
		var name = "profile_user_icon_" + string(user_id)
		if (user_id < 0){
			cache_api_request_callback(name, "groups.getById", {fields: "photo_50", group_id: abs(user_id)}, function(result, is_error){
				if (is_error) return;
				result = result[? "response"][| 0];
			
				var photo_50 = ds_map_find_value(result, "photo_50");
				if (not is_undefined(photo_50)){
					var user_id = string(result[? "id"] * -1);
					cache_download_image("profile_user_icon_" + user_id, photo_50);
				}
			});
		}else{
			cache_api_request_callback(name, "users.get", {fields: "photo_50", user_id: user_id}, function(result, is_error){
				if (is_error) return;
				result = result[? "response"][| 0];
			
				var photo_50 = ds_map_find_value(result, "photo_50");
				if (not is_undefined(photo_50)){
					var user_id = string(result[? "id"]);
					cache_download_image("profile_user_icon_" + user_id, photo_50);
				}
			});
		}
	}
	return icon;
}

#endregion

#region Processing HTTP caching.

function cache_handle_callbacks_result(call_id, result, is_error){
	// @decription Handles result (HTTP) event, and caching result from calling callback, if this is own request.
	// @param {real} call_id Request index.
	// @param {ds_map} result Result.
	
	if (cache_callbacks.requests.exists(call_id)){
		var name = cache_callbacks.requests.read(call_id);
		cache_callbacks.requests.remove(call_id);
		
		var callback = cache_callbacks.functions.read(name);
		cache_callbacks.functions.remove(name);
		
		print("Calling API result callback for cached request with name `" + name + "`");
		
		var callback_result = callback(result, is_error);
		if (not is_undefined(callback_result)) page.cache.write(name, callback_result);
	}
}

function cache_handle_image_download_raw(call_id, status, path){
	// @decription Handles raw HTTP event, and caching downloaded image, if this is own request.
	// @param {real} call_id Request index.
	// @param {real} status HTTP status.
	// @param {string} path Downloaded path.
	
	if (not (status == 0 and cache_images.requests.exists(call_id))) return;
	
	var name = cache_images.requests.read(call_id);
	cache_images.requests.remove(call_id);
		
	var sprite = sprite_add(path, 1, false, false, 0, 0);
	cache_images.sprites.write(name, sprite);
	print("Successfully downloaded image with name `" + name + "` to the file `" + path + "`!");
}

function cache_handle_fullnames_result(call_id, result, is_error){
	// @decription Handles result (HTTP) event, and caching fullname, if this is own request.
	// @param {real} call_id Request index.
	// @param {ds_map} result Result.
	// @param {bool} is_error Error occured or not.
	
	// TODO: Handle errors.
	if (cache_fullnames.requests.exists(call_id)){
		var user_id = cache_fullnames.requests.read(call_id);
		cache_fullnames.requests.remove(call_id);
		cache_fullnames.requested_user_ids.remove(user_id);
		
		if (is_error) return;
		
		var user = result[? "response"][| 0];
		var name = user[? "name"];
		if (is_undefined(name)){
			var fullname = string(user[? "first_name"]) + " " + string(user[? "last_name"]);
		}else{
			var fullname = name;
		}
		
		print("Cached fullname `" + fullname + "` for user with id `" + user_id + "`");
		cache_fullnames.fullnames.write(user_id, fullname);
		
	}
}

#endregion

#endregion

#region Pages.

#region Auth login.

function page_auth_login_draw(){
	// @description Draws page.
	
	var start_x = 16;
	var start_y = 16;

	var last_auth_error = page.cache.try_read("last_auth_error", undefined);
	var auth_in_process = cache_auth.try_read("in_process", false);
	
	draw_rectangle_outline(0, 0, room_width, start_y + INTERFACE_TEXT_OFFSET * 6 + start_y, INTERFACE_COLOR_FOREGROUND, INTERFACE_COLOR_MUTED);
	
	draw_set_color(INTERFACE_COLOR_DEFAULT);
	draw_text(start_x, start_y + INTERFACE_TEXT_OFFSET * 0, "Authorization");
	draw_set_color(INTERFACE_COLOR_MUTED);
	draw_text(start_x, start_y + INTERFACE_TEXT_OFFSET * 1, "Login to continue!");

	draw_set_color(INTERFACE_COLOR_DEFAULT);
	var button_auth_login = draw_button_text(start_x + 28, start_y + INTERFACE_TEXT_OFFSET * 3, "• Login with login:passwords", INTERFACE_COLOR_HOVERED);
	var button_auth_token = draw_button_text(start_x + 28, start_y + INTERFACE_TEXT_OFFSET * 4, "• Login with access_token and user_id", INTERFACE_COLOR_HOVERED);
	var button_auth_cache = draw_button_text(start_x + 28, start_y + INTERFACE_TEXT_OFFSET * 5, "• Login from cache data (if exists)", INTERFACE_COLOR_HOVERED);
	
	if (button_auth_login and not auth_in_process){
		var auth_login = get_string("Please enter your login (phone or mail)", "");
		var auth_password = get_string("Enter your password", "");
		if (string_length(auth_login) > 3 and string_length(auth_password) > 3){
			self.cache_auth.write("in_process", true); // TODO: on_auth_request?.
			api.auth.auth_direct(auth_login, auth_password);
		}else{
			page.cache.write("last_auth_error", "Password or login too short!");
		}
	}
			
	if (button_auth_token and not auth_in_process){
		var auth_token = get_string("Enter your access token (access_token)", "");
		var auth_user_id = get_string("Enter your user index (user_id)", "");
		var auth_expires_in = get_integer("Enter expire time (expires_in, or left blank (0) if not required))", 0);
		if (string_length(auth_token) > 80 and string_length(auth_user_id) > 0){
			self.cache_auth.write("in_process", true); // TODO: on_auth_request?.
			api.auth.auth_external(auth_token, auth_user_id, auth_expires_in);
		}else{
			page.cache.write("last_auth_error", "Access token have invalid size or user index is blank!");
		}
	}
	
	if (button_auth_cache and not auth_in_process){
		client_try_auth_via_cache();
	}
	
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	if (auth_in_process){
		draw_set_color(INTERFACE_COLOR_MUTED);
		draw_text(INTERFACE_CENTER_X, INTERFACE_CENTER_Y, "..waiting auth response..");
		// TODO: Loader.
	}else{
		if (not is_undefined(last_auth_error)){
			draw_set_color(INTERFACE_COLOR_ERROR);
			draw_text(INTERFACE_CENTER_X, INTERFACE_CENTER_Y, "Error\n" + last_auth_error);
		}
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

#endregion

#region Client messenger.

function page_client_messenger_update(){
	// @description Update for page.
	
	// Caching conversations for messenger page.
	cache_api_request_callback("conversations", "messages.getConversations", {count: 20, extended: 0, offset: 0}, function(result, is_error){
		if (is_error) return;
		print("Messenger successfully queried initial conversations! (Total on server: " + string(result[? "response"][? "count"]) + " items)");
		
		//unread_count
		return result[? "response"][? "items"];
	});
	
	var selected_peer = page.cache.try_read("selected_peer");
	
	if (not is_undefined(selected_peer)){
		// Caching conversations for messenger page.
		cache_api_request_callback("messages_" + string(selected_peer), "messages.getHistory", {count: 30, peer_id: selected_peer, offset: 0}, function(result, is_error){
			if (is_error) return;
			print("Messenger successfully queried initial messages! (Total on server: " + string(result[? "response"][? "count"]) + " items)");

			//unread_count
			return result[? "response"][? "items"];
		});
		
		var type_message = page.cache.try_read("type_message");
		page.cache.write("type_message", keyboard_string);
		
		if (keyboard_check_pressed(vk_enter)){
			vk_api_method("messages.send", api.auth.params({
				message: type_message,
				peer_id: selected_peer,
				random_id: 0,
			}));
			keyboard_string = "";
			
		}
	}
}
	

function page_client_mesenger_draw(){
	
	var selected_peer = page.cache.try_read("selected_peer", undefined);

	if (is_undefined(selected_peer)){
		return page_client_mesenger_draw_conversations();
	}else{
		return page_client_mesenger_draw_peer(selected_peer);
	}
}

function page_client_mesenger_draw_conversations(){
	// @description Draws page when there is no peer selected (list conversation).
	
	draw_reset();
	
	var conversations = page.cache.try_read("conversations", undefined);
	if (is_undefined(conversations)){
		draw_set_color(INTERFACE_COLOR_MUTED);
		draw_text_centered(INTERFACE_CENTER_X, INTERFACE_CENTER_Y, "..loading conversations..");
		// TODO: Loader.
		return;
	};

	var conversation_x = 32 + 50;
	var conversations_count = ds_list_size(conversations);
	for (var conversation_index = 0; conversation_index < conversations_count; conversation_index++){
		var conversation = conversations[| conversation_index];
		var conversation_y = 16 + (INTERFACE_TEXT_OFFSET * 2) * conversation_index;
		var conversation_type = conversation[? "conversation"][? "peer"][? "type"];
		var last_message_text = message_format(conversation[? "last_message"]);
		var last_message_is_out = conversation[? "last_message"][? "out"];
		//var last_message_is_action = is_undefined(conversation[? "last_message"][? "action"]);

		var unread_messages_count = conversation[? "conversation"][? "last_conversation_message_id"] - conversation[? "conversation"][? "in_read_cmid"];
		//show_message(json_encode(conversation))
		
		var peer_id = conversation[? "conversation"][? "peer"][? "id"];
		var title = undefined;  // TODO: Add peers title getter.
		if (conversation_type == "chat"){
			title = conversation[? "conversation"][? "chat_settings"][? "title"];
		}else{
			if (conversation_type == "user"){
				title = get_user_fullname_cached(peer_id);
			}else{
				if (conversation_type == "group"){
					title = get_user_fullname_cached(peer_id);
				}
			}
		}
		
		if (is_undefined(title)){
			//show_message(json_encode(conversation));
			title = ":ERROR:";
		}
		
		var conversation_icon = undefined;
		if (conversation_type == "chat"){
			var conversation_icon = get_image_cached("peer_chat_icon_" + string(peer_id));
			
			if (is_undefined(conversation_icon)){
				var conversation_photo = conversation[? "conversation"][? "chat_settings"][? "photo"];
				if (not is_undefined(conversation_photo)){
					var photo_50 = conversation_photo[? "photo_50"];
					if (not is_undefined(photo_50)){
						cache_download_image("peer_chat_icon_" + string(peer_id), photo_50);
					}
				}
			}
		}else{
			conversation_icon = get_user_icon_cached(peer_id);
		}
		
		if (not is_undefined(conversation_icon)) draw_sprite_rounded(conversation_icon, 0, conversation_x - 50 - 16, conversation_y);
		draw_set_color(INTERFACE_COLOR_MUTED);
		draw_text(conversation_x, conversation_y, title);
		
		draw_set_color(INTERFACE_COLOR_DEFAULT);
		if (last_message_is_out){
			last_message_text = "Вы: " + last_message_text;
		}else{
			last_message_text = get_user_fullname_cached(conversation[? "last_message"][? "from_id"]) + ": " + last_message_text;
		}
		
		draw_text(conversation_x, conversation_y + 16, last_message_text);
		draw_set_color(INTERFACE_COLOR_ERROR);
		if (unread_messages_count != 0) draw_text(conversation_x + string_width(last_message_text), conversation_y + 16, " " + string(unread_messages_count));
		
		var region_w = max(string_width(title), string_width(last_message_text));
		var region_h = string_height(title) + string_height(last_message_text);
		if (draw_button_region(conversation_x, conversation_y, conversation_x + region_w, conversation_y + region_h, INTERFACE_COLOR_HOVERED)){
			var peer_id = conversation[? "conversation"][? "peer"][? "id"];
			page.cache.write("selected_peer", peer_id);
			page.cache.write("selected_fullname", title);
		}
	}
}

function page_client_mesenger_draw_peer(selected_peer){
	// @description Draws page when there is peer selected.
	
	if (is_undefined(selected_peer)) return;
	
	var is_chat = selected_peer > 2000000000;
	var icon = is_chat ? get_image_cached("peer_chat_icon_" + string(selected_peer)) : get_user_icon_cached(selected_peer);
	var selected_peer_fullname = page.cache.try_read("selected_fullname");
	
	var messages = page.cache.try_read("messages_" + string(selected_peer));

	if (not is_undefined(messages)){
		draw_set_color(INTERFACE_COLOR_DEFAULT);
		
		var last_from_id = -1;
		
		var side_offset = 8;
		var size = ds_list_size(messages);
		var msg_current_y = self.page.scroll + (INTERFACE_TEXT_OFFSET + 8);
		for (var message_id = size - 1;message_id >= 0; message_id--){
			var message = messages[| message_id];
			var from_id = message[? "from_id"];
			
			var block_form = from_id != last_from_id;
			var out = message[? "out"];
			var text = message[? "text"];
			var is_action = false;
			
			var attachment_sprite = undefined;
			var attachment_h = 0;
			var attachment_w = 0;
			
			var name = "";
			if (block_form){
				var fullname = get_user_fullname_cached(from_id);
				
				if (is_chat){
					name = fullname;
				}else{
					name = string_copy(fullname, 0, string_pos(" ", fullname) - 1);
				}
			}
			
			if (text == ""){
				var attachments = message[? "attachments"];
				var attachments_count = ds_list_size(attachments);
				if (attachments_count == 1){
					var attachment = attachments[| 0];
					var type = attachment[? "type"];
					
					if (type == "sticker"){
						var sticker = attachment[? "sticker"];
						var sticker_id = sticker[? "sticker_id"]
						
						var image = sticker[? "images"][| 1];
						
						cache_download_image("sticker_" + string(sticker_id), image[? "url"]);
						attachment_sprite = get_image_cached("sticker_" + string(sticker_id));
					}
					
					if (type == "photo"){
						var photo = attachment[? "photo"];
						
						var sizes = photo[? "sizes"];
						var image = sizes[| ds_list_size(sizes) - 1];
						
						var owner_id = photo[? "owner_id"];
						var item_id = photo[? "id"];
						
						var image_name = "photo_" + string(owner_id) + "_" + string(item_id);
						cache_download_image(image_name, image[? "url"]);
						attachment_sprite = get_image_cached(image_name);
					}
					
					if (not is_undefined(attachment_sprite)){
						var attachment_h = sprite_get_height(attachment_sprite);
						var attachment_w = sprite_get_width(attachment_sprite);
					}
				}
				
				if (text == "" and is_undefined(attachment_sprite)){
					var text = message_format(message);
					var is_action = !is_undefined(message[? "action"]);
				}
			}
			
			draw_set_color($1a1919);
			msg_current_y += ((from_id != last_from_id) ? 58 : 40);
			var msg_x = is_action ? INTERFACE_CENTER_X : (out ? room_width - INTERFACE_SIDEBAR_WIDTH - side_offset : 50 +  side_offset);
			var rect_x = out ? msg_x - string_width(text) - attachment_w : msg_x;
			
			var rect_w = max(string_width(text), string_width(name), attachment_w);
			var rect_x2 = rect_x + rect_w + 8;
			draw_roundrect_ext(rect_x - 8, msg_current_y - 8, rect_x2, msg_current_y + string_height(text) + attachment_h + 8 + block_form * INTERFACE_TEXT_OFFSET, 30, 30, false);
			if (block_form and not out){
				var message_icon = get_user_icon_cached(from_id);
				if (not is_undefined(message_icon)) draw_sprite_rounded(message_icon, 0, msg_x - 58, msg_current_y - 25 + 16);
			}
			if (out){ 
				draw_set_halign(fa_right);
			}else{
				draw_set_halign(fa_left);
			}
			if (block_form){
				draw_set_color(c_aqua);
				draw_text(msg_x, msg_current_y, name);
			}
			if (is_action){
				draw_set_halign(fa_center);
				draw_set_color(c_silver);
			}else{
				if (out){ 
					draw_set_color($BBBBBB);
					draw_set_halign(fa_right);
				}else{
					draw_set_color($FFFFFF);
					draw_set_halign(fa_left);
				}
			}
			
			draw_text(msg_x, msg_current_y + (block_form * INTERFACE_TEXT_OFFSET), text);
			
			if (not is_undefined(attachment_sprite)){
				draw_sprite(attachment_sprite, 0, msg_x - (attachment_w * out), msg_current_y + (block_form * INTERFACE_TEXT_OFFSET));
			}
			if (block_form) msg_current_y += INTERFACE_TEXT_OFFSET;
			msg_current_y += attachment_h;
			last_from_id = from_id;
		}
		draw_set_halign(fa_left);
	}
	
	
	draw_rectangle_outline(0, 0, room_width - INTERFACE_SIDEBAR_WIDTH, 16 + INTERFACE_TEXT_OFFSET + 16, INTERFACE_COLOR_FOREGROUND, INTERFACE_COLOR_MUTED);
	if (not is_undefined(icon)) draw_sprite_rounded(icon, 0, 8, 4);
	
	
	var back_text = "back";
	var button_back = draw_button_text(room_width - INTERFACE_SIDEBAR_WIDTH - string_width(back_text) - 16, 16, back_text, INTERFACE_COLOR_HOVERED);
	var button_profile = false;
	
	if (not is_chat){
		var profile_text = "open profile";
		var button_profile = draw_button_text(room_width - INTERFACE_SIDEBAR_WIDTH - string_width(back_text) - 8 - string_width(profile_text) - 16, 16, profile_text, INTERFACE_COLOR_HOVERED);
	}
	
	draw_set_color(INTERFACE_COLOR_DEFAULT);
	draw_text(50 + 8 + 8, 16, selected_peer_fullname);
	
	if (button_back){
		page.cache.remove("selected_peer");
		page.cache.remove("selected_fullname");
	}
	
	if (button_profile){
		page.change(ePAGE.CLIENT_USER_PROFILE);
		page.cache.write("profile_user_id", selected_peer);
	}
	
	
	var message = page.cache.try_read("type_message", "");
	var text = "Your message";
	
	draw_reset();
	draw_rectangle_outline(0, room_height - INTERFACE_TEXT_OFFSET * 2, 8 + max(string_width(text), string_width(message)) + 8, room_height, INTERFACE_COLOR_FOREGROUND, INTERFACE_COLOR_MUTED);
	
	draw_set_color(INTERFACE_COLOR_DEFAULT);
	draw_text(8, room_height - INTERFACE_TEXT_OFFSET * 2, text);
	draw_text(8, room_height - INTERFACE_TEXT_OFFSET, message);
}

#endregion

#region Client user profile.

function page_client_user_profile_update(){
	// @description Update for page.
	
	var profile_user_id = string(page.cache.try_read("profile_user_id", undefined) ?? cache_auth.read("auth_user_id"));
	
	// Caching wall for user profile page.
	// TODO: Cache to page cache.
	cache_api_request_callback("profile_user_wall", "wall.get", {count: 5, offset: 0, owner_id: profile_user_id}, function(result, is_error){
		if (is_error) return;
		// TODO: Broken, spams requests.
		return result[? "response"][? "items"];
	});
	
	// Caching user for user profile page.
	// TODO: Cache to page cache.
	cache_api_request_callback("profile_user", "users.get", {fields: USERS_GET_DEFAULT_FIELDS, user_id: profile_user_id}, function(result, is_error){
		if (is_error) return;
		result = result[? "response"][| 0];
		
		var user_id = string(result[? "id"]);

		var photo_200 = ds_map_find_value(result, "photo_200");
		if (not is_undefined(photo_200)) cache_download_image("profile_user_avatar_" + user_id, photo_200);

		return result;
	});
}

function page_client_user_profile_draw(){
	var cx = INTERFACE_CENTER_X;
	var cy = INTERFACE_CENTER_Y;
	
	var start_x = 16;
	var start_y = 16;
	
	var profile_user_id = string(page.cache.try_read("profile_user_id", undefined) ?? cache_auth.read("auth_user_id"));
	var avatar = get_image_cached("profile_user_avatar_" + profile_user_id);
	var user = page.cache.try_read("profile_user", undefined);
	var wall = page.cache.try_read("profile_user_wall", undefined);
	
	draw_rectangle_outline(0, 0, room_width, 232, INTERFACE_COLOR_FOREGROUND, INTERFACE_COLOR_MUTED);
	
	if (not is_undefined(avatar)) draw_sprite_rounded(avatar, 0, start_x, start_y);
	
	draw_set_color(c_white);
	draw_set_valign(fa_top);
	if (not is_undefined(user)){
		draw_text(256, 48, user[? "first_name"] + " " + user[? "last_name"]);
		draw_set_font(INTERFACE_FONT_SMALL);
		if (user[? "online"]){
			draw_text(256, 68, "Online");
		}else{
			if (ds_map_exists(user, "last_seen")){
				var time = user[? "last_seen"][? "time"]
				var last_seen = date_inc_second(date_create_datetime(1970, 1, 2, 0, 0, 0), time);
				draw_text(256, 68, "Was online at " + date_time_string(last_seen));
			}
		}

				
		draw_set_color($848484);
		draw_text(256, 88, user[? "status"]);
		draw_set_font(INTERFACE_FONT_DEFAULT);
		if (user[? "is_closed"]){
			//draw_text(108, 280, "You have closed profile, \nopen it,\nto be in contact.");
		}
		draw_set_valign(fa_middle);
		draw_set_halign(fa_left);
		var calumbs = user[? "counters"][? "albums"];
		var cvideos = user[? "counters"][? "videos"];
		var caudios = user[? "counters"][? "audios"];
		var cphotos = user[? "counters"][? "photos"];
		var cgroups = user[? "counters"][? "groups"];
		var cfollowers = user[? "counters"][? "followers"];
		var cfriends = user[? "counters"][? "friends"];
				
		var conlinefriends = user[? "counters"][? "online_friends"];
		draw_text(256, 148, string(cfriends) + " friends (" +string(conlinefriends) + " online) ");
		draw_text(256, 168, is_undefined(cfollowers) ? "no followers" : string(cfollowers) + " followers");
		draw_text(256, 188, string(cvideos) + " videos, " + string(cphotos) + " photos, " + string(calumbs) + " albums, " + string(cgroups) + " communities, " + string(caudios) + " audios");
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	if (not is_undefined(wall)){
		for (var wall_index=0; wall_index<ds_list_size(wall);wall_index++){
			var post = wall[| wall_index];
			var views = ds_map_exists(post, "views") ? post[? "views"][? "count"] : 0;
			var likes = post[? "likes"][? "count"];
			//var date = post[? "date"];
			var from_id = post[? "from_id"];
			var is_pinned = post[? "is_pinned"];
			var text = post[? "text"];
			var py = cy + wall_index * 90;
			var text_from = "Post from " + get_user_fullname_cached(from_id);
			var text_info = string(likes) + " likes, " + string(views) + " views" + (is_pinned ? " (pinned)" : "");
			draw_set_color($1a1919);
			var mw = max(string_width(text), string_width(text_from), string_width(text_info));
			var mh = string_height(text) + string_height(text_from) + string_height(text_info);
			cx = INTERFACE_CENTER_X - mw / 2;
			cy = INTERFACE_CENTER_Y;
			draw_roundrect_ext(cx - 8, py - 8, cx + mw + 8, py + mh + 8, 30, 30, false);
			draw_set_color($848484);
			draw_text(cx, py, text_from);
			draw_text(cx, py + 20, text_info);
			draw_set_color($FFFFFF);
			draw_text(cx, py + 40, text);
		}
	}
}

#endregion

#endregion

function message_format(message){
	var message_text = message[? "text"];
	var message_attachments = (message_text == "") ? message[? "attachments"] : undefined;
	var fwd_messages = (message_text == "") ? message[? "fwd_messages"] : undefined;
	var action = (message_text == "") ? message[? "action"] : undefined;
	return message_format_ext(message_text, message_attachments, fwd_messages, action);
}

function message_format_ext(message_text, message_attachments, fwd_messages, action){
	message_text = string_replace_all(message_text, "\n", "");

	// TODO: date field.
	if (message_text == ""){;
		var last_attachment = message_attachments[| 0];
		if (not is_undefined(last_attachment)){
			var type = last_attachment[? "type"];
				
			// TODO: Encapsulate attachment type.
			switch(type){
				case "photo": return "<Photo>";
				case "sticker": return "<Sticker>";
				case "audio_message": return "<Audio message>";
				case "video": return "<Video>";
				case "audio": return "<Audio>";
				case "doc": return "<Document>";
				case "link": return "<Link>";
				case "wall": return "<Wall post>";
				case "wall_reply": return "<Wall reply>";
				case "gift": return "<Gift>";
				default: return "<Attachment " + type + ">"; 
			}
		}else{
			var count = ds_list_size(fwd_messages);
			if (count == 0){
				var type = action[? "type"];
				// TODO: Encapsulate action type.
				switch(type){
					case "chat_invite_user_by_link": return "<Joined chat by link...>";
				}
				return "<Action " + type + ">";
			}
			
			return "<" + string(count) + " forwarded messages>";
		}
	}
	
	return message_text;
}

#endregion

#region Variables.

// Caches.
x = x; // GMEdit warn fix.
cache_auth = new sCache();
cache_main = new sCache();
cache_fullnames = {
	fullnames: new sCache(),
	requests: new sCache(),
	requested_user_ids: new sCache(), // May be ds-list.
	
	last_request_time: current_time,
	
	clear: function(){
		// @description Clears cache.
		self.fullnames.clear();
		self.requests.clear();
		self.requested_user_ids.clear();
	}
}
cache_images = {
	sprites: new sCache(),
	requests: new sCache(),

	clear: function(){
		// @description Clears cache.
		self.sprites.clear();
		self.requests.clear();
	}
}
cache_callbacks = {
	requests: new sCache(),
	functions: new sCache(),
	
	clear: function(){
		// @description Clears cache.
		self.requests.clear();
		self.functions.clear();
	}
}

// Other.
api = new VkApi();
page = new sPage(ePAGE.AUTH_LOGIN);

#endregion

// Initialisation.
client_init();