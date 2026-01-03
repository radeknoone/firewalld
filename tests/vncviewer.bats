#!/usr/bin/env bats

# Basic, readable sanity checks for the VNC playbook.

@test "playbook passes syntax check" {
  if ! command -v ansible-playbook >/dev/null; then
    skip "ansible-playbook not installed"
  fi

  mkdir -p .ansible_tmp
  run env ANSIBLE_LOCAL_TEMP="$PWD/.ansible_tmp" ansible-playbook --syntax-check playbook_hostname.yml
  [ "$status" -eq 0 ]
}

@test "playbook references vm variable and virsh domdisplay" {
  run grep -q "virsh domdisplay --include-password" playbook_hostname.yml
  [ "$status" -eq 0 ]

  run grep -q "vm" playbook_hostname.yml
  [ "$status" -eq 0 ]
}
