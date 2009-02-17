# stolen wholesale from capistrano, thanks Jamis!

class CachedGitDeploy
  # Executes the SCM command for this strategy and writes the REVISION
  # mark file to each host.
  def deploy
    @buffer = []
    @configuration[:release_path] = "#{@configuration[:deploy_to]}/releases/#{Time.now.to_i}"
    @configuration[:revision] = source.query_revision('HEAD') {|cmd| run cmd}  
    run(update_repository_cache)
    run(copy_repository_cache)
    symlink
    @buffer
  end
  
  def latest_release
    File.join(release_path, `ls #{release_path}`.split("\n").sort.last)
  end
  
  def previous_release
    File.join(release_path, `ls #{release_path}`.split("\n").sort[-2])
  end
  
  def current_path
    "#{@configuration[:deploy_to]}/current"
  end

  def shared_path
    configuration[:shared_path]
  end
  
  def release_path
    "#{@configuration[:deploy_to]}/releases"
  end
  
  def symlink
    symlink = false
    begin
      run [ "chmod -R g+w #{latest_release}",
            "rm -rf #{latest_release}/log #{latest_release}/public/system #{latest_release}/tmp/pids",
            "mkdir -p #{latest_release}/db #{latest_release}/tmp",
            "ln -nfs #{shared_path}/log #{latest_release}/log",
            "mkdir -p #{latest_release}/public",
            "mkdir -p #{latest_release}/config",
            "ln -nfs #{shared_path}/system #{latest_release}/public/system",
            "ln -nfs #{shared_path}/pids #{latest_release}/tmp/pids",
            "ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml"
          ].join(" && ")

      symlink = true
      run "rm -f #{current_path} && ln -nfs #{latest_release} #{current_path}"
    rescue => e
      run "rm -f #{current_path} && ln -nfs #{previous_release} #{current_path}" if
        symlink
      run "rm -rf #{latest_release}"
      raise e
    end
  end
  
  def run(cmd)
    @buffer << `#{cmd}`
  end
  
  # :repository_cache
  # :shared_path
  # :repository
  # :release_path
  # :copy_exclude
  # :revision
  def initialize(opts={})
    @configuration = opts
    @configuration[:shared_path] = "#{@configuration[:deploy_to]}/shared"
  end
  
  def configuration
    @configuration
  end
  
  def source
    @source ||= Git.new configuration
  end

  private

    def repository_cache
      File.join(configuration[:shared_path], configuration[:repository_cache] || "cached-copy")
    end

    def update_repository_cache
      puts "updating the cached checkout on all servers"
      command = "if [ -d #{repository_cache} ]; then " +
        "#{source.sync(revision, repository_cache)}; " +
        "else #{source.checkout(revision, repository_cache)}; fi"
      command
    end

    def copy_repository_cache
      puts "copying the cached version to #{configuration[:release_path]}"
      if copy_exclude.empty? 
        return "cp -RPp #{repository_cache} #{configuration[:release_path]} && #{mark}"
      else
        exclusions = copy_exclude.map { |e| "--exclude=\"#{e}\"" }.join(' ')
        return "rsync -lrpt #{exclusions} #{repository_cache}/* #{configuration[:release_path]} && #{mark}"
      end
    end
    
    def revision
      configuration[:revision]
    end
    
    def mark
      "(echo #{revision} > #{configuration[:release_path]}/REVISION)"
    end
    
    def copy_exclude
      @copy_exclude ||= Array(configuration.fetch(:copy_exclude, []))
    end
end