# The Ruby Callback Handler

This is a Heroku compatible application for operating a callback handler similar to that built into the
transaction injector and includes a few extra features to boot.

It uses poorly thought out REST/JSON to interact with a set of recorded incoming requests, and may serve as
a foundation for TestPoint-2 (Hermes)

## Install

The Gemfile contains a list of dependencies you need to run this script. They can be installed by simply running
the following command. Ensure you've got ```http_proxy``` set properly

    bundle install 

## Start

Simply run the handler script if you're running locally. This will start a ruby webserver on the default port of 
4567

    ruby handler.rb 

For additional information, use the "--help" argument 

## Further information

Run the handler and open your browser to the returned url. You will be redirected to in-app documentation that describes
the functionality of the tool in detail.
