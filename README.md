# CutePetsChemnitz

Post an random pet from shelter [Chemnitz (OT Röhrsdorf)](http://www.tierfreunde-helfen.de/) on Twitter [@petschemnitz](https://twitter.com/petschemnitz)

## About

Originated as a project of [Team Denver](http://codeforamerica.org/cities/denver/) during the 2014 fellowship at Code for America.
Originally specific to Denver, it's been redeployed by a few cities. Check out [this twitter list](https://twitter.com/drewSaysGoVeg/cutepetseverywhere/members) to see where.


**Links to Bot**

* [Twitter bot](https://twitter.com/petschemnitz)

## Setup & Deployment

I've deployed it on my Raspberry PI running Rasbian ;)

Using user `pi`

### iojs
```
cd ~
wget https://iojs.org/dist/v2.3.4/iojs-v2.3.4-linux-armv6l.tar.xz
tar xf iojs-v2.3.4-linux-armv6l.tar.xz
export PATH=/home/pi/iojs-v2.3.4-linux-armv6l/bin:$PATH
```

### ruby
```
sudo apt-get install ruby ruby-dev rake
sudo gem install bundler
```

### Repo
```
cd /opt/
git clone https://github.com/CodeforChemnitz/CutePetsChemnitz.git
cd CutePetsChemnitz
```

### API

The API is available via http://127.0.0.1:3000/

#### Install
```
cd API
npm install
npm run build
```

#### Run
```
node lib/scraper.js
```

#### Deploy
```
sudo ln -s /opt/CutePetsChemnitz/API/petschemnitz /etc/init.d
sudo update-rc.d petschemnitz defaults
sudo mkdir /var/cache/petschemnitz
sudo service petschemnitz start
```

### Twitter
1. Create a new [twitter app](https://apps.twitter.com/).
1. On the API key tab for the Twitter app, modify permissions so the app can **Read and Write**.
1. Create an access token. On the API Key tab in Twitter for the app, click **Create my access token**
1. Take note of the values for environment set up below.
*Note:* It's important to change permissions to Read/Write before generating the access token. The access token is keyed for the specific access level and will not be updated when changing permissions.

#### Environmental variables
1. Create a local .env file: `cp template.env .env`
1. Fill in the twitter keys created above.

#### Install
```
bundler install
```

#### Run
```
rake
```

#### Deploy
Adding a cronjob:
```
5 9-22/2 * * * root cd /opt/CutePetsChemnitz && rake
```



## Hat tips

* Kudos to [Darius](https://github.com/dariusk) for his [great guide](http://tinysubversions.com/2013/09/how-to-make-a-twitter-bot/) on how to make a twitter bot.

* And kudo to [Erik](https://github.com/sferik/) for the [twitter gem](https://github.com/sferik/twitter).
