require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?

# for esoteric reasons, this is the best/preferred means of establishing the absolute path name
root = File.expand_path("..", __FILE__)

before do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
end

get '/' do
  erb :index
end

get '/:filename' do
  file_path = root + "/data/" + params[:filename]

  headers['Content-Type'] = 'text/plain'
  File.read(file_path)
end