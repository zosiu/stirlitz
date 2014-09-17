require 'cuba'
require 'sequel'
require 'dotenv'
# require 'rack/protection'

Dotenv.load
DB = Sequel.connect(ENV['DATABASE_URL'])

Cuba.use Rack::Session::Cookie, :secret => '__a_very_long_string__'
# Cuba.use Rack::Protection

Cuba.define do
  on get do
    on 'doit' do
      DB[:builds].insert(build_id: Time.now.to_i)
      res.write 'Did it!'
    end

    on 'hello' do
      res.write DB[:builds].all.inspect
    end

    on root do
      res.redirect '/hello'
    end
  end
end
