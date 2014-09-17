Sequel.migration do
  change do
    create_table(:bitbucket_pull_requests) do
      primary_key :id
      String :title
      String :description, text: true
      String :self_link
      String :merge_link
      String :approve_link
      String :decline_link
      String :state
      Integer :pr_id
      String :source_commit_link
      String :source_commit_hash
      String :repository_name
      String :repository_full_name
      String :repository_link
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
