function filemanagerComponent() {
    return {
        files: [], currentPath: '/', sites: [], selectedSite: '', loading: true,
        showEditor: false, showUpload: false, showMkdir: false, showChmod: false,
        editorFile: '', editorContent: '', newDirName: '', chmodFile: '', chmodValue: '755',
        async init() {
            try { const r = await API.get('/api/sites/list.php'); this.sites = r.data.sites || []; if (this.sites.length) { this.selectedSite = this.sites[0].domain; await this.load(); } } catch(e) {}
            this.loading = false;
        },
        async load() {
            this.loading = true;
            try { const r = await API.get(`/api/files/list.php?site=${this.selectedSite}&path=${encodeURIComponent(this.currentPath)}`); this.files = r.data.files || []; } catch(e) { this.files = []; }
            this.loading = false;
        },
        async navigate(name, isDir) {
            if (isDir) { this.currentPath = this.currentPath.replace(/\/$/, '') + '/' + name; await this.load(); }
            else { await this.editFile(name); }
        },
        goUp() { const parts = this.currentPath.split('/').filter(Boolean); parts.pop(); this.currentPath = '/' + parts.join('/'); this.load(); },
        breadcrumbs() { const parts = this.currentPath.split('/').filter(Boolean); return parts.map((p, i) => ({ name: p, path: '/' + parts.slice(0, i+1).join('/') })); },
        async editFile(name) {
            try { const r = await API.get(`/api/files/read.php?site=${this.selectedSite}&path=${encodeURIComponent(this.currentPath + '/' + name)}`); this.editorFile = name; this.editorContent = r.data.content; this.showEditor = true; } catch(e) { API.toast(e.message, 'error'); }
        },
        async saveFile() {
            try { await API.post('/api/files/write.php', { site: this.selectedSite, path: this.currentPath + '/' + this.editorFile, content: this.editorContent }); this.showEditor = false; API.toast('File saved'); } catch(e) { API.toast(e.message, 'error'); }
        },
        async uploadFile(e) {
            const file = e.target.files[0]; if (!file) return;
            try { await API.upload('/api/files/upload.php', file, { site: this.selectedSite, path: this.currentPath }); this.showUpload = false; await this.load(); API.toast('File uploaded'); } catch(e) { API.toast(e.message, 'error'); }
        },
        async createDir() {
            try { await API.post('/api/files/mkdir.php', { site: this.selectedSite, path: this.currentPath + '/' + this.newDirName }); this.showMkdir = false; this.newDirName = ''; await this.load(); } catch(e) { API.toast(e.message, 'error'); }
        },
        async deleteFile(name) {
            if (!confirm('Delete ' + name + '?')) return;
            try { await API.post('/api/files/delete.php', { site: this.selectedSite, path: this.currentPath + '/' + name }); await this.load(); API.toast('Deleted'); } catch(e) { API.toast(e.message, 'error'); }
        },
        async changePerms() {
            try { await API.post('/api/files/chmod.php', { site: this.selectedSite, path: this.currentPath + '/' + this.chmodFile, mode: this.chmodValue }); this.showChmod = false; await this.load(); } catch(e) { API.toast(e.message, 'error'); }
        },
        downloadFile(name) { window.open(`/api/files/download.php?site=${this.selectedSite}&path=${encodeURIComponent(this.currentPath + '/' + name)}`); },
        icon(f) { return f.is_dir ? 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z' : 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'; }
    };
}
