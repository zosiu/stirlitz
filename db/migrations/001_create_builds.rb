Sequel.migration do
  change do
    create_table(:builds) do
      primary_key :id
      String :ci_server, default: 'codeship.io'
      String :build_url
      String :commit_url
      Integer :project_id
      Integer :build_id
      String :status
      String :project_full_name
      String :commit_id
      String :short_commit_id
      String :message
      String :committer
      String :branch
    end
  end
end
