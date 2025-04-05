# Use the latest Arch image
FROM archlinux:latest

# Create a non-root user and group
RUN useradd -r -u 1000 -g users -d /home/serviceuser -m -s /bin/bash serviceuser

# Install base packages and Dovecot
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm dovecot pigeonhole dovecot-fts-xapian spamassassin \
                          sudo fetchmail clamav unbound git ca-certificates-utils \
                          inotify-tools base-devel perl perl-dbi \
                          perl-dbd-sqlite perl-libwww perl-net-cidr-lite \
                          perl-archive-zip perl-io-string perl-email-address-xs \
                          perl-devel-cycle perl-text-diff cpanminus perl-net-idn-encode \
                          perl-net-libidn2 perl-geoip libmaxminddb libcap

# Perl modules that are not wrapped in pacman packages
RUN /usr/bin/vendor_perl/cpanm --notest MaxMind::DB::Reader Math::Int128 Math::Int64 \
    Net::Works::Network Path::Class Test::Number::Delta Test::Requires \
    MaxMind::DB::Reader::XS IP::Country IP::Country::Fast Razor2::Client::Agent \
    Encode::Detect BSD::Resource Mail::DMARC Net::Patricia

# Clean up
RUN pacman -Scc --noconfirm && rm -rf /var/cache/pacman/pkg/* /root/.cpanm /tmp/*

# Generate dh.pem for Dovecot
RUN mkdir -p /opt/dovecot && openssl dhparam -out "/opt/dovecot/dh.pem" 2048 && \
    chmod 600 /opt/dovecot/dh.pem

# /opt/sieve will be mounted as a volume later but we grant privileges here so that
# Dovecot can write a binary config
RUN mkdir -p /opt/sieve && chown serviceuser:users /opt/sieve

# Configure freshclam to skip daemon notification as we're not running clamd
RUN sed -i '/^NotifyClamd/s/^/#/' /etc/clamav/freshclam.conf

# Grant sudo to serviceuser for select executables only
RUN printf "serviceuser ALL=(ALL) NOPASSWD: /usr/sbin/dovecot, /usr/sbin/fetchmail, \
          /usr/bin/unbound-anchor, /usr/sbin/freshclam, /usr/sbin/update-ca-trust, \
          /usr/sbin/unbound, /usr/local/bin/fetchmultimail, \
          /usr/bin/vendor_perl/sa-update, /usr/local/bin/make-user, \
          /usr/bin/vendor_perl/sa-learn\n" >> /etc/sudoers

# Define some env vars to keep when preserving during sudo
RUN printf "Defaults env_keep += \"PASSKEY TIMEZONE IMAP_SERVER LOG_DEBUG\"\n" >> /etc/sudoers

# Use our non-root user to run the services
USER serviceuser

# Expose ports (IMAP, managesieve)
EXPOSE 993 4190

CMD ["/usr/local/bin/start"]
