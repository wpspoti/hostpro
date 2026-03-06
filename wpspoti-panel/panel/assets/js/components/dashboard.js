function dashboardComponent() {
    return {
        stats: null, loading: true, chart: null,
        async init() {
            await this.load();
            setInterval(() => this.load(), 30000);
        },
        async load() {
            try {
                const res = await API.get('/api/dashboard/stats.php');
                this.stats = res.data;
                this.$nextTick(() => this.renderChart());
            } catch(e) { console.error(e); }
            this.loading = false;
        },
        renderChart() {
            const ctx = document.getElementById('loadChart');
            if (!ctx || !this.stats) return;
            if (this.chart) this.chart.destroy();
            this.chart = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['Used RAM', 'Free RAM'],
                    datasets: [{ data: [this.stats.ram.used_mb, this.stats.ram.total_mb - this.stats.ram.used_mb], backgroundColor: ['#4f46e5','#e5e7eb'], borderWidth: 0 }]
                },
                options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } } }
            });
        },
        svcColor(s) { return s === 'active' ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'; }
    };
}
