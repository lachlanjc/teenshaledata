require 'sinatra'
require 'better_errors'
require 'chronic'
require 'redcarpet'
require 'active_support/all'
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/errors'
require 'lib/parse'

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

get '/' do
  erb :index
end

post '/' do
  if params[:tsv_data]
    if params[:tsv_data][:type] == 'text/tab-separated-values'
      parser = DataParser.new
      path = parser.prepare_file!(params)
      name = path.split(/\//).last.to_s
      send_file path, type: 'text/comma-separated-values', filename: name
    else
      Errors.new.need_tsv
    end
  else
    Errors.new.no_file
  end
end

def markdown(str = '')
  Redcarpet::Markdown.new(Redcarpet::Render::HTML).render str.to_s
end
