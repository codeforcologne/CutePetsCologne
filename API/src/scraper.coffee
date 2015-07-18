cheerio = require 'cheerio'
request = require 'request'
express = require 'express'
NodeCache = require 'node-cache'
fs = require 'fs'

app = express()
cache = new NodeCache()

tierheim_url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not"
splitpos = tierheim_url.lastIndexOf '/'
base_url = tierheim_url.slice 0, splitpos+1

# Get details for one pet
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
                link: url
                desc: content
                    .text().replace(/\n/g, '')
                    .replace(/\r/g, '')
                    .replace(/\t/g, '')
                    .trim()
            f details

# Get all urls for pets
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

# Get the data from cache or save data in cache if data is none
# cache lifetime: 24h
get_data = ->
    new Promise (f, r) ->
        values = cache.get('tiere')
        if not values
            #console.log "no cache"
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
            #console.log "cache"
            f values

# get a pet that was not posted yet
get_notPostedPet = ->
    new Promise (f, r) ->
        filename = 'posted_pets.json'
        try
            if fs.existsSync(filename)
                postedPets = JSON.parse fs.readFileSync filename, 'utf8'
            else
                fs.writeFileSync filename, JSON.stringify []
                postedPets = []
        catch err
            console.error err
            r err
        get_data().then (pets) ->
            notPostedPets = []
            for pet in pets
                if pet.id not in postedPets
                    notPostedPets.push pet
            if notPostedPets.length is 0
                notPostedPets = pets
                postedPets = []
            random = Math.ceil Math.random()*notPostedPets.length-1
            notPostedPet = notPostedPets[random]
            postedPets.push notPostedPet.id
            fs.writeFileSync filename, JSON.stringify postedPets
            f notPostedPet

###
get_data().then (values) ->
    console.log values

get_notPostedPet().then (pet) ->
    console.log pet
###

# Return all pets
app.get '/', (req, rep) ->
    get_data().then (pets) ->
        #console.log values
        rep.json pets

# Return a random pet
app.get '/random', (req, rep) ->
    get_notPostedPet().then (pet) ->
        #console.log pet
        rep.json pet

server = app.listen 3000, 'localhost', ->
    host = server.address().address
    host = if host.match /:/ then "[#{host}]" else host
    port = server.address().port
    console.log 'Listening at http://%s:%s', host, port
