require File.join(File.dirname(__FILE__), '../lib/git')
require File.join(File.dirname(__FILE__), '../lib/remote_cache')

class Deployer
  include Nanite::Actor

  expose :deploy

  def deploy(payload)
    r = CachedGitDeploy.new :repository => "git://github.com/engineyard/rails-2.2.2-app.git",
                            :deploy_to  => "/data/foobar"                     
    r.deploy
  end
  
  
end
