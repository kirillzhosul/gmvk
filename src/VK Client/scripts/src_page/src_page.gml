/// @description Page structure.
// @author Kirill Zhosul (@kirillzhosul)

// WARNING!
// WARNING!

// This code is not refactored,
// THIS IS CODE IS NOT SAFE FOR READING.
// PLEASE MOVE KIDS AWAY FROM THE SCREEN.

// WARNING!
// WARNING!

enum ePAGE{
	AUTH_LOGIN,
	CLIENT_MESSENGER,
	CLIENT_USER_PROFILE
}

function sPage(initial_index) constructor{
	// Current page structure.
	// Used as encapsulated* container for current page.
	
	// Should be of type ePAGE.
	self.current_index = initial_index;
	
	// Cached data, cleared on changing page.
	self.cache =  new sCache();

	self.scroll = 0;
	
	self.change = function(to_index){
		// @description Changes page index to given, with clearing cache.
		// @param {ePAGE} to_index Index to change on.
		
		if (self.current_index == to_index) return;
		
		self.current_index = to_index;
		self.cache.clear();
	}
}
