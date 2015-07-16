
# Promises mit Q https://www.npmjs.com/package/q

cheerio = require 'cheerio'
request = require 'request'
Q = require 'q'

url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not"
splitpos = url.lastIndexOf '/'
base_url = url.slice 0, splitpos+1

get_details = (url) ->
  deferred = Q.defer()
  request url, (err, response, body) ->
    $ = cheerio.load body
    name = $('.shady').find('h1').text()
    $('.shady').find('h1').remove()
    details =
      pic: base_url + $('.shady').find('img').attr('src')
      name: name
      url: url
      desc: $('.shady').text()

    deferred.resolve details

  deferred.promise

get_detailUrls = () ->
  deferred = Q.defer()
  request url, (err, response, body) ->
    if err
      console.error err
      throw err
      return

    urls = []
    $ = cheerio.load body
    $('.teaser-subline').each ->
      elem = $(this)
      detail_url = base_url + elem.find('.teaser-image').find('a').attr('href')
      urls.push detail_url
      return

    deferred.resolve urls;

  deferred.promise


get_alleDaten = (urls) ->
  p = []
  for url in urls[..2]
    p.push get_details url

  Q.all(p)


Q.fcall get_detailUrls
  .then get_alleDaten
  .then (daten) ->
    console.log "ERGEBNIS", daten

###
      tier =
        name: elem.find('h3').text()
        url: detail_url
        pic: base_url + get_details detail_url
        desc: elem.children().last().text()
      tiere.push tier
###

console.log "EOS"
