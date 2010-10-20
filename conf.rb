
RoxConf::Conf = {
  # relative paths will be relative to **this __FILE__** ! not pwd
  :apps => [
    { :path => 'confconf' },
    { :path => 'userconf' },
    { :path => 'redconf' },
    { :path => 'monitconf.d/monitconf'},
    { :path => 'passengerconf' },
    { :path => '/etc/nginx/sites', :cd => '../hipe-sites' },
    { :path => '/etc/thin/thinconf', :cd => :dir },
    { :path => 'uniconf' },
    { :path => '/var/sites/redmine-git/current/script/mineconf', :cd => '../..' },
    { :path => '<%= home %>/gitolite-admin/repoconf', :git => 'git@hipeland.org:gitolite-admin', :cd => '..' }
  ]
}
