function sslComponent() {
    return {
        certs: [], loading: true, showIssue: false, issueForm: { domain: '' }, issuing: false,
        async init() { await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/ssl/list.php'); this.certs = r.data.certificates || []; } catch(e) {} this.loading = false; },
        async issue() { this.issuing = true; try { await API.post('/api/ssl/issue.php', this.issueForm); this.showIssue = false; this.issueForm = { domain: '' }; await this.load(); API.toast('SSL certificate issued'); } catch(e) { API.toast(e.message, 'error'); } this.issuing = false; },
        async renew(domain) { try { await API.post('/api/ssl/renew.php', { domain }); await this.load(); API.toast('Certificate renewed'); } catch(e) { API.toast(e.message, 'error'); } },
        statusBadge(s) { return s === 'valid' ? 'badge-green' : s === 'expiring' ? 'badge-yellow' : 'badge-red'; },
        daysLeft(expires) { if (!expires) return 'N/A'; const d = Math.floor((new Date(expires) - new Date()) / 86400000); return d > 0 ? d + ' days' : 'Expired'; }
    };
}
