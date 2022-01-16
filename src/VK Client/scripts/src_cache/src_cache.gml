/// @description Cache structure.
// @author Kirill Zhosul (@kirillzhosul)

function sCache() constructor{
	// Cache structure.
	// Implements simple interface for working with cache.
	
	// Struct to hold values. Private.
	// Should there be used hash-map? (ds-map). Or I will still use objects.
	self.__cached = {};
	
	self.exists = function(key){
		// @description Returns is given key exists or not.
		// @param {string} key Cache key.
		// @returns {bool} Exists.
		
		return variable_struct_exists(self.__cached, key);
	}
	
	self.read = function(key){
		// @description Reads cache value.
		// @param {string} key Cache key.
		// @returns {any} Cache value.
		
		return variable_struct_get(self.__cached, key);
	}
	
	self.try_read = function(key, on_fail){
		// @description Reads cache value o returns `on_fail` value if it is no exists.
		// @param {string} key Cache key.
		// @param {any} on_fail Value that will be return when there is no key in cache.
		// @returns {any} Cache value.
		
		if (self.exists(key)) return self.read(key);
		return on_fail;
	}
	
	self.clear = function(){
		// @description Clears all cache.
		
		delete self.__cached;
		self.__cached = {};
	}
	
	self.remove = function(key){
		// @descrtiption Deletes cache value.
		// @param {string} key Cache key.
		
		variable_struct_remove(self.__cached, key);
	}
	self.write = function(key, value){
		// @descrtiption Writes cache value.
		// @param {string} key Cache key.
		// @param {any} value Cache value.
		
		variable_struct_set(self.__cached, key, value);
	}
}