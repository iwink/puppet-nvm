#!/usr/bin/env bash
pdk bundle exec rake litmus:provision_list[docker]
pdk bundle exec rake litmus:install_agent
pdk bundle exec bolt task run provision::fix_secure_path --modulepath spec/fixtures/modules -i spec/fixtures/litmus_inventory.yaml -t ssh_nodes
pdk bundle exec rake litmus:install_module
