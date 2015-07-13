Sequel.migration do
  change do
    add_column :codeship_builds, :project_name, String
  end
end
