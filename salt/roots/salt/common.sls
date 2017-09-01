{{ sls | replace('.','_') }}_nop:
  test.succeed_without_changes

# {{ sls }}_packages:
#   pkg.latest:
#     - pkgs:
#       - xorg-x11-xauth

# Loop over the users
{%- for userkey,args in pillar.get('users', {}).iteritems() %}
{%- set username = args.get('name', userkey) %}
# Setup for {{ username }}

{{ username }}:
   user.present:
     - fullname: args['fullname']      

{%- if 'sudoer' in args and args['sudoer'] %}
/etc/sudoers.d/{{ username }}:
  file.managed:           
    - contents: "%{{ username }} ALL=(ALL) NOPASSWD: ALL"
    - require:
      - user: {{ username }}
{%- endif  %}

{%- set snippets = args.get('snippets', []) %}
{%- for snippet in snippets %}
{%- for snippet_path,snippet_info in snippet.iteritems() %}
{{ username }}-{{ snippet_path }}_create:
  file.managed:
    - name: ~{{ username }}/{{ snippet_path }}
    - replace: False
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - user: {{ username }}

# {{ snippet_info }}
{%- set language_to_comment_character = {'lisp': ';', 'shell': '#'} %}
{%- set snippet_language = snippet_info.get('language', 'shell') %}
{%- set comment_character = language_to_comment_character[snippet_language] %}
{{ username }}-{{ snippet_path }}:
  file.blockreplace:
    - name: ~{{ username }}/{{ snippet_path }}
    - content: '{{ snippet_info.get("contents", "") }}'
    - append_if_not_found: true
    - marker_start: "{{ comment_character }} Begin salt managed zone {{ sls }}:{{ username }} -- DO NOT EDIT"
    - marker_end: "{{ comment_character }} End salt managed zone {{ sls }}:{{ username }}"
    - require:
      - file: {{ username }}-{{ snippet_path }}_create
{%- endfor %} {# for snippet_path,snippet_info in snippet.iteritems() #}
{%- endfor %} {# for snippet in snippets  #}

{%- set bash_profile = args.get('bash_profile', {}) %}
{%- if bash_profile %}
# {{ username }} Bash Profile

{{ username }}_bash_profile_create:
  file.managed:
    - name: ~{{ username }}/.bash_profile
    - replace: False
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - user: {{ username }}


{%- for env in bash_profile.get('environment', []) %}
# {{ env }}
{%- for key,value in env.iteritems() %}
# {{ key }} {{ value }}
{{ username }}-bash_profile-{{ key }}:
  file.accumulated:
    - name: {{ username }}-bash_profile-accumulator
    - filename: /home/{{ username }}/.bash_profile
    - text: 'export {{ key }}={{value}}'
    - require_in:
      - file: {{ username }}-bash_profile
{%- endfor %} {# for key,value in env.get('', {}).iteritems() #}
{%- endfor %} {# for env in bash_profile.get('environment', [] #}

{%- for item in bash_profile.get('include', []) %}
# {{ item }}
{{ username }}-bash_profile-{{ item }}:
  file.accumulated:
    - name: {{ username }}-bash_profile-accumulator
    - filename: /home/{{ username }}/.bash_profile
    - text: | 
        test -r "{{ item }}" && source "{{ item }}"
    - require_in:
      - file: {{ username }}-bash_profile
{%- endfor %} {# for item in bash_profile.get('include', []) #}

{{ username }}-bash_profile-coda:
  file.accumulated:
    - name: {{ username }}-bash_profile-accumulator
    - filename: /home/{{ username }}/.bash_profile
    - text: |
        # 
        # 
    - require_in:
      - file: {{ username }}-bash_profile

{{ username }}-bash_profile:
  file.blockreplace:
    - name: /home/{{ username }}/.bash_profile
    - append_if_not_found: true
    - marker_start: "# Begin salt managed zone {{ sls }}:{{ username }} -- DO NOT EDIT"
    - marker_end: "# End salt managed zone {{ sls }}:{{ username }}"
    - require:
      - user: {{ username }}
      - file: {{ username }}_bash_profile_create

{%- endif %} {# if bash_profile #}


{%- set pkgs = args.get('packages', []) %}
{%- if pkgs %}
# {{ username }} PKG settings
{{ username }}/packages:
  pkg.installed:
    - require:
      - user: {{ username }}
    - pkgs:
{%- for pkg in pkgs %}
      - {{ pkg }}
{%- endfor %} {# for pkg in pkgs #}
{%- endif %} {# if pkgs #}

{%- set active_profiles = args.get('active_profiles', []) %}
{%- set all_profiles = args.get('profiles', []) %}

# active_profiles: {{ active_profiles }}
# all_profiles: {{ all_profiles }}
{%- for profile_name in active_profiles %}
# profile: {{ profile_name }}
{%- if profile_name in all_profiles %}
# {{ all_profiles.get(profile_name) }}
{{ username }}_profile_{{ profile_name }}:
  pkg.installed:
    - require:
      - user: {{ username }}
    - pkgs:
{%- for pkg in all_profiles.get(profile_name).get('pkg', []) %}
      - {{ pkg }}
{%- endfor %} {# for pkg in pkgs #}
    
{%- endif %}
{%- endfor  %} {# for profile_name in active_profiles #}

{%- set ssh = args.get('ssh', {}) %}
{%- if ssh %}
# {{ username }} SSH settings
{{ username }}/.ssh:
  file.directory:
    - name: ~{{ username }}/.ssh
    - user: {{ username }}
    - group: {{ username }}
    - mode: 700
    - require:
      - user: {{ username }}
    
{%- if 'private_keys' in ssh and ssh['private_keys'] %}
{%- for name,key in ssh.get('private_keys', {}).iteritems() %}
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
{%- endfor %} {# for name,key in pillar.get('private_keys', #}
{%- endif  %} {# if 'private_keys' #}

{%- if 'public_keys' in ssh and ssh['public_keys'] %}
{%- for name,key in ssh.get('public_keys', {}).iteritems() %}
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
{%- endfor %} {# for name,key in pillar.get('public_keys', #}
{%- endif  %} {# if 'public_keys' #}
{%- endif  %} {# if ssh #}

{%- if 'git' in args and args['git'] %}
{%- set git = args['git'] %}
{%- if 'config' in git %} 
{%- for kvpair in git['config'] %}
{%- for key,value in kvpair.iteritems() %}
{{ username }}_git_{{ key | replace('.','_') }}:
  git.config_set:
    - name: {{ key }}
    - value: {{ value }}
    - user: {{ username }}
    - global: True
    - require:
      - user: {{ username }}
{%- endfor %} {# for key,value in  #}
{%- endfor %} {# for kvpair in  #}
{%- endif  %} {# if config in git #}

{%- if 'repos' in git %} 
{%- for repo,args in git['repos'].iteritems() %}
{# set args['name'] = args.get('name', repo)  #}
{{ username }}-git-{{ repo }}:
  git.latest: {{ args }}
{%- endfor %} {# for key,value in git['repos'] #}
{%- endif  %} {# if repos in git #}
{%- endif  %} {# if git #}
{%- endfor %}

