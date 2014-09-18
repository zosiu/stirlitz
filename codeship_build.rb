# Schema Info
#
# Table name: codeship_builds
#
#  id                 :integer
#  build_url          :string
#  commit_url         :string
#  project_id         :integer
#  build_id           :integer
#  status             :string
#  project_full_name  :string
#  commit_id          :string
#  short_commit_id    :string
#  message            :text
#  committer          :string
#  branch             :string
#  created_at         :datetime
#  updated_at         :datetime
#

require './bitbucket_pull_request'

class CodeshipBuild < Sequel::Model

  plugin :validation_helpers
  plugin :timestamps, update_on_create: true
  plugin :update_or_create

  STATUSES = ['testing', 'error', 'success', 'stopped', 'waiting']

  def bitbucket_pull_request
    BitbucketPullRequest.first source_commit_hash: bitbucket_commit_hash
  end

  def bitbucket_commit_hash
    commit_id[0...12]
  end

  def validate
    super
    validates_presence [:build_url, :commit_url, :project_id,
                        :build_id, :status, :project_full_name, :commit_id,
                        :short_commit_id, :message, :committer, :branch]
    validates_unique :build_id
    validates_includes self.class::STATUSES, :status
  end

  def after_save
    super
    return if bitbucket_pull_request.nil?

    case status
    when 'success'
      bitbucket_pull_request.approve!
    else
      bitbucket_pull_request.unapprove!
    end
  end

end
