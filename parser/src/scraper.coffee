cheerio = require 'cheerio'
request = require 'request'

url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not"
splitpos = url.lastIndexOf '/'
base_url = url.slice 0, splitpos+1

get_details = (url, callback)->
  request url, (err, response, body) ->
    $ = cheerio.load body
    name = $('.shady').find('h1').text()
    $('.shady').find('h1').remove()
    details =
      pic: base_url + $('.shady').find('img').attr('src')
      name: name
      url: url
      desc: $('.shady').text()
    callback details

get_detailUrls = (callback) ->
  request url, (err, response, body) ->
    if err
      console.error err
      return
    urls = []
    $ = cheerio.load body
    $('.teaser-subline').each ->
      elem = $(this)
      detail_url = base_url + elem.find('.teaser-image').find('a').attr('href')
      urls.push detail_url
      return
    callback urls

get_detailUrls (urls) ->
  for url in urls
    get_details url, (details) ->
      console.log details

###
      tier =
        name: elem.find('h3').text()
        url: detail_url
        pic: base_url + get_details detail_url
        desc: elem.children().last().text()
      tiere.push tier
###
