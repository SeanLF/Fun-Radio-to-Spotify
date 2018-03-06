require 'HTTParty'
require 'Nokogiri'
require 'titleize'

class Scraper

    attr_accessor :parse_page

    def initialize(url, options={})
        if options == {}
            @parse_page ||= Nokogiri::HTML(HTTParty.get(url))
        else
            @parse_page ||= Nokogiri::HTML(HTTParty.post(url, query: options))
        end
    end

    def get_songs
        song_container.map {|c| {
            title: c.css('.timeline-media--music__title').text.titleize,
            artist: c.css('.timeline-media--music__artist').text.titleize
        }}
    end

    private 
    def song_container
        parse_page.css('.timeline-post.timeline-post--music .timeline-media--music__infos')
    end
end