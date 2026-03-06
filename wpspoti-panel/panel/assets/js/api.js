const API = {
    csrfToken: document.querySelector('meta[name="csrf-token"]')?.content || '',

    async request(method, url, data = null) {
        const options = {
            method,
            headers: {
                'X-CSRF-TOKEN': this.csrfToken,
                'X-Requested-With': 'XMLHttpRequest'
            }
        };
        if (data && method !== 'GET') {
            if (data instanceof FormData) {
                data.append('csrf_token', this.csrfToken);
                options.body = data;
            } else {
                options.headers['Content-Type'] = 'application/json';
                options.body = JSON.stringify({...data, csrf_token: this.csrfToken});
            }
        }
        try {
            const response = await fetch(url, options);
            const json = await response.json();
            if (json.csrf_token) this.csrfToken = json.csrf_token;
            if (!response.ok) throw json;
            return json;
        } catch (e) {
            if (e.message === 'Authentication required' || e.status === 401) {
                window.location.reload();
            }
            throw e;
        }
    },

    get(url) { return this.request('GET', url); },
    post(url, data) { return this.request('POST', url, data); },
    del(url, data) { return this.request('DELETE', url, data); },

    async upload(url, file, extraData = {}) {
        const fd = new FormData();
        fd.append('file', file);
        Object.entries(extraData).forEach(([k, v]) => fd.append(k, v));
        return this.post(url, fd);
    },

    toast(msg, type = 'success') {
        const el = document.getElementById('toast');
        if (!el) return;
        el.className = `fixed bottom-4 right-4 px-6 py-3 rounded-lg shadow-lg text-white z-50 transition-all transform ${type === 'error' ? 'bg-red-600' : type === 'warning' ? 'bg-yellow-600' : 'bg-green-600'}`;
        el.textContent = msg;
        el.classList.remove('hidden');
        setTimeout(() => el.classList.add('hidden'), 4000);
    }
};
