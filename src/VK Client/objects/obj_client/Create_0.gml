/// @description Initialiastion.
// @author Kirill Zhosul (@kirillzhosul)

#region Macros, enums.

enum ePAGE{
	NOT_FOUND,
	AUTH
}

#endregion

#region Functions.

function init_client(){
	client = new sVKClient();
	if (not client.is_authorized){
		page = ePAGE.AUTH;
	}
}

function draw_current_page(){
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	
	var cx = room_width / 2;
	var cy = room_height / 2;
	
	switch(page){
		case ePAGE.NOT_FOUND:
			draw_text(cx, cy, "Sorry, but page you looking for, not exists!");
		break;
		case ePAGE.AUTH:
			draw_text(cx, cy, "Please authorize to continue...");
		break;
		default:
		break;
	}
	
	draw_set_halign(fa_left);
	draw_set_valign(fa_bottom);
}

#endregion

page = ePAGE.NOT_FOUND;
client = undefined;

init_client();