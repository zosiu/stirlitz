require './environment'
require 'send_file'

Cuba.use Rack::Session::Cookie, secret: '__a_very_long_string__'
# Cuba.use Rack::Protection
Cuba.plugin(SendFile)
Cuba.plugin(Cuba::Render)

Cuba.settings[:render][:template_engine] = 'haml'

Cuba.define do
  on get do
    on 'ohai' do
      res.write partial('readme')
    end

    on root do
      res.redirect '/ohai'
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
      # unfortunately pullrequest_updated doesn't contain the pr_id... :(((
      # https://bitbucket.org/site/master/issue/8340/pull-request-post-hook-does-not-include
      payload = JSON.parse(req.body.read)
      pr = payload['pullrequest_created']

      pr_updated = payload['pullrequest_updated']

      # hack | ugly & time-consuming...
      if pr_updated
        repo_name = pr_updated['source']['repository']['full_name']
        # branch_name = pr_updated['source']['branch']['name']

        BitbucketPullRequest.where(repository_full_name: repo_name).each(&:update_last_commit_sha!)
      end

      if pr.nil?
        res.status = 202
        res.write({ payload_was: payload }.to_json)
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
          pr = BitbucketPullRequest.update_or_create({pr_id: pr_attrs['pr_id']}, pr_attrs)

          if pr.valid?
            res.status = 200
          else
            res.status = 500
            res.write({ error: res.errors }.to_json)
          end

        rescue Sequel::Error => e
          res.status = 500
          res.write({ error: e.message }.to_json)
        end

      end

    end

  end

end
