function databasesComponent() {
    return {
        databases: [], loading: true, showCreate: false, showDelete: false, deleteId: null,
        form: { db_name: '', db_user: '', db_password: '' }, creating: false, error: '',
        async init() { await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/databases/list.php'); this.databases = r.data.databases || []; } catch(e) {} this.loading = false; },
        generatePassword() { this.form.db_password = Array.from(crypto.getRandomValues(new Uint8Array(16))).map(b => b.toString(16).padStart(2,'0')).join('').slice(0,16); },
        async create() {
            this.creating = true; this.error = '';
            try { await API.post('/api/databases/create.php', this.form); this.showCreate = false; this.form = { db_name: '', db_user: '', db_password: '' }; await this.load(); API.toast('Database created'); } catch(e) { this.error = e.message; }
            this.creating = false;
        },
        async confirmDelete() { try { await API.post('/api/databases/delete.php', { id: this.deleteId }); this.showDelete = false; await this.load(); API.toast('Database deleted'); } catch(e) { API.toast(e.message, 'error'); } }
    };
}
