#!/usr/bin/env bats

# Basic, readable sanity checks for the VNC playbook.

setup() {
  export PATH="$PWD/tests/fixtures/bin:$PATH"
}

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

@test "prints a single-line vncviewer command for a valid VM" {
  run env ANSIBLE_LOCAL_TEMP="$PWD/.ansible_tmp" ansible-playbook -i "localhost," -c local playbook_hostname.yml -e vm=test-vm
  if [[ "$output" == *"Unable to use multiprocessing"* ]]; then
    skip "ansible-playbook requires /dev/shm access in this environment"
  fi
  [ "$status" -eq 0 ]
  [[ "$output" =~ export\ VNC_PASSWORD=.*\ \&\&\ vncviewer\ .*:[0-9]+ ]]
  [[ "$output" != *"vnc://"* ]]
  [[ "$output" != *"::"* ]]
}

@test "fails for missing VM" {
  run env ANSIBLE_LOCAL_TEMP="$PWD/.ansible_tmp" ansible-playbook -i "localhost," -c local playbook_hostname.yml -e vm=missing-vm
  if [[ "$output" == *"Unable to use multiprocessing"* ]]; then
    skip "ansible-playbook requires /dev/shm access in this environment"
  fi
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found or no VNC display"* ]]
}

@test "quotes password when it contains shell metacharacters" {
  run env ANSIBLE_LOCAL_TEMP="$PWD/.ansible_tmp" ansible-playbook -i "localhost," -c local playbook_hostname.yml -e vm=weird-pass
  if [[ "$output" == *"Unable to use multiprocessing"* ]]; then
    skip "ansible-playbook requires /dev/shm access in this environment"
  fi
  [ "$status" -eq 0 ]
  [[ "$output" =~ export\ VNC_PASSWORD=\'.*\'\ \&\&\ vncviewer\ .*:[0-9]+ ]]
}
