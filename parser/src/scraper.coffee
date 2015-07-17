cheerio = require 'cheerio'
request = require 'request'
express = require 'express'
NodeCache = require 'node-cache'

app = express()
cache = new NodeCache()

tierheim_url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not"
splitpos = tierheim_url.lastIndexOf '/'
base_url = tierheim_url.slice 0, splitpos+1

get_details = (url)->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                console.error err
                r err
                return
            $ = cheerio.load body
            content = $('#content')
            name = content.find('h1').text()
            img = content.find('img').attr('src')
            pic = base_url + content.find('img').attr('src')
            id = img.split '.', 1
            id = id[0].split '/'
            content.find('h1').remove()
            content.find('a').remove()
            details =
                id: id[-1..][0]
                pic: pic
                name: name
                url: url
                desc: content
                    .text().replace(/\n/g, '')
                    .replace(/\r/g, '')
                    .replace(/\t/g, '')
                    .trim()
            f details

get_detailUrls = (url) ->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                console.error err
                r err
                return
            urls = []
            $ = cheerio.load body
            $('.teaser-subline').each ->
                elem = $(this)
                detail_url = base_url + elem.find('.teaser-image').find('a').attr('href')
                urls.push detail_url
                return
            f urls

get_data = ->
    new Promise (f, r) ->
        values = cache.get('tiere')
        if not values
            console.log "no cache"
            get_detailUrls tierheim_url
                .then (urls) ->
                    p = []
                    for url in urls
                        p.push get_details url
                    Promise.all p
                .then (values) ->
                    cache.set('tiere', values, 60*60*24)
                    f values
        else
            console.log "cache"
            f values

###
get_data().then (values) ->
    console.log values
###

app.get '/', (req, rep) ->
    get_data().then (values) ->
        #console.log values
        rep.json values

app.get '/random', (req, rep) ->
    get_data().then (values) ->
        random = Math.ceil Math.random()*values.length-1
        #console.log random
        rep.json values[random]

server = app.listen 3000, ->
    host = server.address().address
    host = if host.match /:/ then "[#{host}]" else host
    port = server.address().port
    console.log 'Listening at http://%s:%s', host, port
