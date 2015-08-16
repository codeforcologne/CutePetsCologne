cheerio = require 'cheerio'
request = require 'request'
express = require 'express'
NodeCache = require 'node-cache'
fs = require 'fs'
_ = require 'underscore'

app = express()
cache = new NodeCache()

zollstock_urls = ["http://www.tierheim-koeln-zollstock.de/tiervermittlung/katzen.html",
              "http://www.tierheim-koeln-zollstock.de/tiervermittlung/hunde.html",
              "http://www.tierheim-koeln-zollstock.de/tiervermittlung/nagetiere.html"];
zollstock_base_url = "http://www.tierheim-koeln-zollstock.de/"

dellbrueck_urls = ["http://presenter.comedius.de/design/bmt_koeln_standard_10001.php?f_mandant=bmt_koeln_d620d9faeeb43f717c893b5c818f1287&f_bereich=Vermittlung+kleine+Hunde+&f_funktion=Uebersicht",
              "http://presenter.comedius.de/design/bmt_koeln_standard_10001.php?f_mandant=bmt_koeln_d620d9faeeb43f717c893b5c818f1287&f_bereich=Vermittlung++mittelgro%DFe+Hunde+&f_funktion=Uebersicht",
              "http://presenter.comedius.de/design/bmt_koeln_standard_10001.php?f_mandant=bmt_koeln_d620d9faeeb43f717c893b5c818f1287&f_bereich=Vermittlung+gro%DFe+Hunde+&f_funktion=Uebersicht",
              "http://presenter.comedius.de/design/bmt_koeln_standard_10001.php?f_mandant=bmt_koeln_d620d9faeeb43f717c893b5c818f1287&f_bereich=Vermittlung+Katzen&f_funktion=Uebersicht",
              "http://presenter.comedius.de/design/bmt_koeln_standard_10001.php?f_mandant=bmt_koeln_d620d9faeeb43f717c893b5c818f1287&f_bereich=Vermittlung%2BKaninchen&f_funktion=Uebersicht",
              "http://presenter.comedius.de/design/bmt_koeln_standard_10001.php?f_mandant=bmt_koeln_d620d9faeeb43f717c893b5c818f1287&f_bereich=Vermittlung%2BMeerschweinchen&f_funktion=Uebersicht",
              "http://presenter.comedius.de/design/bmt_koeln_standard_10001.php?f_mandant=bmt_koeln2_d620d9faeeb43f717c893b5c818f1287&f_bereich=Degus%2Bund%2BChinchillas&f_funktion=Uebersicht"];
dellbrueck_base_url = "http://presenter.comedius.de/design/bmt_koeln_standard_10001.php"

get_zollstock_tier = (url)->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                r err
            $ = cheerio.load body
            content = $('.animalDetail')
            name = content.find('h1').text()
            img = content.find('.lightbox-image').attr('href')
            pic = zollstock_base_url + img
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
                detail_url = zollstock_base_url + elem.find('.more').attr('href')
                console.log(detail_url)
                urls.push detail_url
            f urls

get_dellbrueck_tier = (url)->
    new Promise (f, r) ->
        #console.log('\n' + url + '\n')
        request url, (err, response, body) ->
            if err
                r err
            $ = cheerio.load body
            content = $('p[style="font-family:Verdana;font-size:13px;font-style:normal;font-weight:normal;color:#756d58;vertical-align:top"]')
            name = content.find('b').text()
            img = $('#bild_0').attr('src')
            pic = zollstock_base_url + img
            start = url.indexOf("&f_aktueller_ds=");
            id = url.substr(start+16);
            end = id.indexOf("&");
            id = url.substr(0, end);
            content.find('b').remove()
            details =
                id: id
                pic: encodeURI pic
                name: name
                link: url
                desc: content
                    .text().replace(/\n/g, '')
                    .replace(/\r/g, '')
                    .replace(/\t/g, '')
                    .trim()
            f details

get_dellbrueck_sub_urls = (url) ->
    new Promise (f, r) ->
        request url, (err, response, body) ->
            if err
                r err
            sub_urls = []
            $ = cheerio.load body
            $('a#TextSeitenanzeige').each ->
                elem = $(this)
                detail_url = dellbrueck_base_url + elem.attr('href')
                sub_urls.push detail_url
            f sub_urls

get_dellbrueck_urls_for_page = (sub_url) ->
  new Promise (f, r) ->
    request sub_url, (err, response, body) ->
        if err
            r err
      #  console.log(sub_url)
        urls = []
        $ = cheerio.load body
        $('a[style="border-style:none;background-color:#ece9e2;vertical-align:top;font:normal 13px Verdana; color:#756d58"]').each ->
            elem = $(this)
            detail_url = dellbrueck_base_url + elem.attr('href')
            #console.log(detail_url)
            urls.push detail_url

        #console.log(urls.length)
        f urls


get_dellbrueck_urls = (url) ->
    new Promise (f, r) ->
            urls = []
            p = []
            get_dellbrueck_sub_urls url
                .then (sub_urls) ->
                    for sub_url in sub_urls
                      p.push get_dellbrueck_urls_for_page sub_url
                    Promise.all p
                      .then (tier_urls) ->
                        console.log(tier_urls.length)
                        for tier_url in tier_urls
                          console.log(tier_url)
                          urls.push tier_url
                  .then () ->
                    f urls
                  #    new Promise (f, r) ->
                  #      request sub_url, (err, response, body) ->
                  #          if err
                  #              r err
                  #          console.log(sub_url)
                  #          $ = cheerio.load body
                  #          $('a[style="border-style:none;background-color:#ece9e2;vertical-align:top;font:normal 13px Verdana; color:#756d58"]').each ->
                  #              elem = $(this)
                  #              detail_url = dellbrueck_base_url + elem.attr('href')
                  #              console.log(detail_url)
                  #              urls.push detail_url
              #  .then () ->
                #  console.log(urls.length)
                #  f urls

get_zollstockdata = (tier_url)->
    new Promise (f, r) ->
          get_zollstock_urls tier_url
              .then (urls) ->
                  p = []
                  for url in urls
                      console.log(url)
                      p.push get_zollstock_tier url
                  Promise.all p
              .then (values) ->
                  f values
              .catch (err) ->
                  r err

get_dellbrueckdata = (tier_url)->
    new Promise (f, r) ->
          get_dellbrueck_urls tier_url
              .then (urls) ->
                  console.log(urls.length)
                  p = []
                  for url in urls
                      p.push get_dellbrueck_tier url
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
          #  p2 = []
          #  for url in dellbrueck_urls
          #      p2.push get_dellbrueck_sub_urls url
          #  Promise.all p2
          #    .then (sub_urls) ->
          #      for sub_url in sub_urls
          #          p.push get_dellbrueckdata sub_url
          #  for url in zollstock_urls
          #      p.push get_zollstockdata url
            for url in dellbrueck_urls
                p.push get_dellbrueckdata url
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
