# See README.md for usage information
# @summary Install nvm from git
# @param user
#   The user for whom NVM will be installed. This is a required parameter.
# @param home
#   The home directory of the user. If not specified, it defaults to '/root' for root or '/home/<user>'.
# @param version
#   The version of NVM to install. If not specified, it defaults to the value in nvm::params.
# @param nvm_dir
#   The directory where NVM will be installed. If not specified, it defaults to '/home/<user>/.nvm'.
# @param nvm_repo
#   The repository URL for NVM. If not specified, it defaults to the value in nvm::params.
# @param dependencies
#   The dependencies required for NVM installation. If not specified, it defaults to the value in nvm::params.
# @param refetch
#   Whether to refetch the NVM repository. If not specified, it defaults to the value in nvm::params.
class nvm::install (
  String $user,
  String $version,
  String $nvm_dir,
  String $nvm_repo,
  Array[String] $dependencies,
  Boolean $refetch = false,
  Optional[String] $home = undef,
) {
  exec { "git clone ${nvm_repo} ${nvm_dir}":
    command => "git clone ${nvm_repo} ${nvm_dir}",
    cwd     => $home,
    user    => $user,
    unless  => "/usr/bin/test -d ${nvm_dir}/.git",
    require => $dependencies,
    notify  => Exec["git checkout ${nvm_repo} ${version}"],
  }

  if $refetch {
    exec { "git fetch ${nvm_repo} ${nvm_dir}":
      command => 'git fetch',
      cwd     => $nvm_dir,
      user    => $user,
      require => Exec["git clone ${nvm_repo} ${nvm_dir}"],
      notify  => Exec["git checkout ${nvm_repo} ${version}"],
    }
  }

  exec { "git checkout ${nvm_repo} ${version}":
    command     => "git checkout --quiet ${version}",
    cwd         => $nvm_dir,
    user        => $user,
    refreshonly => true,
  }
}
