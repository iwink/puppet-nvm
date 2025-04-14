# @summary Install a node package using the supplied Node version
#
# @param version The package version to install
# @param node_version The Node version to use
# @param package The package name to install
# @param nvm_dir The NVM directory to use
define nvm::node::install_package (
  String $version,
  String $node_version,
  String $package = $title,
  String $nvm_dir = '/opt/nvm',
) {
  if ! defined(Class['nvm']) {
    fail('You must include the nvm base class before using any nvm defined resources')
  }

  exec { "nvm install package ${title} with version ${version} for node version ${node_version}":
    command     => ". ${nvm_dir}/nvm.sh && nvm use ${node_version} && npm install --global --unsafe-perm ${package}@${version}",
    user        => 'root',
    unless      => ". ${nvm_dir}/nvm.sh && nvm use ${node_version} && npm list --global --depth=0 | grep -q ${package}@${version}",
    environment => ["NVM_DIR=${nvm_dir}"],
    provider    => shell,
  }
}
