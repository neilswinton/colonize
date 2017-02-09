{% set user = pillar.get("user", {}) %}

{{ sls }}_packages:
  pkg.latest:
    - pkgs:
      - emacs
      - git
