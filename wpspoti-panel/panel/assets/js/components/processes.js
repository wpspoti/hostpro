function processesComponent() {
    return {
        processes: [], loading: true, search: '', autoRefresh: true, interval: null,
        async init() { await this.load(); this.interval = setInterval(() => { if (this.autoRefresh) this.load(); }, 5000); },
        async load() { try { const r = await API.get('/api/processes/list.php'); this.processes = r.data.processes || []; } catch(e) {} this.loading = false; },
        filtered() { if (!this.search) return this.processes; const s = this.search.toLowerCase(); return this.processes.filter(p => p.command.toLowerCase().includes(s) || p.user.toLowerCase().includes(s)); },
        async killProcess(pid) { if (!confirm('Kill process ' + pid + '?')) return; try { await API.post('/api/processes/kill.php', { pid }); await this.load(); API.toast('Process killed'); } catch(e) { API.toast(e.message, 'error'); } },
        destroy() { if (this.interval) clearInterval(this.interval); }
    };
}
