/// @description ...
// @author Kirill Zhosul (@kirillzhosul)


function sPublisher() constructor{
	// Implements simple Publisher - Subscriber pattern.
	
	// Subscribed callback functions.
	self.__subscribers = [];
	
	self.subscribe = function(subscriber){
		// @description Subscribes on publisher.
		// @param {function} subscriber_function Function to subscribe.
		
		// May be unsafe!...
		subscriber = typeof(subscriber) == "struct" ? subscriber : new sSubscriber(subscriber);
		array_push(self.__subscribers, subscriber);
	}
	
	self.notify = function(args){
		// @description Triggers (invoking) all subscribers.
		// @param {any} args Data Transfer Object*.
		
		for(var subscriber_index = 0;subscriber_index < array_length(self.__subscribers);subscriber_index++){
			self.__subscribers[subscriber_index].on_notify(args);
		}
	}
}

function sSubscriber(callback) constructor{
	self.__callback_function = callback;
	self.on_notify = function(args){
		self.__callback_function(args);
	}
}
