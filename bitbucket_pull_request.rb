# Schema Info
#
# Table name: bit_bucket_pull_requests
#
#  id                   :integer
#  title                :string
#  description          :text
#  self_link            :string
#  merge_link           :string
#  approve_link         :string
#  decline_link         :string
#  state                :string
#  pr_id                :integer
#  source_commit_link   :string
#  source_commit_hash   :string
#  repository_name      :string
#  repository_full_name :string
#  repository_link      :string
#  created_at           :datetime
#  updated_at           :datetime
#

class BitbucketPullRequest < Sequel::Model

  plugin :validation_helpers
  plugin :timestamps, update_on_create: true
  plugin :update_or_create

  def validate
    super
    validates_presence [:title, :self_link, :merge_link, :approve_link,
                        :decline_link, :state, :pr_id, :source_commit_link,
                        :source_commit_hash, :repository_name,
                        :repository_full_name, :repository_link]
    validates_unique :pr_id
  end

end
