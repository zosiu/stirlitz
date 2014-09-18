require 'dotenv'
Dotenv.load

require 'sequel'
DB = Sequel.connect(ENV['DATABASE_URL'])

require 'cuba'
require 'json'

require './codeship_build'
require './bitbucket_pull_request'
# require 'rack/protection'
