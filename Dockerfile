# Agent Zero for Railway: the official image, pinned by version and digest.
# Bump the tag and the digest together, and add a CHANGELOG.md entry.
FROM agent0ai/agent-zero:v2.16@sha256:0490714bf25bf481ea50d59ead21acec04344cee410a86b4e159908cb92ed8a2

COPY railway-start.sh railway-clean-venv.py /
# Record the venv's real file list (see railway-clean-venv.py for why).
RUN chmod 755 /railway-start.sh /railway-clean-venv.py \
 && sleep 1 \
 && find /opt/venv-a0 -xdev | LC_ALL=C sort > /opt/railway-venv-manifest.txt

# Agent Zero's web UI listens on port 80 inside the container (fixed upstream).
EXPOSE 80

CMD ["/railway-start.sh"]
