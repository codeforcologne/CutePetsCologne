cheerio = require 'cheerio'
request = require 'request'
express = require 'express'
fs = require 'fs'

app = express()

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
            pic = base_url + content.find('img').attr('src')
            content.find('h1').remove()
            content.find('a').remove()
            details =
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

tiere = get_detailUrls tierheim_url
    .then (urls) ->
        p = []
        for url in urls
            p.push get_details url
        Promise.all p

###
tiere.then (values) ->
    console.log values
###

app.get '/', (req, rep) ->
    tiere.then (values) ->
        #console.log values
        rep.json values

app.get '/random', (req, rep) ->
    tiere.then (values) ->
        random = Math.ceil Math.random()*values.length-1
        console.log random
        rep.json values[random]

server = app.listen 3000, ->
    host = server.address().address
    host = if host.match /:/ then "[#{host}]" else host
    port = server.address().port
    console.log 'Listening at http://%s:%s', host, port
