{{ sls | replace('.','_') }}_nop:
  test.succeed_without_changes

{{ sls }}_packages:
  pkg.latest:
    - pkgs:
      - xorg-x11-xauth

# Loop over the users
{% for userkey,args in pillar.get('users', {}).iteritems() %}
{% set username = args.get('name', userkey) %}
# Setup for {{ username }}

{{ username }}:
   user.present:
     - fullname: args['fullname']      

{% if 'sudoer' in args and args['sudoer'] %}
/etc/sudoers.d/{{ username }}:
  file.managed:           
    - contents: "%{{ username }} ALL=(ALL) NOPASSWD: ALL"
    - require:
      - user: {{ username }}
{% endif  %}

{% set bash_profile = args.get('bash_profile', {}) %}
{% if bash_profile %}
# {{ username }} Bash Profile
{% for env in bash_profile.get('environment', []) %}
# {{ env }}
{% for key,value in env.iteritems() %}
# {{ key }} {{ value }}
{{ username }}-bash_profile-{{ key }}:
  file.accumulated:
    - name: {{ username }}-bash_profile-accumulator
    - filename: /home/{{ username }}/.bash_profile
    - text: |
         export {{ key }}={{value}}
         
    - require_in:
      - file: {{ username }}-bash_profile
{% endfor %} {# for key,value in env.get('', {}).iteritems() #}
{% endfor %} {# for env in bash_profile.get('environment', [] #}

{{ username }}-bash_profile:
  file.blockreplace:
    - name: /home/{{ username }}/.bash_profile
    - append_if_not_found: true
    - marker_start: "# begin managed zone {{ sls }}:{{ username }}"
    - marker_end: "# end managed zone {{ sls }}:{{ username }}"
{% endif %} {# if bash_profile #}


{% set ssh = args.get('ssh', {}) %}
{% if ssh %}
# {{ username }} SSH settings
{{ username }}/.ssh:
  file.directory:
    - name: ~{{ username }}/.ssh
    - user: {{ username }}
    - group: {{ username }}
    - mode: 700
    
{% if 'private_keys' in ssh and ssh['private_keys'] %}
{% for name,key in ssh.get('private_keys', {}).iteritems() %}
{{ username }}_private_keys_{{name}}:
  file.managed:
    - name: ~{{ username }}/.ssh/{{name}}
    - user: {{ username }}
    - group: {{ username }}
    - mode: 400
    - contents_pillar: users:{{ username }}:ssh:private_keys:{{ name }}
    - require:
      - user: {{ username }}
      - file: {{ username }}/.ssh
{% endfor %} {# for name,key in pillar.get('private_keys', #}
{% endif  %} {# if 'private_keys' #}

{% if 'public_keys' in ssh and ssh['public_keys'] %}
{% for name,key in ssh.get('public_keys', {}).iteritems() %}
{{ username }}_public_keys_{{name}}:
  file.managed:
    - name: ~{{ username }}/.ssh/{{name}}
    - user: {{ username }}
    - group: {{ username }}
    - mode: 444
    - contents_pillar: users:{{ username }}:ssh:public_keys:{{ name }}
    - require:
      - user: {{ username }}
      - file: {{ username }}/.ssh
{% endfor %} {# for name,key in pillar.get('public_keys', #}
{% endif  %} {# if 'public_keys' #}
{% endif  %} {# if ssh #}

{% if 'git' in args and args['git'] %}
{% set git = args['git'] %}
{% if 'config' in git %} 
{% for kvpair in git['config'] %}
{% for key,value in kvpair.iteritems() %}
{{ username }}_git_{{ key | replace('.','_') }}:
  git.config_set:
    - name: {{ key }}
    - value: {{ value }}
    - user: {{ username }}
    - global: True
{% endfor %} {# for key,value in  #}
{% endfor %} {# for kvpair in  #}
{% endif  %} {# if config in git #}

{% if 'repos' in git %} 
{% for repo,args in git['repos'].iteritems() %}
{# set args['name'] = args.get('name', repo)  #}
{{ username }}-git-{{ repo }}:
  git.latest: {{ args }}
{% endfor %} {# for key,value in git['repos'] #}
{% endif  %} {# if repos in git #}
{% endif  %} {# if git #}
{% endfor %}

