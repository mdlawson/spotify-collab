App = angular.module "app", []

App.config ($httpProvider) ->
#	$httpProvider.defaults.headers.post['Content-Type'] = 'multipart/form-data'

App.controller "PlayerController", ($scope, SearchService, PlaylistService, PushService) ->
	$scope.query = ""
	$scope.results = []
	$scope.playlist = []
	$scope.playing = false
	holding = false
	statChange = (change) ->
		console.log change
		$scope.status = change
		if change is "playing"
			$scope.action = "pause"
		else
			$scope.action = "play"
	playlistChange = (data) -> 
		$scope.playlist = data
	PlaylistService.fetch().success playlistChange
	PlaylistService.status().success statChange
	PushService.on "status", statChange
	PushService.on "playlist", playlistChange

	$scope.search = ->
		SearchService.search($scope.query).success((results) ->
			$scope.results = results
		)
	$scope.toggle = ->
		PlaylistService[$scope.action]()
	$scope.add = (track) ->	
		PlaylistService.add(track)
		$scope.results = []
	$scope.press = (e,item) ->
		e.preventDefault()
		holding = true
		setTimeout ->
			if holding
				if e.button is 0
					alert("upboat")
					PlaylistService.upvote(item)
				else if e.button is 2
					alert("downboat")
					PlaylistService.downvote(item)
			holding = false
		, 1000
	$scope.release = ->
		holding = false


App.factory "PlaylistService", ($http) ->
	return {
		play: -> $http.post '/playlist/play'
		pause: -> $http.post '/playlist/pause'
		fetch: -> $http.get '/playlist'
		upvote: (num) -> $http.post "/playlist/#{num}/up"
		downvote: (num) -> $http.post "/playlist/#{num}/down"
		add: (track) -> $http.post "/add", {uri: track}
		status: -> $http.get "/status"
	}

App.factory "SearchService", ($http) ->
	return {
		search: (query) -> $http.post '/search', {query: query}
	}

App.factory "PushService", ($rootScope) ->
	pusher = new Pusher('e2d83dd45546b5fd99b4')
	channel = pusher.subscribe('spot')
	return {
		on: (ev,cb) ->
			channel.bind ev, ->
				args = arguments
				$rootScope.$apply -> cb.apply(channel,args)
	}

