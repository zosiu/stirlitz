Sequel.migration do
  change do
    create_table(:codeship_builds) do
      primary_key :id
      String :build_url
      String :badge_url
      String :commit_url
      Integer :project_id
      Integer :build_id
      String :status
      String :project_full_name
      String :commit_id
      String :short_commit_id
      String :message, text: true
      String :committer
      String :branch
      Boolean :badge_comment_sent, default: false
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
