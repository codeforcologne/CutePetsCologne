cheerio = require 'cheerio'
request = require 'request'

tierheim_url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not"
splitpos = tierheim_url.lastIndexOf '/'
base_url = tierheim_url.slice 0, splitpos+1

get_details = (url)->
  new Promise (fulfill, reject) ->
    request url, (err, response, body) ->
      if err
        console.error err
        reject err
        return
      $ = cheerio.load body
      name = $('.shady').find('h1').text()
      $('.shady').find('h1').remove()
      details =
        pic: base_url + $('.shady').find('img').attr('src')
        name: name
        url: url
        desc: $('.shady').text()
      fulfill details

get_detailUrls = (url) ->
  new Promise (fulfill, reject) ->
    request url, (err, response, body) ->
      if err
        reject err
        return
      urls = []
      $ = cheerio.load body
      $('.teaser-subline').each ->
        elem = $(this)
        detail_url = base_url + elem.find('.teaser-image').find('a').attr('href')
        urls.push detail_url
        return
      fulfill urls

get_detailUrls tierheim_url
  .then (urls) ->
    p = []
    for url in urls[..1]
      p.push get_details url
    Promise.all p
  .then (values) ->
    console.log values
  .catch (err) ->
    console.error err
