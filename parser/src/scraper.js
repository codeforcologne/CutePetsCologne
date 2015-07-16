(function() {
  var Q, base_url, cheerio, get_alleDaten, get_detailUrls, get_details, request, splitpos, url;

  cheerio = require('cheerio');

  request = require('request');

  Q = require('q');

  url = "http://www.tierfreunde-helfen.de/index.php?zuhausegesucht-tiere-in-not";

  splitpos = url.lastIndexOf('/');

  base_url = url.slice(0, splitpos + 1);

  get_details = function(url) {
    var deferred;
    deferred = Q.defer();
    request(url, function(err, response, body) {
      var $, details, name;
      $ = cheerio.load(body);
      name = $('.shady').find('h1').text();
      $('.shady').find('h1').remove();
      details = {
        pic: base_url + $('.shady').find('img').attr('src'),
        name: name,
        url: url,
        desc: $('.shady').text()
      };
      return deferred.resolve(details);
    });
    return deferred.promise;
  };

  get_detailUrls = function() {
    var deferred;
    deferred = Q.defer();
    request(url, function(err, response, body) {
      var $, urls;
      if (err) {
        console.error(err);
        throw err;
        return;
      }
      urls = [];
      $ = cheerio.load(body);
      $('.teaser-subline').each(function() {
        var detail_url, elem;
        elem = $(this);
        detail_url = base_url + elem.find('.teaser-image').find('a').attr('href');
        urls.push(detail_url);
      });
      return deferred.resolve(urls);
    });
    return deferred.promise;
  };

  get_alleDaten = function(urls) {
    var p, _i, _len, _ref;
    p = [];
    _ref = urls.slice(0, 3);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      url = _ref[_i];
      p.push(get_details(url));
    }
    return Q.all(p);
  };

  Q.fcall(get_detailUrls).then(get_alleDaten).then(function(daten) {
    return console.log("ERGEBNIS", daten);
  });


  /*
        tier =
          name: elem.find('h3').text()
          url: detail_url
          pic: base_url + get_details detail_url
          desc: elem.children().last().text()
        tiere.push tier
   */

  console.log("EOS");

}).call(this);
