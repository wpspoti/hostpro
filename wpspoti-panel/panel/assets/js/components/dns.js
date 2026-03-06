function dnsComponent() {
    return {
        zones: [], records: [], loading: true, selectedZone: null,
        showAddZone: false, showAddRecord: false,
        zoneForm: { domain: '' }, recordForm: { name: '@', type: 'A', value: '', ttl: 3600, priority: 10 },
        recordTypes: ['A','AAAA','CNAME','MX','TXT','NS','SRV','CAA'],
        async init() { await this.loadZones(); },
        async loadZones() { this.loading = true; try { const r = await API.get('/api/dns/zones.php'); this.zones = r.data.zones || []; } catch(e) {} this.loading = false; },
        async selectZone(z) { this.selectedZone = z; try { const r = await API.get('/api/dns/records.php?zone_id=' + z.id); this.records = r.data.records || []; } catch(e) { this.records = []; } },
        async addZone() { try { await API.post('/api/dns/zones.php', this.zoneForm); this.showAddZone = false; this.zoneForm = { domain: '' }; await this.loadZones(); API.toast('Zone created'); } catch(e) { API.toast(e.message, 'error'); } },
        async addRecord() { try { await API.post('/api/dns/records.php', { ...this.recordForm, zone_id: this.selectedZone.id }); this.showAddRecord = false; this.recordForm = { name: '@', type: 'A', value: '', ttl: 3600, priority: 10 }; await this.selectZone(this.selectedZone); API.toast('Record added'); } catch(e) { API.toast(e.message, 'error'); } },
        async deleteRecord(id) { if (!confirm('Delete record?')) return; try { await API.del('/api/dns/records.php', { id, zone_id: this.selectedZone.id }); await this.selectZone(this.selectedZone); } catch(e) { API.toast(e.message, 'error'); } }
    };
}
