require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?
require 'redcarpet'
require 'pry'

# for esoteric reasons, this is the best/preferred means of establishing the absolute path name
root = File.expand_path("..", __FILE__)

configure do
  enable :sessions
  set :session_secret, "32ab0485ddc0875ddf7b3baf1d1ef175899de111a86b4d49d6d5447e9530e516"
end

get '/' do
  # we could have gone with 'root + /data/*' but File.join changes path
  # separator (e.g. / or \ ) depending on OS (Windows uses \)
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path) # returns: ["history.txt", "about.md", "changes.txt"]
  end
  erb :index
end

get '/new' do
  require_signed_in_user

  erb :new
end

post "/create" do
  require_signed_in_user

  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  if params[:username] == 'admin' && params[:password] == 'secret'
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect '/'
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session[:username] = nil
  session[:message] = "You have been signed out."

  redirect '/'
end

get '/:filename' do
  file_path = File.join(data_path, params[:filename])

  if File.file?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect '/'
  end
end

post '/:filename' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  File.write(file_path, params[:content])

  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

get '/:filename/edit' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])

  @filename = params[:filename]
  @content = File.read(file_path)

  erb :edit
end

post '/:filename/delete' do
  require_signed_in_user
  
  file_path = File.join(data_path, params[:filename])

  File.delete(file_path)

  session[:message] = "#{params[:filename]} has been deleted."

  redirect '/'
end

def render_markdown(markdown_text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(markdown_text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers['Content-Type'] = 'text/plain'
    content
  when ".md"
    erb render_markdown(content)
  end
end

# allows us to set different root variable depending on whether a test or development
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect '/'
  end
end