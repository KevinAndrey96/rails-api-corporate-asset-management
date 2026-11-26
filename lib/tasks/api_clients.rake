namespace :api_clients do
  desc "Issue a bearer token: bin/rails 'api_clients:issue[name,editor]' (access: reader or editor)"
  task :issue, %i[name access] => :environment do |_task, args|
    client, token = ApiClient.issue!(name: args.fetch(:name), access: args.fetch(:access, "reader"))

    puts "#{client.name} (#{client.access}): #{token}"
    puts "Store it now, only its SHA-256 digest is kept."
  end

  desc "Revoke a client by name: bin/rails 'api_clients:revoke[name]'"
  task :revoke, %i[name] => :environment do |_task, args|
    ApiClient.find_by!(name: args.fetch(:name)).revoke!

    puts "revoked #{args[:name]}"
  end
end
