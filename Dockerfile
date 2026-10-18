# Odoo Community. Pin a major version for compatibility with custom addons.
FROM odoo:19.0

# Normalize shell-script line endings in case a Windows checkout introduced CRLF.
COPY --chown=odoo:odoo --chmod=0755 docker/odoo/start.sh /usr/local/bin/odoo-start.sh
USER root
RUN sed -i 's/\r$//' /usr/local/bin/odoo-start.sh && chmod 0755 /usr/local/bin/odoo-start.sh
USER odoo

# Keep the database-manager secret out of Git and inject it at runtime.
ENTRYPOINT ["/usr/local/bin/odoo-start.sh"]
CMD []
