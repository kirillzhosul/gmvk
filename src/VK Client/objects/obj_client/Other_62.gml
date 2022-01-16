/// @description HTTP.
// @author Kirill Zhosul (@kirillzhosul)

event_http();

self.on_raw.notify({
	call_id: async_load[? "id"],
	status: async_load[? "status"],
	result: async_load[? "result"]
});