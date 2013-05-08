class HookController < ApplicationController
	
	def index
		@version = `git describe`
		@branch = `git rev-parse --abbrev-ref HEAD`
	end

	def post
		# TODO check if this is really from Travis CI
		# Check if the branch name is master
		# Check if it built correctly
				
		`cd /var/www/life/`
		`git fetch --tags`
		`git checkout master`
		`git reset --hard HEAD`
		`git pull origin master`
		@version = `git describe --abbrev=0`

		`bundle install --deployment`
		
		# Delete tmp directory?
		# chmod 774 ?
		# permissions?
	end
end
