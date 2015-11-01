require "chronic"
require "redcarpet"
require "sinatra"
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "lib/errors"
require "lib/parse"

get "/" do
  erb :index
end

post "/" do
  if params[:tsv_data]
    if params[:tsv_data][:type] == "text/tab-separated-values"
      parser = DataParser.new
      filename = parser.export_filename
      parser.prepare_file! filename, parser.prepare_data(params)
      send_file filename, type: "text/comma-separated-values", disposition: "attachment"
    else
      Errors.new.need_tsv
    end
  else
    Errors.new.no_file
  end
end

def markdown(str = "")
  Redcarpet::Markdown.new(Redcarpet::Render::HTML).render str.to_s
end
