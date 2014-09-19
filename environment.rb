require 'dotenv'
Dotenv.load

require 'sequel'
DB = Sequel.connect(ENV['DATABASE_URL'])

require 'cuba'
require 'cuba/render'
require 'json'
require 'tilt/haml'

require './codeship_build'
require './bitbucket_pull_request'
# require 'rack/protection'
