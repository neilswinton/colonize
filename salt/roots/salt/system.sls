{{ sls | replace('.','_') }}_nop:
  test.succeed_without_changes

{%- set system = pillar.get('system', {}) %}

/etc/ssh/sshd_config:
  file.blockreplace:
    - marker_start: "# Start managed zone {{sls}}  -- Do Not Edit"
    - marker_end: "# End managed zone {{sls}}  -- Do Not Edit"
    - prepend_if_not_found: True
    - sources: 
      - salt://sshd_config
    - watch_in:
      - service: sshd

sshd:
  service.running:
    - reload: True

