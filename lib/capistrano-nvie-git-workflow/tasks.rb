require 'capistrano'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano-nvie-git-workflow requires Capistrano v2"
end

require 'cap_git_tools/tasks'
require 'capistrano-nvie-git-workflow/task_helpers'

Capistrano::Configuration.instance.load do
  namespace :git do
    extend CapGitTools::TaskHelpers
    extend CapistranoNvieGitWorkflow::TaskHelpers

    desc "Sets the proper values to deploy using the nvie workflow"
    task :use_nvie_workflow do
      ensure_git_fetch
      tag_task = ""
      if fetch(:stage) == :production
        setup_final_workflow_stage
        tag_task = "git:retag"
      else
        setup_initial_workflow_stage
        tag_task = "git:tag"
      end

      after "git:use_nvie_workflow", "git:guard_committed", "git:guard_upstream", tag_task
    end

    task :set_from_tag do
      if fetch(:stage) == :production
        _cset :from_tag, choose_deployment_tag
      else
        set :branch, choose_deployment_branch
      end
    end

    task :set_log_command do
      ENV['git_log_command'] = fetch(:git_log_command, 'log --pretty=format:"%h %ad %s [%an]" --date=short') unless ENV['git_log_command']
    end

    before "git:commit_log", "git:set_from_tag", "git:set_log_command"
  end


end
