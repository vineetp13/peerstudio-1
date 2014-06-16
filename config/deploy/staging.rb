set :stage, :staging

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary
# server in each group is considered to be the first
# unless any hosts have the primary property set.
# role :app, %w{ubuntu@beta.peerstudio.org}
# role :web, %w{ubuntu@beta.peerstudio.org}
# role :db,  %w{ubuntu@beta.peerstudio.org}

set :branch, "beta"
set :rails_env, "production"

# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server
# definition into the server list. The second argument
# something that quacks like a hash can be used to set
# extended properties on the server.
server 'www.peerstudio.org', user: 'deploy', roles: %w{web app}, my_property: :my_value

# set :deploy_to, 
set :deploy_to, '/srv/www/peerstudio'
# you can set custom ssh options
# it's possible to pass any option but you need to keep in mind that net/ssh understand limited list of options
# you can see them in [net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start)
# set it globally
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
# and/or per server
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
# setting per server overrides global ssh_options

task :check_write_permissions do
  on roles(:all) do |host|
	if test("[ -w #{fetch(:deploy_to)} ]")
	  info "#{fetch(:deploy_to)} is writable on #{host}"
	else
	  error "#{fetch(:deploy_to)} is not writable on #{host}"
	end
  end
end

# fetch(:default_env).merge!(rails_env: :staging)
