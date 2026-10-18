# Odoo Community. Pin a major version for compatibility with custom addons.
FROM odoo:19.0

# Keep the database-manager secret out of Git and inject at runtime.
COPY --chown=odoo:odoo --chmod=0755 docker/odoo/start.sh /usr/local/bin/odoo-start.sh
ENTRYPOINT ["/usr/local/bin/odoo-start.sh"]
CMD []
