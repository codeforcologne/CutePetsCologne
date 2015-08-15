cheerio = require 'cheerio'
request = require 'request'
express = require 'express'
NodeCache = require 'node-cache'
fs = require 'fs'
_ = require 'underscore'

app = express()
cache = new NodeCache()

tierfreunde_url = "http://www.tierheim-koeln-zollstock.de/tiervermittlung/katzen.html"
zollstock_urls = ["http://www.tierheim-koeln-zollstock.de/tiervermittlung/katzen.html",
              "http://www.tierheim-koeln-zollstock.de/tiervermittlung/hunde.html",
              "http://www.tierheim-koeln-zollstock.de/tiervermittlung/nagetiere.html"];
tierfreunde_base_url = "http://www.tierheim-koeln-zollstock.de/"

tierschutz_url = "http://www.tierschutz-chemnitz.de/vm_hunde.php"
tierschutz_splitpos = tierschutz_url.lastIndexOf '/'
tierschutz_base_url = tierschutz_url.slice 0, tierschutz_splitpos+1

get_zollstock_tier = (url)->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                r err
            $ = cheerio.load body
            content = $('.animalDetail')
            name = content.find('h1').text()
            img = content.find('.lightbox-image').attr('href')
            pic = tierfreunde_base_url + img
            id = content.find('h1').attr('id')
            content.find('h1').remove()
            content.find('a').remove()
            details =
                id: id
                pic: encodeURI pic
                name: name
                link: url
                desc: content.find('.animalDescription p')
                    .text().replace(/\n/g, '')
                    .replace(/\r/g, '')
                    .replace(/\t/g, '')
                    .trim()
            f details

get_zollstock_urls = (url) ->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                r err
            urls = []
            $ = cheerio.load body
            $('.animalOverviewItem').each ->
                elem = $(this)
                detail_url = tierfreunde_base_url + elem.find('.more').attr('href')
                console.log(detail_url)
                urls.push detail_url
            f urls

get_tierschutz = (url) ->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                r err
            $ = cheerio.load body
            content = $('table')
            name = content.find('.Stil2').text().replace /"/g, ''
            img = content.find('img').attr('src')
            pic = tierschutz_base_url + 'vermittlung/' + content.find('img').attr('src')
            id = img.split '.', 1
            id = id[0].split '/'
            content.find('.Stil2').remove()
            content.find('p').first().remove()
            content.find('p').last().remove()
            content.find('p').each ->
                elem = $(this)
                elem.remove() if elem.text().trim().split(/\s+/).length < 10
                elem.remove() if /^-/.test elem.text().trim()
            details =
                id: id[-1..][0]
                pic: encodeURI pic
                name: name
                link: url
                desc: content.find('.Stil1')
                    .text().replace(/\n/g, '')
                    .replace(/\r/g, '')
                    .replace(/\t/g, '')
                    .trim()
            f details

get_tierschutzUrls = (url) ->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                console.error err
                r err
            urls = []
            $ = cheerio.load body
            $('td', '#center').each ->
                elem = $(this)
                if elem.attr 'colspan' is undefined
                    href = elem.find('a').attr('href')
                    if href isnt undefined and /^vermittlung/.test href
                        detail_url = tierschutz_base_url + href
                        urls.push detail_url
            f urls

get_zollstockdata = (tier_url)->
    new Promise (f, r) ->
          get_zollstock_urls tier_url
              .then (urls) ->
                  p = []
                  for url in urls
                      p.push get_zollstock_tier url
                  Promise.all p
              .then (values) ->
                  f values
              .catch (err) ->
                  r err

get_tierschutzdata = ->
    new Promise (f, r) ->
        get_tierschutzUrls tierschutz_url
            .then (urls) ->
                p = []
                for url in urls
                    p.push get_tierschutz url
                Promise.all p
            .then (values) ->
                f values
            .catch (err) ->
                r err

get_data = ->
    new Promise (f ,r) ->
        #values = cache.get('tiere')
        #if not values
            #Promise.all [get_tierschutzdata(), get_tierfreundedata()]
            #Promise.all [ get_tierfreundedata()]
            p = []
            for url in zollstock_urls
                p.push get_zollstockdata url
            Promise.all p
                .then (list_of_values) ->
                    values = _.union.apply null, list_of_values
                    cache.set('tiere', values, 60*60*24)
                    f values
                .catch (err) ->
                    r err
        #else
        #    f values

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

###
get_data().then (values) ->
    console.log values.length
get_notPostedPet().then (pet) ->
    console.log pet
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
