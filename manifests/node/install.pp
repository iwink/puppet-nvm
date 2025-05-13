# See README.md for usage information
# @summary Install a specific version of Node.js using NVM
# @param user
#   The user for whom Node.js will be installed. This is a required parameter.
# @param nvm_dir
#   The directory where NVM is installed. If not specified, it defaults to '/home/<user>/.nvm'.
# @param version
#   The version of Node.js to install. This is a required parameter.
# @param set_default
#   Whether to set the installed version as the default. This is a boolean parameter. Defaults to false.
# @param from_source
#   Whether to install Node.js from source. This is a boolean parameter. Defaults to false.
# @param default
#   A deprecated parameter that is now replaced by set_default. This is a boolean parameter. Defaults to false.
define nvm::node::install (
  String $user,
  String           $version     = $title,
  Boolean          $set_default = false,
  Boolean          $from_source = false,
  Boolean          $default     = false,
  Optional[String] $nvm_dir     = undef,
) {
  # The base class must be included first because it is used by parameter defaults
  if ! defined(Class['nvm']) {
    fail('You must include the nvm base class before using any nvm defined resources')
  }

  # Notify users that use the deprecated default parameter
  if $default {
    notify { 'The `default` parameter is now deprecated because `default` is a reserved word use `set_default` instead': }
    $is_default = true
  }
  else {
    $is_default = $set_default
  }

  if $nvm_dir == undef {
    $final_nvm_dir = "/home/${user}/.nvm"
  }
  else {
    $final_nvm_dir = $nvm_dir
  }

  validate_string($user)
  validate_string($final_nvm_dir)
  validate_string($version)
  validate_bool($default)
  validate_bool($set_default)
  validate_bool($from_source)

  if $from_source {
    $nvm_install_options = ' -s '
  }
  else {
    $nvm_install_options = ''
  }

  exec { "nvm install node version ${version}":
    cwd         => $final_nvm_dir,
    command     => ". ${final_nvm_dir}/nvm.sh && nvm install ${nvm_install_options} ${version}",
    user        => $user,
    unless      => ". ${final_nvm_dir}/nvm.sh && nvm which ${version}",
    environment => ["NVM_DIR=${final_nvm_dir}"],
    require     => Class['nvm::install'],
    provider    => shell,
  }

  if $is_default {
    exec { "nvm set node version ${version} as default":
      cwd         => $final_nvm_dir,
      command     => ". ${final_nvm_dir}/nvm.sh && nvm alias default ${version}",
      user        => $user,
      environment => ["NVM_DIR=${final_nvm_dir}"],
      unless      => ". ${final_nvm_dir}/nvm.sh && nvm which default | grep ${version}",
      provider    => shell,
      require     => Exec["nvm install node version ${version}"],
    }
  }
}
