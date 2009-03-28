# twitter_client.rb
require 'sinatra'
require 'net/http'
require 'rexml/document'
require 'cgi'

HOST = 'twitter.com'
PORT = 80
PATH = '/statuses/friends_timeline.xml'
USER = 'ashbb'
PW = 'asakawa1'

Twitter = Struct.new :name, :screen_name, :location, :avatar, :text, :created_at

get '/' do
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
  req.basic_auth USER, PW
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
  
  result = %Q[<http><body>\
<form action='/posting' method='post' accept-charset='utf-8'>\
<input type='text' name='str' id='str' maxlength=140 size=140>\
<input type='submit' value='post'>\
</form><br>]

  page = %Q[<http><body>\
<form action='/page' method='post' accept-charset='utf-8'>\
<input type='text' name='str' id='str' maxlength=3 size=3>\
<input type='submit' value='page'>\
</form></body></http>]
  
  twitters.each do |tw|
    result << '<font color=blue>' << tw.screen_name << '</font> '
    result << '(' << tw.name << ') : '
    #result << tw.location << '<br>'
    result << tw.text << '<br>'
    result << tw.created_at << '<br><br>'
  end
  result << page
end

def post_update data
  return unless data
  data = CGI.escape data
  Net::HTTP.version_1_2
  req = Net::HTTP::Post.new("http://twitter.com/statuses/update.xml?status=#{data}") 
  req.basic_auth USER, PW
  xml = ''
  Net::HTTP.start(HOST, PORT) {|http| xml << http.request(req).body}
  xml
end
  