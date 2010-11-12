define git::clone(
  $git_repo,
  $projectroot,
  $ensure = present,
  $cloneddir_user = 'root',
  $cloneddir_group = '0',
  $cloneddir_restrict_mode = true
){
  case $ensure {
    absent: {
      exec{"rm -rf $projectroot":
        onlyif => "test -d  $projectroot",
      }
    }
    default: {
      include git
      exec{"git-clone_$name":
        user => root,
        command => "git-clone --no-hardlinks $git_repo $projectroot",
        creates => "$projectroot/.git",
        require => Package['git'],
        notify => Exec["git-clone-chown_$name"],
      }
      exec{"git-clone-chown_$name":
        command => "chown -R $cloneddir_user:$cloneddir_group $projectroot",
        refreshonly => true
      }
      if $cloneddir_restrict_mode {
        exec{"git-clone-chmod_$name":
          command => "chmod -R o-rwx $projectroot",
          refreshonly => true,
          subscribe => Exec["git-clone_$name"],
        }
      }
    }
  }
}
