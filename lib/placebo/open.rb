require 'open-uri'
# require 'httpclient'

def read_source(path)
  if !path.start_with?('http')
    File.read path
  else
    # httpc = HTTPClient.new
    # r = httpc.get(path)
    # r.read
    open(path).read
  end
end
