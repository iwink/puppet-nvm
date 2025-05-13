# File pulled from the nodejs module.~
# See README.md for usage information.
define nvm::npm (
  Stdlib::Absolutepath            $nvm_dir,
  Pattern[/^\d+.\d+.\d+/]         $nodejs_version,
  Optional[Stdlib::Absolutepath]  $target             = undef,
  Pattern[/^[^<            >= ]/] $ensure             = 'present',
  Optional[Stdlib::Absolutepath]  $cmd_exe_path       = $nodejs::cmd_exe_path,
  Array                           $install_options    = [],
  String                          $package            = $title,
  String                          $source             = 'registry',
  Array                           $uninstall_options  = [],
  String                          $user               = 'root',
  Boolean                         $use_package_json   = false,
) {
  $install_options_string = join($install_options, ' ')
  $uninstall_options_string = join($uninstall_options, ' ')
  # Use the nvm command to set the node version
  $nvm_command_prefix = ". ${nvm_dir}/nvm.sh && nvm use ${nodejs_version} && "
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

  # Check if the mutex of $target and --global is correct, and set correct paths and flags
  if $target == undef and ! ('--global' in $install_options) {
    fail("The target parameter must be set when not using the --global option.")
  } elsif $target != undef and '--global' in $install_options {
    fail("The target parameter cannot be set when using the --global option.")
  } elsif '--global' in $install_options {
    $global_flag = "--global"
    $install_location = "${nvm_dir}${dirsep}versions${dirsep}node${dirsep}v${nodejs_version}/lib"
  } else {
    $global_flag = undef
    $install_location = $target
  }

   $list_command = "${nvm_command_prefix} npm ${global_flag} ls --long --parseable"
  $install_check = "${list_command} | ${grep_command} ${install_check_package_string}"
  # set a sensible path on Unix
  $exec_path = $facts['os']['family'] ? {
    'Windows' => undef,
    'Darwin'  => ['/bin', '/usr/bin', '/opt/local/bin', '/usr/local/bin'],
    default    => ['/bin', '/usr/bin', '/usr/local/bin'],
  }

  if $ensure == 'absent' {
    $npm_command = 'rm'
    $options = $uninstall_options_string

    if $use_package_json {
      exec { "nvm_npm_${npm_command}_${name}":
        command => "${nvm_command_prefix} npm ${npm_command} * ${options}",
        path    => $exec_path,
        onlyif  => $list_command,
        cwd     => "${install_location}${dirsep}node_modules",
        provider => shell,
        require => Nvm::Node::Install[$nodejs_version],
      }
    } else {
      exec { "nvm_npm_${npm_command}_${name}":
        command => "${nvm_command_prefix} npm ${npm_command} ${package_string} ${options}",
        path    => $exec_path,
        onlyif  => $install_check,
        cwd     => $install_location,
        provider => shell,
        require => Nvm::Node::Install[$nodejs_version],
      }
    }
  } else {
    $npm_command = 'install'
    $options = $install_options_string
    # Conditionally require proxy and https-proxy to be set first only if the resource exists.
    Nodejs::Npm::Global_config_entry<| title == 'https-proxy' |> -> Exec["npm_install_${name}"]
    Nodejs::Npm::Global_config_entry<| title == 'proxy' |> -> Exec["npm_install_${name}"]

    if $use_package_json {
      exec { "nvm_npm_${npm_command}_${name}":
        command     => "${nvm_command_prefix} npm ${npm_command} ${options}",
        path        => $exec_path,
        unless      => $list_command,
        user        => $user,
        cwd         => $install_location,
        provider    => shell,
        require     => Nvm::Node::Install[$nodejs_version],
      }
    } else {
      exec { "nvm_npm_${npm_command}_${name}":
        command     => "${nvm_command_prefix} npm ${npm_command} ${package_string} ${options}",
        path        => $exec_path,
        unless      => $install_check,
        user        => $user,
        cwd         => $install_location,
        provider    => shell,
        require     => Nvm::Node::Install[$nodejs_version],
      }
    }
  }
}
