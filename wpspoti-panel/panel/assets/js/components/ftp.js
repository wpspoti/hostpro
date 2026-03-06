function ftpComponent() {
    return {
        accounts: [], loading: true, showCreate: false,
        form: { username: '', password: '', home_directory: '/var/www' }, creating: false,
        async init() { await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/ftp/list.php'); this.accounts = r.data.accounts || []; } catch(e) {} this.loading = false; },
        async create() { this.creating = true; try { await API.post('/api/ftp/create.php', this.form); this.showCreate = false; this.form = { username: '', password: '', home_directory: '/var/www' }; await this.load(); API.toast('FTP account created'); } catch(e) { API.toast(e.message, 'error'); } this.creating = false; },
        async remove(id) { if (!confirm('Delete this FTP account?')) return; try { await API.post('/api/ftp/delete.php', { id }); await this.load(); API.toast('Deleted'); } catch(e) { API.toast(e.message, 'error'); } }
    };
}
