begin
  require 'beaker/dsl/install_utils'
  require 'puppet/acceptance/git_utils'
  extend Puppet::Acceptance::GitUtils
end

test_name "Install packages and repositories on target machines..." do
  extend Beaker::DSL::InstallUtils

  SourcePath  = Beaker::DSL::InstallUtils::SourcePath
  GitURI      = Beaker::DSL::InstallUtils::GitURI
  GitHubSig   = Beaker::DSL::InstallUtils::GitHubSig

  tmp_repositories = []
  options[:install].each do |uri|
    if uri !~ GitURI
      # Build up project git urls based on git server and SHA env variables
      sha = ENV['SHA']
      facter_sha = ENV['FACTER_SHA']
      hiera_sha = ENV['HIERA_SHA']
      uri += '#' + sha if sha && uri =~ /^puppet/
      uri.gsub!(/#stable/, facter_sha) if facter_sha && uri =~ /^facter/
      uri.gsub!(/#stable/, hiera_sha) if hiera_sha && uri =~ /^hiera/
      project = uri.split('#')
      newURI = "#{build_giturl(project[0])}#{newURI}##{project[1]}"
      tmp_repositories << extract_repo_info_from(newURI)
    else  # URI probably built up by rakefile
      raise(ArgumentError, "#{uri} is not recognized.") unless(uri =~ GitURI)
      tmp_repositories << extract_repo_info_from(uri)
    end
  end

  repositories = order_packages(tmp_repositories)

  hosts.each_with_index do |host, index|
    on host, "echo #{GitHubSig} >> $HOME/.ssh/known_hosts"

    case test_config[:install_type]
    when :git
      case host['platform']
      when /(el-|fedora)/
        on host, "yum install -y git-core ruby rubygem-rake"
      when /debian/
        on host, "apt-get install -y git-core ruby rake"
      else
        raise "OS #{host['platform']} not supported"
      end
    end

    versions = {}
    repositories.each do |repository|
      step "Install #{repository[:name]}"
      if repository[:path] =~ /^file:\/\/(.+)$/
        on host, "test -d #{SourcePath} || mkdir -p #{SourcePath}"
        source_dir = $1
        checkout_dir = "#{SourcePath}/#{repository[:name]}"
        on host, "rm -f #{checkout_dir}" # just the symlink, do not rm -rf !
        on host, "ln -s #{source_dir} #{checkout_dir}"
        on host, "cd #{checkout_dir}
                    && if [ -f install.rb ]; then ruby ./install.rb ; else true; fi"
      else
        install_from_git host, SourcePath, repository
      end

      if index == 1
        versions[repository[:name]] = find_git_repo_versions(host, SourcePath,
                                                             repository)
      end
    end
  end

  step "Populate facts from each host" do
    populate_facts
  end

  step "Agents: create basic puppet.conf" do
    agents.each do |agent|
      puppetconf = File.join(agent['puppetpath'], 'puppet.conf')

      on agent, "echo '[agent]' > #{puppetconf} && " +
                "echo server=#{master} >> #{puppetconf}"
      step "ensure puppet user and group added to all nodes because this is what the packages do" do
        on agent, puppet("resource user puppet ensure=present")
        on agent, puppet("resource group puppet ensure=present")
    end
    end
  end
end
