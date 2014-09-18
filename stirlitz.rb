require './environment'
require 'send_file'

Cuba.use Rack::Session::Cookie, secret: '__a_very_long_string__'
# Cuba.use Rack::Protection
Cuba.plugin(SendFile)

Cuba.define do
  on get do
    on 'hello' do
      res.write (DB[:codeship_builds].all + DB[:bitbucket_pull_requests].all).map(&:inspect).join('<br/><br/>')
    end

    on root do
      res.redirect '/hello'
    end

    # codeship generates the badges nicely, but the url is based on the project_uuid,
    # and that's currently isn't exposed by their API
    # things would be much easier if the codeship webhook contained the badge url too...
    on 'badge/:build_id' do |build_id|
      res['Date'] = DateTime.now.to_time.utc.rfc2822.sub( /.....$/, 'GMT')
      res['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
      res['Pragma'] = 'no-cache'
      res['Cache-Control'] = 'no-cache, must-revalidate'

      build = CodeshipBuild[build_id: build_id]
      if build.nil?
        res.status = 404
      else
        send_file File.join('misc', 'badges', "status_#{build.badge_status}.png")
      end
    end

  end

  on post do
    on 'codeship' do
      build_attrs = JSON.parse(req.body.read)['build']
      build_id = build_attrs['build_id']
      build_attrs['badge_url'] = "#{req.env['rack.url_scheme']}://#{req.env['HTTP_HOST']}/badge/#{build_id}"

      begin
        CodeshipBuild.update_or_create({build_id: build_id}, build_attrs)

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
