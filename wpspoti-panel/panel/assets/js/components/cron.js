function cronComponent() {
    return {
        jobs: [], loading: true, showCreate: false,
        form: { minute: '*', hour: '*', day_of_month: '*', month: '*', day_of_week: '*', command: '', description: '' },
        presets: [
            { label: 'Every minute', v: { minute:'*',hour:'*',day_of_month:'*',month:'*',day_of_week:'*' } },
            { label: 'Every 5 min', v: { minute:'*/5',hour:'*',day_of_month:'*',month:'*',day_of_week:'*' } },
            { label: 'Hourly', v: { minute:'0',hour:'*',day_of_month:'*',month:'*',day_of_week:'*' } },
            { label: 'Daily midnight', v: { minute:'0',hour:'0',day_of_month:'*',month:'*',day_of_week:'*' } },
            { label: 'Weekly Sun', v: { minute:'0',hour:'0',day_of_month:'*',month:'*',day_of_week:'0' } },
            { label: 'Monthly', v: { minute:'0',hour:'0',day_of_month:'1',month:'*',day_of_week:'*' } },
        ],
        async init() { await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/cron/list.php'); this.jobs = r.data.jobs || []; } catch(e) {} this.loading = false; },
        applyPreset(p) { Object.assign(this.form, p.v); },
        schedule(j) { return `${j.minute} ${j.hour} ${j.day_of_month} ${j.month} ${j.day_of_week}`; },
        async create() { try { await API.post('/api/cron/create.php', this.form); this.showCreate = false; this.form = { minute:'*',hour:'*',day_of_month:'*',month:'*',day_of_week:'*',command:'',description:'' }; await this.load(); API.toast('Cron job created'); } catch(e) { API.toast(e.message, 'error'); } },
        async remove(id) { if (!confirm('Delete cron job?')) return; try { await API.post('/api/cron/delete.php', { id }); await this.load(); } catch(e) {} },
        async toggle(id) { try { await API.post('/api/cron/toggle.php', { id }); await this.load(); } catch(e) {} }
    };
}
