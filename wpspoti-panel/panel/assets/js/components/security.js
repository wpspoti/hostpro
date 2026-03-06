function securityComponent() {
    return {
        fail2ban: null, blockedIps: [], auditLog: [], loading: true, tab: 'fail2ban',
        blockForm: { ip: '', reason: '' }, auditPage: 1, auditTotal: 0,
        async init() { await this.load(); },
        async load() { this.loading = true; try {
            const f = await API.get('/api/security/fail2ban.php'); this.fail2ban = f.data;
            const b = await API.get('/api/security/blocked-ips.php'); this.blockedIps = b.data.blocked || [];
            await this.loadAudit();
        } catch(e) {} this.loading = false; },
        async loadAudit() { try { const r = await API.get('/api/security/audit-log.php?page=' + this.auditPage); this.auditLog = r.data.entries || []; this.auditTotal = r.data.total || 0; } catch(e) {} },
        async blockIp() { try { await API.post('/api/security/blocked-ips.php', this.blockForm); this.blockForm = { ip: '', reason: '' }; await this.load(); API.toast('IP blocked'); } catch(e) { API.toast(e.message, 'error'); } },
        async unblockIp(ip) { try { await API.del('/api/security/blocked-ips.php', { ip }); await this.load(); API.toast('IP unblocked'); } catch(e) { API.toast(e.message, 'error'); } },
        prevPage() { if (this.auditPage > 1) { this.auditPage--; this.loadAudit(); } },
        nextPage() { this.auditPage++; this.loadAudit(); }
    };
}
