require 'cap_git_tools/tasks'

module CapistranoNvieGitWorkflow::TaskHelpers
  include CapGitTools::TaskHelpers

  def checkout_and_pull_branch(deployment_branch)
    if has_branch_locally?(deployment_branch)
      local_sh "git checkout #{deployment_branch}"
      local_sh "git pull #{upstream_remote} #{deployment_branch}"
    else
      local_sh "git checkout -b #{deployment_branch}  #{upstream_remote}/#{deployment_branch} -t"
    end
  end

  def choose_deployment_branch
    deployable_branches = get_deployable_branches
    Capistrano::CLI.ui.say "What branch do you want to deploy?"
    Capistrano::CLI.ui.choose *deployable_branches
  end

  def choose_deployment_tag
    tags = `git tag -l '#{previous_stage}-*'`.split("\n")
    Capistrano::CLI.ui.say "What tag do you want to deploy?"
    Capistrano::CLI.ui.choose *tags
  end

  def create_deployment_tag(version)
    timestamp = Time.now.localtime.strftime('%Y%m%d%H%M%S')
    deployment_tag = "#{fetch(:stage)}-#{version}-#{timestamp}" 
    Capistrano::CLI.ui.say "    New deployment tag will be: #{deployment_tag}"
    return deployment_tag
  end

  def create_deployment_tag_from_branch(deploy_branch)
    version = deploy_branch.gsub /^(release|hotfix)-/, ''
    create_deployment_tag version
  end

  def filter_remote_branches
    rem_branches = local_sh("git branch -r --no-color").split "\n"
    rem_branches.reject! {|b| b =~ /HEAD/}
    rem_branches.map do |b|
      b = b.strip
      b.gsub!(/#{upstream_remote}\//, '')
      b.gsub!(/ .*/, '')
      b.strip
    end
  end

  def final_stage
    workflow_stages.last
  end

  def final_stage?
    final_stage == fetch(:stage).to_s
  end

  def get_deployable_branches
    rem_branches = filter_remote_branches
    releases = rem_branches.map {|b| b if b =~ /^release-/}
    hotfixes = rem_branches.map {|b| b if b =~ /^hotfix-/}
    (releases + hotfixes).compact
  end

  def get_local_branches
    loc_branches = local_sh("git for-each-ref --format='%(refname:short)' refs/heads/*").chomp.split("\n")
    loc_branches
  end

  def get_version_from_tag(tag)
    tag.gsub(/(^\w+-)|(-\d+$)/, '')
  end

  def has_branch_locally?(target_branch)
    get_local_branches.include? target_branch
  end

  def initial_stage
    workflow_stages.first
  end

  def initial_stage?
    initial_stage == fetch(:stage).to_s
  end

  def local_sh(cmd)
    Capistrano::CLI.ui.say "    Executing locally: #{cmd}"
    r = `#{cmd}`
    abort("failed: #{cmd}") unless $? == 0
    r
  end

  def merge_tag_to_production(deploy_tag, version)
    `git checkout #{production_branch}`
    local_sh "git merge --no-ff --no-edit -m 'Release #{version} to #{fetch :stage}' #{deploy_tag}"
    local_sh "git push #{upstream_remote} #{production_branch}"
  end

  def next_stage
    next_idx = workflow_stages.index(fetch(:stage).to_s) + 1
    next_idx >= workflow_stages.size ? nil : workflow_stages[next_idx]
  end

  def previous_stage
    previous_idx = workflow_stages.index(fetch(:stage).to_s) - 1
    previous_idx < 0 ? nil : workflow_stages[previous_idx]
  end

  def production_branch
    fetch(:production_branch, 'master')
  end

  def setup_tagged_workflow_stage
    deploy_tag = choose_deployment_tag
    version = get_version_from_tag deploy_tag

    if final_stage?
      checkout_and_pull_branch fetch(:production_branch, 'master')
      merge_tag_to_production(deploy_tag, version) if final_stage?
    end

    _cset :tag, create_deployment_tag(version)
    _cset :from_tag, deploy_tag
  end

  def setup_initial_workflow_stage
    deployment_branch = choose_deployment_branch
    checkout_and_pull_branch deployment_branch
    set :branch, deployment_branch
    _cset :tag, create_deployment_tag_from_branch(deployment_branch)
  end

  def workflow_stages
    @workflow_stages ||= if exists?(:workflow_stages)
      fetch :workflow_stages
    elsif fetch(:stages).size == 2
      stages = fetch(:stages).dup
      abort(<<-EOF) unless stages.delete('production')
  failed: No 'production' stage found
    
    You do not have a stage named 'production'. Please specify the proper
    stage deployment order by setting the :workflow_stages variable with 
    the final production stage last.
    EOF

      stages << 'production'
      stages
    else
      abort(<<-EOF)
  failed: Unable to identify workflow stages

    You must either have only two stages defined in the :stages variable
    or you must set the :workflow_stages variable to the stages you want 
    to deploy to, and their proper sequence.
      EOF
    end
  end
end
