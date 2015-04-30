AD Syncinator [![Build Status](https://travis-ci.org/biola/ad-syncinator.svg)](https://travis-ci.org/biola/ad-syncinator)
=============

AD Syncinator creates and syncs accounts from [trogdir-api](https://github.com/biola/trogdir-api) into Active Directory.

Requirements
------------
- Ruby
- Redis server (for Sidekiq)
- trogdir-api installation
- Admin access to a Active Directory server

Installation
------------
```bash
git clone git@github.com:biola/ad-syncinator.git
cd ad-syncinator
bundle install
cp config/settings.local.yml.example config/settings.local.yml
cp config/blazing.rb.example config/blazing.rb
```

Configuration
-------------
- Edit `config/settings.local.yml` accordingly.
- Edit `config/blazing.rb` accordingly.

Running
-------

```ruby
sidekiq -r ./config/environment.rb
```

Deployment
----------
```bash
blazing setup [target name in blazing.rb]
git push [target name in blazing.rb]
```
