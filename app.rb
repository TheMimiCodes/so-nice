#!/usr/bin/env ruby
$LOAD_PATH.unshift 'lib'
$LOAD_PATH.unshift 'lib/players'

retried = false
begin
  require 'sinatra'
  require 'haml'
  require 'xmlsimple'
  require 'json'

  require 'open-uri'

  require 'artist_image'
  require 'player'

  require 'itunes_mac'
  require 'itunes_win'
  require 'mpd'
  require 'rhythmbox'

rescue LoadError => e
  raise if retried
  require 'rubygems'
  retried = true
  retry
end

enable :inline_templates
set :environment, ENV['RACK_ENV'] || :production

configure do
  set :controls, ENV['SONICE_CONTROLS'] != '0'
  $player = MusicPlayer.launched or abort "Error: no music player launched!"
end

post '/player' do
  return if !settings.controls
  params.each { |k, v| $player.send(k) if $player.respond_to?(k) }
  redirect '/'
end

get '/' do
  @title = $player.track
  @artist = $player.artist
  @album = $player.album
  @image_uri = ArtistImage.new(@artist).uri
  haml :index
end


__END__
@@ index
!!!
%html
  %head
    %title
      - if @artist
        = "#{@artist} &mdash; #{@title}"
      - else
        = @title
    %meta{'http-equiv' => 'Content-Type', :content => 'text/html; charset=utf-8'}
    %meta{'http-equiv' => 'Refresh', :content => 10}
    %link{:rel => 'stylesheet', :href => '/stylesheet.css', :type => 'text/css'}
  %body{:style => @image_uri ? "background-image:url(#{@image_uri})" : nil }
    %h1= @title
    - if @artist
      %h2= @artist
    - if @album
      %h3= @album

    - if settings.controls
      %form{:method => 'post', :action => 'player'}
        %p
          %input{:type=>'submit', :value => '▸', :name=>'playpause', :title => "Play/Pause"}
          %input{:type=>'submit', :value => '←', :name=>'prev',      :title => "Previous"}
          %input{:type=>'submit', :value => '→', :name=>'next',      :title => "Next"}
          %input{:type=>'submit', :value => '♪', :name=>'voldown',   :title => "Quieter"}
          %input{:type=>'submit', :value => '♫', :name=>'volup',     :title => "Louder"}

