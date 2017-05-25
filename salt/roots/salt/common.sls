{{ sls | replace('.','_') }}_nop:
  test.succeed_without_changes

{{ sls }}_packages:
  pkg.latest:
    - pkgs:
      - xorg-x11-xauth
