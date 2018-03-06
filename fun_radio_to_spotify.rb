require './scraper.rb'
require 'rspotify'
require 'dotenv/load'
require 'thread'
require 'csv'
require 'active_support/core_ext/numeric/time.rb'

Thread.report_on_exception = false

class FunRadioToSpotify
    attr_reader :songs_csv_path
    attr_accessor :search_terms_not_found
    attr_reader :user
    attr_reader :playlist
    attr_reader :url
    attr_accessor :date

    def initialize(url, date, options={})
        @songs_csv_path = './songs.csv'
        @search_terms_not_found = Set.new
        @url = url
        @date = date

        # authentication with Spotify Web API
        RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])

        # get the playlist we're appending to
        @playlist = RSpotify::Playlist.find(ENV['SPOTIFY_USERNAME'], ENV['SPOTIFY_PLAYLIST_ID'])

        # load user + credentials from file
        user = RSpotify::User.find(ENV['SPOTIFY_USERNAME']).to_hash
        user['credentials'] = {'token' => ENV['SPOTIFY_TOKEN'], 'token_type': 'Bearer', 'expires_in': 3600}
        @user = RSpotify::User.new(user)

        at_exit {
            # replace token
            puts 'Write token to .env'
            `ruby -pi -e "gsub(/SPOTIFY_TOKEN.*/, 'SPOTIFY_TOKEN=#{@user.credentials['token']}')" .env`
        
            puts @search_terms_not_found.to_a
        }
    end

    def run(num_hours)
        while true
            print "\n\nDate: #{@date.to_date.strftime('%d/%m/%Y')}"

            # create an array with the ctkoi url and options to fetch data
            url_n_options = (num_hours*2).times.map {|i| d=@date+i*30.minutes; [@url, {date: d.to_date.strftime('%d/%m/%Y'), hour: d.hour, minute: d.minute}]}
            
            # scrape and remove previously seen tracks
            begin
                scraped = threaded_scraper(url_n_options)
            rescue
                next
            end
            old_songs, search_strings = remove_duplicates(scraped)

            @date -= 24.hours
            next if search_strings.empty?

            # overwrite search_strings to remove unfound songs on spotify
            new_songs, tracks = spotify_search_multiple(search_strings)
            tracks_were_added = add_tracks_to_playlist(tracks)

            @search_terms_not_found += search_strings.subtract(new_songs.to_set)
            
            # add tracks to CSV
            CSV.open(@songs_csv_path, 'w') { |csv| (old_songs + new_songs.to_set).to_a.each { |song| csv << [song] } } if tracks_were_added
        end
    end

    private
    # returns scraped songs
    def threaded_scraper(array_of_urls_and_options)
        threads, tracks = [], []

        for url, options in array_of_urls_and_options
            threads << Thread.new { Thread.current['tracks'] = Scraper.new(url, options).get_songs.uniq }
        end

        threads.each { |t| t.join; tracks << t['tracks'] unless t['tracks'].empty? }

        return tracks.flatten
    end

    def remove_duplicates(songs)
        old_songs = CSV.read(@songs_csv_path).flatten.to_set
        songs = songs.map {|s| "#{s[:title]} #{s[:artist].gsub(/\.|\&|\,\/|\bEt\b/,' ')}" }.to_set
        new_songs = songs.subtract(old_songs)
        new_songs = new_songs.subtract(@search_terms_not_found)
        return old_songs, new_songs
    end

    def spotify_search(search_string)
        begin
            RSpotify::Track.search(search_string).first
        rescue
        end
    end

    # returns array of [search_term, Track]
    def spotify_search_multiple(search_strings)
        threads, search_terms, tracks = [], [], []

        # get songs from Fun Radio, skip songs already added
        search_strings.each do |search_string|
            threads << Thread.new { Thread.current['track'] = spotify_search(search_string); Thread.current['search_string'] = search_string }
        end

        # collect all new tracks to add
        threads.each { |t| t.join; track = t['track']; search_terms << t['search_string'] unless track.nil?; tracks << track unless track.nil? }

        print "\tFound #{tracks.count} new track(s) on Spotify (#{search_strings.count} searched)\t"
        return search_terms, tracks
    end

    # try to add all discovered tracks to spotify, try again up to 10 times when it fails
    def add_tracks_to_playlist(tracks)
        added_tracks = false
        failures = 0
        while added_tracks == false && failures < 10
            begin
                @playlist.add_tracks! tracks unless tracks.empty?
                added_tracks = true
            rescue
                failures += 1
                puts 'FAILED TO ADD TRACKS TO SPOTIFY'
                sleep 5
            end
        end
        return added_tracks
    end
end

FunRadioToSpotify.new('http://www.funradio.fr/quel-est-ce-titre', DateTime.parse('2018-03-06T01:00:00-00:00')).run(4)