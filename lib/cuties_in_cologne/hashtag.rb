require 'json'

class Hashtag
  FILE = "lib/hashtags.json"

  def hashtags
      JSON.parse(IO.read(FILE))
  end

  def random
      hashtags.sample
  end
end