require "net/http"
require 'json'
require 'open-uri'

class AdoptAPet
  URL = 'http://127.0.0.1:3000/random'

  def self.random
    pet = fetch_pet while pet.nil? || pet.error?
    pet
  end

  private
  def self.fetch_pet
    Pet.new(JSON.parse(Net::HTTP.get_response(URI.parse(URL)).body))
  end
end
