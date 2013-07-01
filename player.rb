require "hallon"
require "hallon-openal"

module Player
	class Player
		def initialize(playlist)
			@player = Hallon::Player.new(Hallon::OpenAL)
			@playlist = playlist
			track = @playlist.tracks[0]
			track.load
			@player.play(track)
			@player.on(:end_of_track) do
				if @playlist.size
					@playlist.remove(0)
					if @playlist.size
						track = @playlist.tracks[0]
						@player.play(track)
					end
				end
			end
		end
		def play()
			@player.play()
		end
		def pause()
			@player.pause()
		end
		def status()
			@player.status
		end
		def add(track)
			@playlist.insert((@playlist.size or 0), track)
			@playlist.upload
		end
		def upvote(num)
			@playlist.move((num-1 or 0),num)
			@playlist.upload
		end
		def downvote(num)
			val = (num+2 or @playlist.size)
			@playlist.move(val,num)
			@playlist.upload
		end
	end
end