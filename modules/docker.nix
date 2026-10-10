{ pkgs, ... }:

{
  # Docker container runtime.
  virtualisation.docker.enable = true;

  # Automatic garbage collection: once a week, prune stopped containers, unused
  # networks/build cache and unused images older than 7 days. `-a` also removes
  # images not referenced by any container, `-f` skips the confirmation prompt,
  # and `--filter until` spares anything younger than 7 days.
  systemd.services.docker-gc = {
    description = "Docker garbage collection";
    after = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker system prune -af --filter until=168h";
    };
  };

  systemd.timers.docker-gc = {
    description = "Run Docker garbage collection weekly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
