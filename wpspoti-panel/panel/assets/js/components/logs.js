function logsComponent() {
    return {
        logFiles: [], logContent: '', selectedLog: '', loading: true, lines: 100, search: '', autoScroll: true,
        async init() { await this.loadFiles(); },
        async loadFiles() { this.loading = true; try { const r = await API.get('/api/logs/list.php'); this.logFiles = r.data.files || []; if (this.logFiles.length) { this.selectedLog = this.logFiles[0]; await this.loadLog(); } } catch(e) {} this.loading = false; },
        async loadLog() { try { const r = await API.get(`/api/logs/read.php?file=${encodeURIComponent(this.selectedLog)}&lines=${this.lines}&search=${encodeURIComponent(this.search)}`); this.logContent = r.data.content || ''; if (this.autoScroll) this.$nextTick(() => { const el = this.$refs.logViewer; if (el) el.scrollTop = el.scrollHeight; }); } catch(e) { this.logContent = 'Error loading log'; } },
        async refresh() { await this.loadLog(); }
    };
}
