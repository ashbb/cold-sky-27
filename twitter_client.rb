# twitter_client.rb
require 'sinatra'
require 'net/http'
require 'rexml/document'
require 'cgi'
require 'xml'

HOST = 'twitter.com'
PORT = 80
PATH = '/statuses/friends_timeline.xml'

Twitter = Struct.new :name, :screen_name, :location, :avatar, :text, :created_at

get '/' do
  authentification
end

post '/init' do
  @@id, @@pw = params[:id], params[:pw]
  get_friends_timeline
end

post '/posting' do
  post_update params[:str]
  get_friends_timeline
end

post '/page' do
  get_friends_timeline params[:str]
end

def get_friends_timeline n = nil
  Net::HTTP.version_1_2
  req = Net::HTTP::Get.new(n ? PATH + "?page=#{n}" : PATH)
  req.basic_auth @@id, @@pw
  xml = ''
  Net::HTTP.start(HOST, PORT) {|http| xml << http.request(req).body}
  
  twitters = []
  REXML::Document.new(xml).elements.each('statuses/status') do |e|
    twitters << Twitter.new(e.text('user/name'),
                                      e.text('user/screen_name'),
                                      e.text('user/location'),
                                      e.text('user/profile_image_url'),
                                      e.text('text').delete("\n"),
                                      e.text('created_at'))
  end
  xml_gen twitters
end

def xml_gen twitters
  XML.generate do
    html do
      body do
        form :action => '/posting', :method => 'post', :'accept-charset' => 'utf-8' do
          input :type => 'text', :name => 'str', :maxlength => 140, :size => 140
          input :type => 'submit', :value => 'post'
        end
        
        twitters.each do |tw|
          img :src => tw.avatar, :alt => tw.name, :width => 25, :height => 25
          font(:color => 'blue'){' ' + tw.screen_name}
          content [" : " , tw.text]
          br
          content tw.created_at
          br
          br
        end
      
        form :action => '/page', :method => 'post',  :'accept-charset' => 'utf-8' do
          input :type => 'text', :name => 'str', :maxlength => 3, :size => 3
          input :type => 'submit', :value => 'page'
        end
      end
    end
  end
end

def post_update data
  return unless data
  data = CGI.escape data
  Net::HTTP.version_1_2
  req = Net::HTTP::Post.new("http://twitter.com/statuses/update.xml?status=#{data}") 
  req.basic_auth @@id, @@pw
  xml = ''
  Net::HTTP.start(HOST, PORT) {|http| xml << http.request(req).body}
  xml
end

def authentification
  XML.generate do
    http do
      body do
        content 'Twitter Client v0.2'
        form :action => '/init', :method => 'post', :'accept-charset' => 'utf-8' do
          content 'User name: '
          input :type => 'text', :name => 'id'
          content 'Password : '
          input :type => 'password', :name =>'pw'
          input :type => 'submit', :value => 'ok'
        end
      end
    end
  end
end
