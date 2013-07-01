require "hallon"
require "sinatra/base"
require "sinatra/assetpack"
require "rack/parser"
require "pusher"
require "json"
require "./player"



def tracksToObj(tracks)
	result = []
	tracks.each do |track|
		track.load
		result << {
			artist: track.artist.name,
			album: track.album.name,
			duration: track.duration,
			name: track.name,
			link: track._to_link(0).to_uri(50)		
		}
	end
	result
end


class App < Sinatra::Base

	session = Hallon::Session.initialize ENV['SPOTIFY_KEY']
	details = ENV['SPOTIFY_AUTH'].split(":")
	session.login!(details[0],details[1])
	puts "Logged in!"
	playlist = Hallon::Playlist.new(ENV['SPOTIFY_PLAYLIST']).load
	player = Player::Player.new playlist

	Pusher.app_id = ENV['PUSHER_APP_ID']
	Pusher.key = ENV['PUSHER_KEY']
	Pusher.secret = ENV['PUSHER_SECRET']

	callback = Proc.new {
		Pusher['spot'].trigger('playlist',tracksToObj(playlist.tracks))
	}

	playlist.on(:tracks_added) { callback.call }
	playlist.on(:tracks_moved) { callback.call }
	playlist.on(:tracks_removed) { callback.call }

	set :root, File.dirname(__FILE__)

	register Sinatra::AssetPack
	use Rack::Parser

	assets {
		serve "/js", from: "app/js"
		serve "/css", from: "app/css"
		serve "/font", from: "app/font"
		
		js :app, [
			'/js/vendor/*.js',
			'/js/*.js'
		]

	    css :application, [
	    	'/css/vendor/*.css',
	    	'/css/*.css'
	    ]

	    js_compression  :jsmin    # :jsmin | :yui | :closure | :uglify
	    css_compression :simple   # :simple | :sass | :yui | :sqwish
	}

	get "/playlist" do
		playlist.load
		tracksToObj(playlist.tracks).to_json
	end

	post "/playlist/:id/:method" do
		id = Integer params[:id]
		if params[:method] == "up" then player.upvote(id)
		elsif params[:method] == "down" then player.downvote(id)
		end
		
	end 

	post "/playlist/:method" do
		if params[:method] == "play"
			player.play()
		elsif params[:method] == "pause"
			player.pause()
		end
		Pusher['spot'].trigger('status',player.status().to_s)
	end
	get "/status" do
		player.status().to_s
	end
	post "/search" do
		content_type :json
		if params[:query] != ""
			tracksToObj(Hallon::Search.new(params[:query]).load.tracks).to_json
		end
	end

	post "/add" do
		uri = params[:uri]
		track = Hallon::Track.new(uri).load
		player.add track
	end

	get '/*' do
		haml :index
	end

	run!
end


