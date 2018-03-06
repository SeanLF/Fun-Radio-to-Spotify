# Fun Radio to Spotify

This program does the following:

- scrape [fun radio ctkoi](http://funradio.fr/quel-est-ce-titre) for songs and artists
- searches the scraped data on Spotify
- adds the songs found on Spotify to a user's playlist
- keeps track of songs found to avoid adding duplicates to the playlist, and songs not found for manual insertion at a later date if desired

## Playlists
- [Fun Radio - Son Dancefloor](https://open.spotify.com/user/sfloy029/playlist/3s15Dxa4QJ9RuH4eOpsC7u?si=MSbEFMp9RBOXvMP4XlZn6w) (songs played from 1h to 5h over the last few months)
- [Fun Radio](https://open.spotify.com/user/sfloy029/playlist/5qChJ7pNbUZgKAXteLG2Hv?si=JbPbnm4lT1m8AL8h6Xo9ug) (all songs played in the last 3 months)

## Before running
- requires a [developer spotify account](https://beta.developer.spotify.com/)
    - create an app, get the client ID and secret key
- requires a spotify account
    - (optional) create a playlist
    - get the playlist ID of the playlist you want to add songs to
- open your browser and paste the following [http://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=token&redirect_uri=https:%2F%2FSOMEWEBSITEYOUTRUST%2Fcallback&scope=playlist-read-private%20playlist-read-collaborative%20playlist-modify-public%20playlist-modify-private](.)
    - sign in, as it will ask you to authorize your app with your spotify account
    - extract the client token from the redirected url
- create a `.env` file with the following

```.env
SPOTIFY_CLIENT_ID=xxxx
SPOTIFY_CLIENT_SECRET=xxxx
SPOTIFY_USERNAME=xxxx
SPOTIFY_PLAYLIST_ID=xxxx
SPOTIFY_TOKEN=xxxx
```

## Running

```bash
bundle install
ruby fun_radio_to_spotify.rb
```