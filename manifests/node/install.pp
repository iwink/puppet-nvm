# See README.md for usage information
# @summary Install a specific version of Node.js using NVM
# @param user
#   The user for whom Node.js will be installed. This is a required parameter.
# @param nvm_dir
#   The directory where NVM is installed. If not specified, it defaults to '/home/<user>/.nvm'.
# @param version
#   The version of Node.js to install. This is a required parameter. Not prefixed with `v`
# @param set_default
#   Whether to set the installed version as the default. This is a boolean parameter. Defaults to false.
# @param from_source
#   Whether to install Node.js from source. This is a boolean parameter. Defaults to false.
# @param default
#   A deprecated parameter that is now replaced by set_default. This is a boolean parameter. Defaults to false.
# @param version_alias
#   An optional alias for the installed version. This is a string parameter. Defaults to undef.
define nvm::node::install (
  String $user,
  Pattern[/^\d+.\d+.\d+/] $version       = $title,
  Boolean                 $set_default   = false,
  Boolean                 $from_source   = false,
  Boolean                 $default       = false,
  Optional[String]        $version_alias = undef,
  Optional[String]        $nvm_dir       = undef,
) {
  # The base class must be included first because it is used by parameter defaults
  if ! defined(Class['nvm']) {
    fail('You must include the nvm base class before using any nvm defined resources')
  }
  if $version_alias == 'default' {
    fail('The alias parameter cannot be set to "default", use set_default instead')
  }
  # Notify users that use the deprecated default parameter
  if $default {
    notify { 'The `default` parameter is now deprecated because `default` is a reserved word use `set_default` instead': }
    $is_default = true
  }
  else {
    $is_default = $set_default
  }
  # Switch nvm_dir based on user home
  if $nvm_dir == undef {
    $final_nvm_dir = $user ? {
      'root' => '/root/.nvm',
      default => "/home/${user}/.nvm",
    }
  }
  else {
    $final_nvm_dir = $nvm_dir
  }

  if $from_source {
    $nvm_install_options = ' -s '
  }
  else {
    $nvm_install_options = ''
  }

  exec { "nvm install node version v${version}":
    cwd         => $final_nvm_dir,
    command     => ". ${final_nvm_dir}/nvm.sh && nvm install ${nvm_install_options} v${version}",
    user        => $user,
    unless      => ". ${final_nvm_dir}/nvm.sh && nvm which v${version}",
    environment => ["NVM_DIR=${final_nvm_dir}"],
    require     => Class['nvm::install'],
    provider    => shell,
  }

  if $is_default {
    exec { "nvm set node version v${version} as default":
      cwd         => $final_nvm_dir,
      command     => ". ${final_nvm_dir}/nvm.sh && nvm alias default v${version}",
      user        => $user,
      environment => ["NVM_DIR=${final_nvm_dir}"],
      unless      => ". ${final_nvm_dir}/nvm.sh && nvm which default | grep v${version}",
      provider    => shell,
      require     => Exec["nvm install node version v${version}"],
    }
  }
  if $version_alias {
    exec { "nvm set node version v${version} alias as ${version_alias}":
      cwd         => $final_nvm_dir,
      command     => ". ${final_nvm_dir}/nvm.sh && nvm alias ${version_alias} v${version}",
      user        => $user,
      environment => ["NVM_DIR=${final_nvm_dir}"],
      unless      => ". ${final_nvm_dir}/nvm.sh && nvm which ${version_alias} | grep v${version}",
      provider    => shell,
      require     => Exec["nvm install node version v${version}"],
    }
  }
}
