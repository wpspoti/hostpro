function sitesComponent() {
    return {
        sites: [], loading: true, showCreate: false, showDelete: false, deleteId: null,
        form: { domain: '', php_version: '8.3', install_wordpress: false },
        creating: false, error: '',
        async init() { await this.load(); },
        async load() {
            this.loading = true;
            try { const r = await API.get('/api/sites/list.php'); this.sites = r.data.sites || []; } catch(e) {}
            this.loading = false;
        },
        async create() {
            this.creating = true; this.error = '';
            try {
                const fd = new FormData();
                fd.append('domain', this.form.domain);
                fd.append('php_version', this.form.php_version);
                await API.post('/api/sites/create.php', fd);
                if (this.form.install_wordpress) {
                    await API.post('/api/sites/wordpress.php', { domain: this.form.domain });
                    API.toast('WordPress installed on ' + this.form.domain);
                }
                this.showCreate = false;
                this.form = { domain: '', php_version: '8.3', install_wordpress: false };
                await this.load();
                API.toast('Site created successfully');
            } catch(e) { this.error = e.message || 'Failed'; }
            this.creating = false;
        },
        async confirmDelete() {
            try {
                await API.post('/api/sites/delete.php', { id: this.deleteId });
                this.showDelete = false;
                await this.load();
                API.toast('Site deleted');
            } catch(e) { API.toast(e.message, 'error'); }
        },
        sslBadge(s) { return s ? 'badge-green' : 'badge-yellow'; }
    };
}
