function emailComponent() {
    return {
        domains: [], accounts: [], forwarders: [], loading: true, tab: 'accounts',
        showAddDomain: false, showAddAccount: false, showAddForwarder: false,
        domainForm: { domain: '' }, accountForm: { local_part: '', domain_id: '', password: '', quota: 500 },
        forwarderForm: { source: '', destination: '', domain_id: '' },
        async init() { await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/email/domains.php'); this.domains = r.data.domains || []; const a = await API.get('/api/email/accounts.php'); this.accounts = a.data.accounts || []; const f = await API.get('/api/email/forwarders.php'); this.forwarders = f.data.forwarders || []; } catch(e) {} this.loading = false; },
        async addDomain() { try { await API.post('/api/email/domains.php', this.domainForm); this.showAddDomain = false; this.domainForm = { domain: '' }; await this.load(); API.toast('Domain added'); } catch(e) { API.toast(e.message, 'error'); } },
        async addAccount() { try { await API.post('/api/email/accounts.php', this.accountForm); this.showAddAccount = false; this.accountForm = { local_part: '', domain_id: '', password: '', quota: 500 }; await this.load(); API.toast('Account created'); } catch(e) { API.toast(e.message, 'error'); } },
        async addForwarder() { try { await API.post('/api/email/forwarders.php', this.forwarderForm); this.showAddForwarder = false; this.forwarderForm = { source: '', destination: '', domain_id: '' }; await this.load(); API.toast('Forwarder added'); } catch(e) { API.toast(e.message, 'error'); } },
        async deleteAccount(id) { if (!confirm('Delete this account?')) return; try { await API.del('/api/email/accounts.php', { id }); await this.load(); API.toast('Deleted'); } catch(e) { API.toast(e.message, 'error'); } },
        async deleteForwarder(id) { if (!confirm('Delete?')) return; try { await API.del('/api/email/forwarders.php', { id }); await this.load(); } catch(e) {} }
    };
}
