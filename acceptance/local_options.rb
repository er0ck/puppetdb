dir = File.expand_path(File.dirname(__FILE__))
pre_suite_dir = File.join(dir, 'setup', 'pre_suite')
{
  :install => [
    'facter#stable',
    'hiera#stable',
    'puppet',
  ],
  :load_path => './lib/',
  :log_level => 'verbose',
  :add_el_extras => true,
  :type => 'git',
  :puppetdb_database => 'embedded',
  :puppetdb_repo_puppetdb => 'git://github.com/puppetlabs/puppetdb#master',
  :helper    => [File.join(dir, 'helper.rb')],
  :pre_suite => [
    File.join(dir, 'setup', 'early', '00_remove_previous_config.rb'),
    File.join(pre_suite_dir, '00_setup_test_env.rb'),
    File.join(pre_suite_dir, '05_clear_firewalls.rb'),
    File.join(pre_suite_dir, '10_setup_proxies.rb'),
    File.join(pre_suite_dir, '12_upgrade_distros.rb'),
    File.join(pre_suite_dir, '15_setup_repos.rb'),
    File.join(pre_suite_dir, '21_install_puppet_from_source.rb'),
    File.join(pre_suite_dir, '30_generate_ssl_certs.rb'),
    File.join(pre_suite_dir, '40_install_deps.rb'),
    File.join(pre_suite_dir, '50_install_modules.rb'),
    File.join(pre_suite_dir, '60_munge_etc_hosts_for_dujour.rb'),
    File.join(pre_suite_dir, '70_install_released_puppetdb.rb'),
    File.join(pre_suite_dir, '80_add_dev_repo.rb'),
    File.join(pre_suite_dir, '90_install_devel_puppetdb.rb'),
  ]
}
