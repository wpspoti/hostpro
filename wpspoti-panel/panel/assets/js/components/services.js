function servicesComponent() {
    return {
        services: [], loading: true,
        serviceList: ['nginx','php8.3-fpm','mariadb','named','postfix','dovecot','vsftpd','fail2ban','ufw'],
        async init() { await this.load(); },
        async load() { this.loading = true; try { const r = await API.get('/api/services/list.php'); this.services = r.data.services || []; } catch(e) {} this.loading = false; },
        async action(name, act) {
            try { await API.post('/api/services/action.php', { service: name, action: act }); await this.load(); API.toast(`${name} ${act}ed`); } catch(e) { API.toast(e.message, 'error'); }
        },
        statusColor(s) { return s === 'active' ? 'text-emerald-600' : 'text-red-600'; },
        statusBg(s) { return s === 'active' ? 'bg-emerald-50 border-emerald-200' : 'bg-red-50 border-red-200'; }
    };
}
