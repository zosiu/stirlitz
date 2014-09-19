Sequel.migration do
  change do
    add_column :bitbucket_pull_requests, :last_commit_sha, String
  end
end
