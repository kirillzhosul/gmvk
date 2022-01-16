/// @description Interface functions.
// @author Kirill Zhosul (@kirillzhosul)

// WARNING!
// WARNING!

// This code is not refactored,
// THIS IS CODE IS NOT SAFE FOR READING.
// PLEASE MOVE KIDS AWAY FROM THE SCREEN.

// WARNING!
// WARNING

#macro REGION_DEBUG_OUTLINE false

function draw_button_text(x, y, text, hovered_background_color){
	// @description Draws text as button, and returns it is clicked or not.
	// @param {real} x X to draw at.
	// @param {real} y Y to draw at.
	// @param {string} text Text to draw.
	// @param {color} hovered_background_color Color of the background tint 10% alpha.
	
	var default_color = draw_get_color();
	
	var x2 = x + string_width(text);
	var y2 = y + string_height(text);
	
	if (REGION_DEBUG_OUTLINE){
		draw_set_color(c_red);
		draw_roundrect(x, y, x2, y2, true);
		draw_set_color(default_color);
	}
	
	var is_hovered = point_in_rectangle(mouse_x, mouse_y, x, y, x2, y2);
	var is_clicked = is_hovered ? mouse_check_button_pressed(mb_left) : false;
	
	if (is_hovered){
		var default_alpha = draw_get_alpha();
		draw_set_alpha(0.1);
		draw_set_color(hovered_background_color);
		draw_roundrect(x, y, x2, y2, false);
		draw_set_alpha(default_alpha);
	}
	
	draw_set_color(default_color);
	draw_text(x, y, text);
	
	return is_clicked;
}

function draw_button_text_aligned(x, y, text, hovered_background_color, align_x, align_y){
	// @description Draws text as button, and returns it is clicked or not.
	// @param {real} x X to draw at.
	// @param {real} y Y to draw at.
	// @param {string} text Text to draw.
	// @param {color} hovered_background_color Color of the background tint 10% alpha.
	// @param {real} align_x Y to align.
	// @param {real} align_y Y to align.
	
	var default_color = draw_get_color();
	
	var text_x = x;
	var text_y = y;
	
	var x2 = x + align_x;
	var y2 = y + align_y;
	
	if (x2 < x){
		var t = x;
		x = x2;
		x2 = t;
	}
	
	if (y2 < y){
		var t = y;
		y = y2;
		y2 = t;
	}
	
	if (REGION_DEBUG_OUTLINE){
		draw_set_color(c_red);
		draw_roundrect(x, y, x2, y2, true);
		draw_set_color(default_color);
	}
	
	var is_hovered = point_in_rectangle(mouse_x, mouse_y, x, y, x2, y2);
	var is_clicked = is_hovered ? mouse_check_button_pressed(mb_left) : false;
	
	if (is_hovered){
		var default_alpha = draw_get_alpha();
		draw_set_alpha(0.1);
		draw_set_color(hovered_background_color);
		draw_roundrect(x, y, x2, y2, false);
		draw_set_alpha(default_alpha);
	}
	
	draw_set_color(default_color);
	draw_text(text_x, text_y, text);
	
	return is_clicked;
}

function draw_text_centered(x, y, text){
	// @description Draws centered text.
	// @param {real} x X to draw at.
	// @param {real} y Y to draw ay.
	// @param {string} text Text to draw.
	
	draw_text(x - string_width(text) / 2, y - string_height(text) / 2, text);
}

function draw_rectangle_outline(x1, y1, x2, y2, color_body, color_outline){
	// @decsription Draw rectangle with outline.
	// @param {real} x1 Left X.
	// @param {real} y1 Up Y.
	// @param {real} x2 Right X.
	// @param {real} y2 Bottom Y.
	// @param {color} color_body Color of the body to draw.
	// @param {color} color_outline Color of the outline to draw.
	
	var default_color = draw_get_color();
	draw_set_color(color_body);
	draw_rectangle(x1, y1, x2, y2, false);
	draw_set_color(color_outline);
	draw_rectangle(x1, y1, x2, y2, true);
	draw_set_color(default_color);
}

function draw_button_region(x1, y1, x2, y2, hovered_background_color){
	// @decsription Draw region as button, and returns is clicked or not.
	// @param {real} x1 Left X.
	// @param {real} y1 Up Y.
	// @param {real} x2 Right X.
	// @param {real} y2 Bottom Y.
	// @param {color} hovered_background_color Color of the background tint 10% alpha.
	
	var default_color = draw_get_color();
	
	if (REGION_DEBUG_OUTLINE){
		draw_set_color(c_red);
		draw_roundrect(x1, y1, x2, y2, true);
		draw_set_color(default_color);
	}
	
	var is_hovered = point_in_rectangle(mouse_x, mouse_y, x1, y1, x2, y2);
	if (is_hovered){
		var default_alpha = draw_get_alpha();
		draw_set_alpha(0.1);
		draw_set_color(hovered_background_color);
		draw_roundrect(x1, y1, x2, y2, false);
		draw_set_alpha(default_alpha);
		return mouse_check_button_pressed(mb_left);
	}
	
	return false;
}

function draw_sprite_rounded(sprite, subimg, x, y){
	
	var w = sprite_get_width(sprite);
	var h = sprite_get_height(sprite);
	
	var surface = surface_create(w, h);
	surface_set_target(surface);
	{
		draw_sprite(sprite, subimg, 0, 0);
	}
	surface_reset_target();
	
	var surface_cut = surface_create(w, h);
	surface_set_target(surface_cut);
	{
		draw_set_color(c_white);
		draw_rectangle(0, 0, w, h, false);
		
		gpu_set_blendmode(bm_subtract);
		
		draw_roundrect_ext(0, 0, w, h, w, h, false);
		
		draw_set_alpha(0.5);
		draw_roundrect_ext(0, 0, w, h, w, h, true);
		draw_set_alpha(1);
		
		gpu_set_blendmode(bm_normal);
	}
	surface_reset_target();
	
	surface_set_target(surface);
	{
		gpu_set_blendmode(bm_subtract);
		draw_surface(surface_cut, 0, 0);
		gpu_set_blendmode(bm_normal);
	}
	surface_reset_target();
	
	draw_surface(surface, x, y);
	surface_free(surface);
	surface_free(surface_cut);
	//gpu_set_texfilter(false);
}