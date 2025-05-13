# @summary Manages the installation and configuration of NVM (Node Version Manager)

# @param user
#   The user for whom NVM will be installed. This is a required parameter.
# @param home
#   The home directory of the user. If not specified, it defaults to '/root' for root or '/home/<user>' for others.
# @param nvm_dir
#   The directory where NVM will be installed. If not specified, it defaults to '/home/<user>/.nvm'.
# @param profile_path
#   The path to the user's profile file. If not specified, it defaults to '/home/<user>/.bashrc'.
# @param version
#   The version of NVM to install. If not specified, it defaults to the value in nvm::params.
# @param manage_user
#   Whether to manage the user resource. If not specified, it defaults to the value in nvm::params.
# @param manage_dependencies
#   Whether to manage dependencies like git, wget, and make. If not specified, it defaults to the value in nvm::params.
# @param manage_profile
#   Whether to manage the user's profile file. If not specified, it defaults to the value in nvm::params.
# @param nvm_repo
#   The repository URL for NVM. If not specified, it defaults to the value in nvm::params.
# @param refetch
#   Whether to refetch the NVM repository. If not specified, it defaults to the value in nvm::params.
# @param install_node
#   The version of Node.js to install. If not specified, it defaults to the value in nvm::params.
# @param node_instances
#   A hash of Node.js versions to install with their configurations. If not specified, it defaults to the value in nvm::params.
class nvm (
  String $user,

  # The home directory of the user. Defaults to '/root' for root or '/home/<user>' for others.
  Optional[String] $home = undef,

  # The directory where NVM will be installed. Defaults to '/home/<user>/.nvm'.
  Optional[String] $nvm_dir = undef,

  # The path to the user's profile file. Defaults to '/home/<user>/.bashrc'.
  Optional[String] $profile_path = undef,

  # The version of NVM to install. Defaults to the value in nvm::params.
  String $version = $nvm::params::version,

  # Whether to manage the user resource. Defaults to the value in nvm::params.
  Boolean $manage_user = $nvm::params::manage_user,

  # Whether to manage dependencies like git, wget, and make. Defaults to the value in nvm::params.
  Boolean $manage_dependencies = $nvm::params::manage_dependencies,

  # Whether to manage the user's profile file. Defaults to the value in nvm::params.
  Boolean $manage_profile = $nvm::params::manage_profile,

  # The repository URL for NVM. Defaults to the value in nvm::params.
  String $nvm_repo = $nvm::params::nvm_repo,

  # Whether to refetch the NVM repository. Defaults to the value in nvm::params.
  Boolean $refetch = $nvm::params::refetch,

  # The version of Node.js to install. Defaults to the value in nvm::params.
  Optional[String] $install_node = $nvm::params::install_node,

  # A hash of Node.js versions to install with their configurations. Defaults to the value in nvm::params.
  Hash $node_instances = $nvm::params::node_instances,
) inherits nvm::params {
  if $home == undef and $user == 'root' {
    $final_home = '/root'
  }
  elsif $home == undef {
    $final_home = "/home/${user}"
  }
  else {
    $final_home = $home
  }

  if $nvm_dir == undef {
    $final_nvm_dir = "/home/${user}/.nvm"
  }
  else {
    $final_nvm_dir = $nvm_dir
  }

  if $profile_path == undef {
    $final_profile_path = "/home/${user}/.bashrc"
  }
  else {
    $final_profile_path = $profile_path
  }

  validate_string($user)
  validate_string($final_home)
  validate_string($final_nvm_dir)
  validate_string($final_profile_path)
  validate_string($version)
  validate_bool($manage_user)
  validate_bool($manage_dependencies)
  validate_bool($manage_profile)
  if $install_node {
    validate_string($install_node)
  }
  validate_hash($node_instances)

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  if $manage_dependencies {
    $nvm_install_require = Package['git','wget','make']
    ensure_packages(['git', 'wget', 'make'])
  }
  else {
    $nvm_install_require = undef
  }

  if $manage_user {
    user { $user:
      ensure     => present,
      home       => $final_home,
      managehome => true,
      before     => Class['nvm::install'],
    }
  }

  class { 'nvm::install':
    user         => $user,
    home         => $final_home,
    version      => $version,
    nvm_dir      => $final_nvm_dir,
    nvm_repo     => $nvm_repo,
    dependencies => $nvm_install_require,
    refetch      => $refetch,
  }

  if $manage_profile {
    file { "ensure ${final_profile_path}":
      ensure => 'file',
      path   => $final_profile_path,
      owner  => $user,
    }
    -> file_line { 'add NVM_DIR to profile file':
      path => $final_profile_path,
      line => "export NVM_DIR=${final_nvm_dir}",
    }
    -> file_line { 'add . ~/.nvm/nvm.sh to profile file':
      path => $final_profile_path,
      line => "[ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"  # This loads nvm",
    }
  }

  if $install_node {
    $final_node_instances = merge($node_instances, {
        "${install_node}" => {
          set_default => true,
        },
    })
  }
  else {
    $final_node_instances = $node_instances
  }

  $default_node_settings = {
    user        => $user,
    nvm_dir     => $final_nvm_dir,
  }
  create_resources(::nvm::node::install, $final_node_instances, $default_node_settings)
}
