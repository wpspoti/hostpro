function monitoringComponent() {
    return {
        current: null, history: [], loading: true, range: '1h', cpuChart: null, ramChart: null,
        async init() { await this.load(); setInterval(() => this.loadCurrent(), 10000); },
        async load() { this.loading = true; await this.loadCurrent(); await this.loadHistory(); this.loading = false; },
        async loadCurrent() { try { const r = await API.get('/api/monitoring/realtime.php'); this.current = r.data; } catch(e) {} },
        async loadHistory() { try { const r = await API.get('/api/monitoring/history.php?range=' + this.range); this.history = r.data.history || []; this.$nextTick(() => this.renderCharts()); } catch(e) {} },
        async changeRange(r) { this.range = r; await this.loadHistory(); },
        renderCharts() {
            const labels = this.history.map(h => h.recorded_at.substr(11,5));
            if (this.cpuChart) this.cpuChart.destroy();
            if (this.ramChart) this.ramChart.destroy();
            const cpuCtx = document.getElementById('cpuHistChart');
            const ramCtx = document.getElementById('ramHistChart');
            if (cpuCtx) this.cpuChart = new Chart(cpuCtx, { type:'line', data:{ labels, datasets:[{ label:'Load 1m', data:this.history.map(h=>h.load_1), borderColor:'#4f46e5', tension:0.3, fill:false }] }, options:{ responsive:true, maintainAspectRatio:false, scales:{ y:{beginAtZero:true} } } });
            if (ramCtx) this.ramChart = new Chart(ramCtx, { type:'line', data:{ labels, datasets:[{ label:'RAM Used MB', data:this.history.map(h=>h.ram_used_mb), borderColor:'#059669', backgroundColor:'rgba(5,150,105,0.1)', tension:0.3, fill:true }] }, options:{ responsive:true, maintainAspectRatio:false } });
        },
        pct(used, total) { return total > 0 ? Math.round(used/total*100) : 0; }
    };
}
