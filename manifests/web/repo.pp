#
# name: the fqdn under which this repo will be avaiable
# projectroot: where the git repos are listened
# projects_list: which repos to export
#
define git::web::repo(
  $ensure = 'present',
  $projectroot = false,
  $projects_list = false,
  $sitename = 'absent'
){
  if $ensure == 'present' and ! $projectroot and ! $projects_list {
    fail "must provide \$projectroot and \$projects_list for git::web::repo $name"
  }
  if $ensure == 'present' {
    include git::web
  }
  case $gitweb_sitename {
    'absent': {
      $gitweb_sitename = "$name git repository"
    }
    default: {
      $gitweb_sitename = $sitename
    }
  }
  $gitweb_config = "/etc/gitweb.d/$name.conf"
  file{$gitweb_config: }
  if $ensure == 'present' {
    File[$gitweb_config]{
      content => template("git/web/config")
    }
  } else {
    File[$gitweb_config]{
      ensure => absent,
    }
  }
  case $gitweb_webserver {
    'apache': {
      apache::vhost::generator{"$name.conf":
        ensure => $ensure,
        http => {
          'ServerName' => $name,
          'DocumentRoot' => '/var/www/git/public',
          'ScriptAlias' => '/gitweb.cgi /var/www/git/gitweb.cgi',
          'SetEnv' => "GITWEB_CONFIG $gitweb_config",
          'DirectoryIndex' => 'gitweb.cgi',
          'Directory "/var/www/git/static"' => {
            'Options' => 'ExecCGI',
            'AddHandler' => 'cgi-script .cgi',
            'Files gitweb.cgi' => {
              'Options' => 'ExecCGI FollowSymLinks',
              'SetHandler' => 'cgi-script',
            },
          },
          'RewriteEngine' => 'on',
          'RewriteRule' => '^[a-zA-Z0-9_-]+.git/?(\?.)?$ /gitweb.cgi%{REQUESTURI} [L,PT]',
        }
      }
    }
    default: {
      if ($ensure == 'present') {
        fail("no supported \$gitweb_webserver defined on $fqdn, so can't do git::web::repo: $name")
      }
    }
  }
}
