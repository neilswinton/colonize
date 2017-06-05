{{ sls | replace('.','_') }}_nop:
  test.succeed_without_changes

{%- set system = pillar.get('system', {}) %}

{%- if 'hostname' in system %}
system:
  network.system:
    - hostname: {{ system['hostname'] }}
    - apply_hostname: True
{%- endif %}
