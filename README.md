# CutePetsChemnitz

## Post a random adoptable pet from Denver's shelter to a twitter feed.

Originated as a project of [Team Denver](http://codeforamerica.org/cities/denver/) during the 2014 fellowship at Code for America.

### About
A twitter bot to serve data for animals currently in ["Tierfreunde helfen Tieren in Not e.V." shelter](http://www.tierfreunde-helfen.de/) ready for adoption.

Originally specific to Denver, it's been redeployed by a few cities. Check out [this twitter list](https://twitter.com/drewSaysGoVeg/cutepetseverywhere/members) to see where.

**Links to API and Bot**

* [Twitter bot](https://twitter.com/petschemnitz)

* [API](http://[::]:3000/)

## Setup

### API

#### Install

```
cd parser
npm install
npm build
```

#### Run
```
node lib/scraper.js
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

### Deployment

Todo

### Hat tips

* Kudos to [Darius](https://github.com/dariusk) for his [great guide](http://tinysubversions.com/2013/09/how-to-make-a-twitter-bot/) on how to make a twitter bot.

* And kudo to [Erik](https://github.com/sferik/) for the [twitter gem](https://github.com/sferik/twitter).
