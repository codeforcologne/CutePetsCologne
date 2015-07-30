cheerio = require 'cheerio'
request = require 'request'
express = require 'express'
NodeCache = require 'node-cache'
fs = require 'fs'

app = express()
cache = new NodeCache()

tierfreunde_url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not"
tierfreunde_splitpos = tierfreunde_url.lastIndexOf '/'
tierfreunde_base_url = tierfreunde_url.slice 0, tierfreunde_splitpos+1

tierschutz_url = "http://www.tierschutz-chemnitz.de/vm_hunde.php"
tierschutz_splitpos = tierschutz_url.lastIndexOf '/'
tierschutz_base_url = tierschutz_url.slice 0, tierschutz_splitpos+1

get_tierfreunde = (url)->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                r err
            $ = cheerio.load body
            content = $('#content')
            name = content.find('h1').text()
            img = content.find('img').attr('src')
            pic = tierfreunde_base_url + content.find('img').attr('src')
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

get_tierfreundeUrls = (url) ->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                r err
            urls = []
            $ = cheerio.load body
            $('.teaser-subline').each ->
                elem = $(this)
                detail_url = tierfreunde_base_url + elem.find('.teaser-image').find('a').attr('href')
                urls.push detail_url
            f urls

get_tierschutzUrls = (url) ->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                console.error err
                r err
                return
            urls = []
            $ = cheerio.load body
            $('td', 'table', '#center').each ->
                elem = $(this)
                if elem.attr 'colspan'
                    return
                else
                    detail_url = tierschutz_base_url + elem.find('a').attr('href')
                    urls.push detail_url
                    return
            f urls

get_data = ->
    new Promise (f, r) ->
        values = cache.get('tiere')
        if not values
            console.log "no cache"
            get_tierfreundeUrls tierfreunde_url
                .then (urls) ->
                    p = []
                    for url in urls
                        p.push get_tierfreunde url
                    Promise.all p
                .then (values) ->
                    cache.set('tiere', values, 60*60*24)
                    f values
                .catch (err) ->
                    r err
        else
            f values

# get a pet that was not posted yet
get_notPostedPet = ->
    new Promise (f, r) ->
        filename = '/var/cache/petschemnitz/posted_pets.json'
        try
            if fs.existsSync(filename)
                postedPets = JSON.parse fs.readFileSync filename, 'utf8'
            else
                fs.writeFileSync filename, JSON.stringify []
                postedPets = []
        catch err
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


get_tierschutzUrls(tierschutz_url).then (values) ->
    console.log values
###
get_notPostedPet().then (pet) ->
    console.log pet
###
###
# Return all pets
app.get '/', (req, res) ->
    get_data()
        .then (pets) ->
            res.json pets
        .catch (err) ->
            console.error err
            res.status(500).json(err)

# Return a random pet
app.get '/random', (req, res) ->
    get_notPostedPet()
        .then (pet) ->
            res.json pet
        .catch (err) ->
            console.error err
            res.status(500).json(err)

server = app.listen 3000, 'localhost', ->
    host = server.address().address
    host = if host.match /:/ then "[#{host}]" else host
    port = server.address().port
    console.log 'Listening at http://%s:%s', host, port
###
