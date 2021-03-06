namespace :newrelic do

  # on all deployments, notify New Relic
  desc "Record a deployment in New Relic (newrelic.com)"
  task :notice_deployment, :roles => :app, :only => { :primary => true }, :except => { :no_release => true } do
    begin
      # allow overrides to be defined for revision, description, changelog
      rev = fetch(:newrelic_revision) if exists?(:newrelic_revision)
      description = fetch(:newrelic_desc) if exists?(:newrelic_desc)
      changelog = fetch(:newrelic_changelog) if exists?(:newrelic_changelog)
      user = fetch(:newrelic_user) if exists?(:newrelic_user)

      if !changelog
        logger.debug "Getting log of changes for New Relic Deployment details"
        from_revision = source.local.next_revision(current_revision)
        if scm == :git
          log_command = "git log --no-color --pretty=format:'  * %an: %s' --abbrev-commit --no-merges #{previous_revision}..#{real_revision}"
        else
          log_command = "#{source.local.log(from_revision)}"
        end
        changelog = `#{log_command}`
      end
      if rev.nil?
        rev = source.local.query_revision(source.local.head()) do |cmd|
          logger.debug "executing locally: '#{cmd}'"
          `#{cmd}`
        end
        rev = rev[0..6] if scm == :git
      end
      new_revision = rev
      logger.debug "Uploading deployment to New Relic"
      capifony_pretty_print "--> Notifying New Relic of deployment"

      run "cd #{latest_release} && #{php_bin} #{symfony_console} newrelic:notify-deployment --env=#{symfony_env_prod} --no-debug --revision=#{rev.shellescape} --changelog=#{changelog.to_s.shellescape} --description=#{description.to_s.shellescape} --user=#{user.to_s.shellescape}"
      capifony_puts_ok
    rescue Capistrano::CommandError
      logger.info "Unable to notify New Relic of the deployment... skipping"
    end
  end
end
