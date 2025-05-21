# File pulled from the nodejs module.~
# @summary Install npm using nvm 
# @param nvm_dir
#   The directory where NVM is installed. This is a required parameter.
# @param nodejs_version
#   The version of Node.js to use. This is a required parameter.
# @param ensure
#   The desired state of the npm package. This can be 'present', 'absent', or a specific version. Defaults to 'present'.
# @param install_options
#   Additional options to pass to the npm install command. This is an array of strings. Defaults to an empty array.
# @param package
#   The name of the npm package to install. This is a required parameter.
# @param source
#   The source from which to install the npm package. This can be 'registry' or a remote URL. Defaults to 'registry'.
# @param uninstall_options
#   Additional options to pass to the npm uninstall command. This is an array of strings. Defaults to an empty array.
# @param user
#   The user under which to run the npm command. This is a required parameter.
# @param use_package_json
#   Whether to use a package.json file for installation. This is a boolean parameter. Defaults to false.
# @param target
#   The target directory for the npm installation. This is a mutually exclusive parameter with --global. If not specified, it defaults to
#   the value of the target parameter.
# @param cmd_exe_path
#   The path to the command executable. This is a required parameter.
define nvm::npm (
  Pattern[/^\d+.\d+.\d+/]         $nodejs_version,
  Pattern[/^[^<            >= ]/] $ensure             = 'present',
  Array                           $install_options    = [],
  String                          $package            = $title,
  String                          $source             = 'registry',
  Array                           $uninstall_options  = [],
  String                          $user               = 'root',
  Boolean                         $use_package_json   = false,
  Optional[Stdlib::Absolutepath]  $nvm_dir            = undef,
  Optional[Stdlib::Absolutepath]  $target             = undef,
  Optional[Stdlib::Absolutepath]  $cmd_exe_path       = undef,  #nodejs::cmd_exe_path
) {
  # Sanity checks
  if ! defined(Nvm::Node::Install[$nodejs_version]) {
    fail("You must install node version ${nodejs_version} before using nvm::npm")
  }

  $install_options_string = join($install_options, ' ')
  $uninstall_options_string = join($uninstall_options, ' ')

  # Note that install_check will always return false when a remote source is
  # provided
  if $source != 'registry' {
    $install_check_package_string = $source
    $package_string = $source
  } elsif $ensure =~ /^(present|absent)$/ {
    $install_check_package_string = $package
    $package_string = $package
  } else {
    # ensure is either a tag, version or 'latest'
    # Note that install_check will always return false when 'latest' or a tag is
    # provided
    # npm ls does not keep track of tags after install
    $install_check_package_string = "${package}:${package}@${ensure}"
    $package_string = "${package}@${ensure}"
  }

  $grep_command = $facts['os']['family'] ? {
    'Windows' => "${cmd_exe_path} /c findstr /l",
    default   => 'grep',
  }

  $dirsep = $facts['os']['family'] ? {
    'Windows' => '\\',
    default   => '/'
  }

  if $nvm_dir == undef {
    $final_nvm_dir = $user ? {
      'root' => '/root/.nvm',
      default => "/home/${user}/.nvm",
    }
  } else {
    $final_nvm_dir = $nvm_dir
  }
  # Use the nvm command to set the node version
  $nvm_command_prefix = ". ${final_nvm_dir}${dirsep}nvm.sh && nvm use v${nodejs_version} &&"

  # Check if the mutex of $target and --global is correct, and set correct paths and flags
  if $target == undef and ! ('--global' in $install_options) {
    fail('The target parameter must be set when not using the --global option.')
  } elsif $target != undef and '--global' in $install_options {
    fail('The target parameter cannot be set when using the --global option.')
  } elsif '--global' in $install_options {
    $global_flag = '--global'
    $install_location = "${final_nvm_dir}${dirsep}versions${dirsep}node${dirsep}v${nodejs_version}${dirsep}lib"
  } else {
    $global_flag = undef
    $install_location = $target
  }

  $list_command = "${nvm_command_prefix} npm ${global_flag} ls --long --parseable"
  $install_check = "${list_command} | ${grep_command} ${install_check_package_string}"

  if $ensure == 'absent' {
    $npm_command = 'rm'
    $options = $uninstall_options_string

    if $use_package_json {
      exec { "nvm_${nodejs_version}_npm_${npm_command}_${package}":
        command  => "${nvm_command_prefix} npm ${npm_command} * ${options}",
        onlyif   => $list_command,
        cwd      => "${install_location}${dirsep}node_modules",
        provider => shell,
        require  => Nvm::Node::Install[$nodejs_version],
      }
    } else {
      exec { "nvm_${nodejs_version}_npm_${npm_command}_${package}":
        command  => "${nvm_command_prefix} npm ${npm_command} ${package_string} ${options}",
        onlyif   => $install_check,
        cwd      => $install_location,
        provider => shell,
        require  => Nvm::Node::Install[$nodejs_version],
      }
    }
  } else {
    $npm_command = 'install'
    $options = $install_options_string
    if $use_package_json {
      exec { "nvm_${nodejs_version}_npm_${npm_command}_${package}":
        command  => "${nvm_command_prefix} npm ${npm_command} ${options}",
        unless   => $list_command,
        user     => $user,
        cwd      => $install_location,
        environment => ["NVM_DIR=${final_nvm_dir}"],
        provider => shell,
        require  => Nvm::Node::Install[$nodejs_version],
      }
    } else {
      exec { "nvm_${nodejs_version}_npm_${npm_command}_${package}":
        command  => "${nvm_command_prefix} npm ${npm_command} ${package_string} ${options}",
        unless   => $install_check,
        user     => $user,
        cwd      => $install_location,
        environment => ["NVM_DIR=${final_nvm_dir}"],
        provider => shell,
        require  => Nvm::Node::Install[$nodejs_version],
      }
    }
  }
}
