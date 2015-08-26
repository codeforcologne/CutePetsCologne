require "net/http"
require 'json'
require 'open-uri'

class AdoptAPet
  URL = 'http://127.0.0.1:3000'

  def self.random
    pet = fetch_pet while pet.nil? || pet.error?
    pet
  end

  private
  def self.fetch_pet
    json = JSON.parse(Net::HTTP.get_response(URI.parse(URL)).body)
    puts json.first
    data = {}
    json.count.times do |p|
      data = json.sample
      if not data[:desc].nil?
        break
      end
    end
    Pet.new(data)
  end
end
