require 'dotenv'
Dotenv.load

require 'sequel'
DB = Sequel.connect(ENV['DATABASE_URL'])

require 'cuba'
require 'json'

require './codeship_build'
require './bitbucket_pull_request'
# require 'rack/protection'

Cuba.use Rack::Session::Cookie, secret: '__a_very_long_string__'
# Cuba.use Rack::Protection

Cuba.define do
  on get do
    on 'hello' do
      res.write (DB[:codeship_builds].all + DB[:bitbucket_pull_requests].all).map(&:inspect).join('<br/><br/>')
    end

    on root do
      res.redirect '/hello'
    end
  end

  on post do
    on 'codeship' do
      build_attrs = JSON.parse(req.body.read)['build']
      begin
        CodeshipBuild.update_or_create({build_id: build_attrs['build_id']}, build_attrs)

        res.status = 200
      rescue Sequel::Error => e
        res.status = 500
        res.write({ error: e.message }.to_json)
      end
    end

    on 'bitbucket' do
      pr = JSON.parse(req.body.read)['pullrequest_created']

      if pr.nil?
        res.status = 200
      else
        pr_attrs = {
          description: pr['description'],
          decline_link: pr['links']['decline']['href'],
          approve_link: pr['links']['approve']['href'],
          self_link: pr['links']['self']['href'],
          merge_link: pr['links']['merge']['href'],
          title: pr['title'],
          state: pr['state'],
          pr_id: pr['id'],
          source_commit_link: pr['source']['commit']['links']['self']['href'],
          source_commit_hash: pr['source']['commit']['hash'],
          repository_name: pr['source']['repository']['name'],
          repository_full_name: pr['source']['repository']['full_name'],
          repository_link: pr['source']['repository']['links']['self']['href']
        }

        begin
          BitbucketPullRequest.update_or_create({pr_id: pr_attrs['pr_id']}, pr_attrs)

          res.status = 200
        rescue Sequel::Error => e
          res.status = 500
          res.write({ error: e.message }.to_json)
        end

      end

    end

  end

end
