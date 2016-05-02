require 'json'

class Hashtag
  FILE = "lib/hashtags.json"

  def hashtags
      JSON.parse(File.read(FILE, :external_encoding => 'utf-8',))
  end

  def random
      hashtags.sample
  end
end
