# [DEPRECATED] Puppet NVM

> 📌 **Deprecation Notice**
>
> This repository is deprecated and no more work will be done on this by [Alberto Varela](https://github.com/artberri). The usage of this plugin is discouraged and any future issues will not be fixed by its current author.
>
> I've [offered the plugin to the Voxpupuli community](https://groups.io/g/voxpupuli/message/484), but it seems they are not interested in adopting it. If you are interested in maintaining this plugin, don't hesitate to contact me.
>
> If you don't want to take over as a maintainer, but you still want to get feature/bugfix X into production open-source is all about forking, so go right ahead.

A puppet module to install (multiple versions of) Node.js with NVM (Node Version Manager).

#### Table of Contents

- [Puppet NVM](#puppet-nvm) - [Table of Contents](#table-of-contents)
  - [Module Description](#module-description)
  - [Setup](#setup)
    - [What nvm affects](#what-nvm-affects)
    - [Beginning with NVM](#beginning-with-nvm)
  - [Usage](#usage)
    - [Installing an specific version of Node.js](#installing-an-specific-version-of-nodejs)
    - [Installing multiple versions of Node.js](#installing-multiple-versions-of-nodejs)
    - [Installing Node.js globally](#installing-nodejs-globally)
    - [Installing Node.js global npm packages](#installing-nodejs-global-npm-packages)
  - [Reference](#reference)
    - [Class: `nvm`](#class-nvm)
      - [`user`](#user)
      - [`home`](#home)
      - [`nvm_dir`](#nvm_dir)
      - [`profile_path`](#profile_path)
      - [`version`](#version)
      - [`manage_user`](#manage_user)
      - [`manage_dependencies`](#manage_dependencies)
      - [`manage_profile`](#manage_profile)
      - [`nvm_repo`](#nvm_repo)
      - [`refetch`](#refetch)
      - [`install_node`](#install_node)
      - [`node_instances`](#node_instances)
    - [Define: `nvm::node::install`](#define-nvmnodeinstall)
      - [`user`](#user-1)
      - [`nvm_dir`](#nvm_dir-1)
      - [`version`](#version-1)
      - [`set_default` _\[Since version 1.1.0\]_](#set_default-since-version-110)
      - [`default` _\[Deprecated since version 1.1.0 use `set_default` instead\]_](#default-deprecated-since-version-110-use-set_default-instead)
      - [`from_source`](#from_source)
      - [`version_alias`](#version_alias)
    - [Define: `nvm::npm`](#define-nvmnpm)
      - [`nvm_dir`](#nvm_dir-2)
      - [`nodejs_version`](#nodejs_version)
      - [`target`](#target)
      - [`ensure`](#ensure)
      - [`cmd_exe_path`](#cmd_exe_path)
      - [`install_options`]($install_options)
      - [`package`](#package)
      - [`source`](#source)
      - [`uninstall_options`](#uninstall_options)
      - [`user`](#user-2)
      - [`use_package_json`](#use_package_json)
  - [Limitations](#limitations)
  - [Development](#development)
    - [Contributing](#contributing)
    - [Running tests](#running-tests)
      - [Testing quickstart](#testing-quickstart)

## Module Description

Node Version Manager (NVM) is a little bash script that allows you to manage multiple versions of Node.js on the same box. This Puppet module simplifies the task of installing it and allows to install unique or multiple versions of Node.js.

## Setup

### What nvm affects

- **Profile configuration:** By default this module will write in the user's `.bashrc` file, this behaviour can be modified with the `profile_path` or `manage_profile` parameters as is explained bellow.

**Warning:** If your are going to manage Node.js with NVM is highly recommended to uninstall any native Node.js installation.

### Beginning with NVM

To have Puppet install NVM with the default parameters, declare the nvm class (`user` is a required parameter):

```puppet
class { 'nvm':
  user => 'foo',
}
```

The Puppet module applies a default configuration: installs NVM to the selected user's home and adds it to `.bashrc`. Use the [Reference](#reference) section to find information about the class's parameters and their default values.

You can customize parameters when declaring the `nvm` class. For instance, this declaration will also install Node.js v0.12.7 as set it as defaul node:

```puppet
class { 'nvm':
  user         => 'foo',
  install_node => '0.12.7',
}
```

## Usage

### Installing an specific version of Node.js

This is the most common usage for NVM. It installs NVM to the `~/.nvm` folder, makes it available for the user adding the script to the `.bashrc` file, installs a Node.js version and sets it as default ensuring the dependencies.

```puppet
class { 'nvm':
  user         => 'foo',
  install_node => '0.12.7',
}
```

### Installing multiple versions of Node.js

Once NVM is installed you can install as many Node.js versions as you want.

```puppet
class { 'nvm':
  user => 'foo',
} ->

nvm::node::install { '0.12.7':
    user    => 'foo',
    set_default => true,
} ->

nvm::node::install { '0.10.36':
    user => 'foo',
} ->

nvm::node::install { 'iojs':
    user => 'foo',
}
```

Or:

```puppet
class { 'nvm':
  user           => 'foo',
  node_instances => {
    '0.12.7' => {
      set_default => true,
    },
    '0.10.36' => {},
    'iojs' => {},
  }
}
```

### Installing Node.js globally

It isn't the recommended way but you can install Node.js globally.

```puppet
class { 'nvm':
  user => 'root',
  nvm_dir => '/opt/nvm',
  version => 'v0.29.0',
  profile_path => '/etc/profile.d/nvm.sh',
  install_node => '0.12.7',
}
```

### Installing Node.js global npm packages

You can use this module with other Node.js puppet modules that allow to install NPM packages. For example with the [puppetlabs-nodejs](https://forge.puppetlabs.com/puppetlabs/nodejs) module.

```puppet
class { 'nvm':
  user => 'root',
  nvm_dir => '/opt/nvm',
  version => 'v0.29.0',
  profile_path => '/etc/profile.d/nvm.sh',
  install_node => '0.12.7',
}

package { 'forever':
  ensure   => 'present',
  provider => 'npm',
}
```

**Warning:** This module does not allow to install npm packages, this example asumes that you have also installed [puppetlabs-nodejs](https://forge.puppetlabs.com/puppetlabs/nodejs) module.

## Reference

### Class: `nvm`

Guides the basic setup and installation of NVM on your system. It requires `user` as parameter.

When this class is declared with the default options, Puppet:

- Installs the 0.29.0 version of NVM.
- Adds the `nvm.sh` script to the `.bashrc` file.
- Ensures packages `git`, `make` and `wget`.

You can simply declare the default `nvm` class:

```puppet
class { 'nvm':
  user => 'foo',
}
```

You can install a default Node.js version in this class, by using the `install_node` param.

**Parameters within `nvm`:**

#### `user`

Sets the user that will install NVM.

#### `home`

Indicates the user's home. It needs to be an existing directory if the `manage_user` is not set to `true`.

Default: `/home/${user}` (or `/root` if the user is `root`).

#### `nvm_dir`

Sets the directory where NVM is going to be installed.

Default: `/home/${user}/.nvm`.

#### `profile_path`

Sets the profile file where the `nvm.sh` is going to be loaded. Only used when `manage_profile` is set to `true` (default behaivour).

Default: `/home/${user}/.bashrc`.

#### `version`

Version of NVM that is going to be installed. Can point to any git reference of the [NVM project](https://github.com/creationix/nvm) (or the repo set in `ǹvm_repo` parameter).

Default: `v0.29.0`.

#### `manage_user`

Sets if the selected user will be created if not exists.

Default: `false`.

#### `manage_dependencies`

Sets if the module will manage the `git`, `wget`, `make` package dependencies.

Default: `true`.

#### `manage_profile`

Sets if the module will add the `nvm.sh` file to the user profile.

Default: `true`.

#### `nvm_repo`

Sets the NVM repo url that is going to be cloned.

Default: `https://github.com/creationix/nvm`.

#### `refetch`

Sets if the repo should be fetched again.

Default: `false`.

#### `install_node`

Installs a default Node.js version. Could be set to any NVM Node.js version name.

Default: `undef`.

#### `node_instances`

A hash with the node instances you want to install (it will be used to create `nvm::node::install` instances with `create_resources`).

Default: {}.

### Define: `nvm::node::install`

Installs a Node.js version.

**Parameters within `nvm::node::install`**:

#### `user`

Sets the user that will install Node.js.

#### `nvm_dir`

Sets the directory where NVM is going to be installed.

Default: `/home/${user}/.nvm`.

#### `version`

Node.js version. Could be set to any NVM Node.js version name.

Default: `0.12.7`.

#### `set_default` _[Since version 1.1.0]_

Determines whether to set this Node.js version as default.

#### `default` _[Deprecated since version 1.1.0 use `set_default` instead]_

This parameter is now deprecated because [is a reserved word](https://docs.puppetlabs.com/puppet/latest/reference/lang_reserved.html#reserved-words), use `set_default` instead. Backguard compatibilty is added but throws a warning message.

Determines whether to set this Node.js version as default.

Default: `false`.

#### `from_source`

Determines whether to install Node.js from sources.

Default: `false`.

#### `version_alias`

Alias this version to specified name

default: `undef`.

### Define: `nvm::npm`

Uses npm to manage packages using a specific nodejs version

**Parameters within `nvm::node::install`**

#### `nvm_dir`

The installation directory of `nvm`

#### `nodejs_version`

Version of Node.js to use. This needs to be installed

#### `target`

When managing a specific installation or project, run commands from this directory
This option is mutually exclusive with the `--global` install flag

Default: `undef`

#### `ensure`

Whether the package should be installed or removed. Use `present`,`absent` or a valid version/tag.

Default: `present`

#### `cmd_exe_path`

Used on windows installations to override the `cmd.exe` location

Default: see the `puppet_nodejs` module

#### `install_options`

Array of install options to be passed to npm

Default: []

#### `package` 

The package name you want to install/uninstall

#### `source`

Used in the building of the `package_string`. 

Default: `registry`

#### `uninstall_options`

Array of options to be used when uninstalling packages

Default: []

#### `user`

Sets the user running the `npm` commands

#### `use_package_json`

If set, this will read the `package.json` file at the current `target`, and install dependencies based on that file

Default: `false`


## Limitations

This module can not work on Windows and should work on LINUX systems.

This module is CI tested against [open source Puppet](http://docs.puppetlabs.com/puppet/) on:

- CentOS 6 and 7
- Ubuntu 12.04 and 14.04
- Debian 7

This module has been tested in several production servers (OpenLogic7 (Centos7) and Ubuntu 14.04) in Azure.

This module should also work properly in other distributions and operating systems, such as FreeBSD, Gentoo, and Amazon Linux, but is not formally tested on them.

Report an [issue](../../issues) if this module does not work properly in any Linux distro.

## Development

### Contributing

This modules is an open project, and community contributions are highly appreciated.

For more information, please read the complete [module contribution guide](CONTRIBUTING.md).

### Running tests

This project contains tests for both [rspec-puppet](http://rspec-puppet.com/) and [litmus](https://github.com/puppetlabs/puppet_litmus) to verify functionality. For detailed information on using these tools, please see their respective documentation.

#### Testing quickstart

```sh
gem install bundler
pdk bundle install
./spec/prepare_litmus_test.sh
pdk bundle exec rake litmus:acceptance:parallel
```
