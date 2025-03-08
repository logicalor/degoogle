# Use the latest Debian image
FROM archlinux:latest

# Install base packages and Dovecot
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm dovecot pigeonhole dovecot-fts-elastic spamassassin fetchmail clamav unbound \
        git ca-certificates-utils inotify-tools && \
    pacman -Scc --noconfirm && rm -rf /var/cache/pacman/pkg/* /tmp/*
RUN freshclam || true
RUN unbound-anchor -v -a /etc/unbound/root.key || true
RUN update-ca-trust

RUN chage -E -1 unbound

# Expose ports (adjust based on your needs)
EXPOSE 143 993 110 995

# Start Dovecot
CMD ["/usr/local/bin/start.sh"]
