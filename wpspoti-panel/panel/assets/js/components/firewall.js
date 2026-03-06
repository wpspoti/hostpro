function firewallComponent() {
    return {
        status: '', rules: [], loading: true, showAdd: false,
        form: { action: 'allow', direction: 'in', protocol: 'tcp', port: '', from_ip: 'any', comment: '' },
        async init() { await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/firewall/status.php'); this.status = r.data.status; this.rules = r.data.rules || []; } catch(e) {} this.loading = false; },
        async addRule() { try { await API.post('/api/firewall/add-rule.php', this.form); this.showAdd = false; this.form = { action: 'allow', direction: 'in', protocol: 'tcp', port: '', from_ip: 'any', comment: '' }; await this.load(); API.toast('Rule added'); } catch(e) { API.toast(e.message, 'error'); } },
        async deleteRule(num) { if (!confirm('Delete rule #' + num + '?')) return; try { await API.post('/api/firewall/delete-rule.php', { rule_number: num }); await this.load(); API.toast('Rule deleted'); } catch(e) { API.toast(e.message, 'error'); } },
        async toggle() { try { await API.post('/api/firewall/toggle.php', {}); await this.load(); API.toast('Firewall toggled'); } catch(e) { API.toast(e.message, 'error'); } }
    };
}
