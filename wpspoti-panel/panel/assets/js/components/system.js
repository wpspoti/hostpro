function systemComponent() {
    return {
        info: null, settings: {}, loading: true, saving: false,
        async init() { await this.load(); },
        async load() { this.loading = true; try {
            const r = await API.get('/api/system/info.php'); this.info = r.data;
            const s = await API.get('/api/system/settings.php'); this.settings = s.data.settings || {};
        } catch(e) {} this.loading = false; },
        async saveSettings() { this.saving = true; try { await API.post('/api/system/settings.php', { settings: this.settings }); API.toast('Settings saved'); } catch(e) { API.toast(e.message, 'error'); } this.saving = false; }
    };
}
