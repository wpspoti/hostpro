function backupsComponent() {
    return {
        backups: [], schedules: [], loading: true, tab: 'backups', showCreate: false, showSchedule: false,
        form: { site_id: '', type: 'full' }, scheduleForm: { site_id: '', type: 'full', frequency: 'daily', time: '02:00', retention_count: 7 },
        sites: [], creating: false,
        async init() { try { const s = await API.get('/api/sites/list.php'); this.sites = s.data.sites || []; } catch(e) {} await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/backups/list.php'); this.backups = r.data.backups || []; const s = await API.get('/api/backups/schedule.php'); this.schedules = s.data.schedules || []; } catch(e) {} this.loading = false; },
        async create() { this.creating = true; try { await API.post('/api/backups/create.php', this.form); this.showCreate = false; await this.load(); API.toast('Backup started'); } catch(e) { API.toast(e.message, 'error'); } this.creating = false; },
        async restore(id) { if (!confirm('Restore this backup?')) return; try { await API.post('/api/backups/restore.php', { id }); API.toast('Restore started'); } catch(e) { API.toast(e.message, 'error'); } },
        async remove(id) { if (!confirm('Delete backup?')) return; try { await API.post('/api/backups/delete.php', { id }); await this.load(); } catch(e) {} },
        async saveSchedule() { try { await API.post('/api/backups/schedule.php', this.scheduleForm); this.showSchedule = false; await this.load(); API.toast('Schedule saved'); } catch(e) { API.toast(e.message, 'error'); } },
        formatSize(b) { if (!b) return '0 B'; const k = 1024, s = ['B','KB','MB','GB']; const i = Math.floor(Math.log(b)/Math.log(k)); return (b/Math.pow(k,i)).toFixed(1)+' '+s[i]; }
    };
}
