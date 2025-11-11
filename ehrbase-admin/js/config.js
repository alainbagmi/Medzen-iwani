// Configuration Management
const config = {
    baseUrl: localStorage.getItem('ehrbase_url') || 'https://ehrbase.mylestechsolutions.com',
    username: localStorage.getItem('ehrbase_username') || 'ehrbase-user',
    password: localStorage.getItem('ehrbase_password') || 'ehrbase-password',

    // Save configuration
    save: function(url, username, password) {
        this.baseUrl = url;
        this.username = username;
        this.password = password;
        localStorage.setItem('ehrbase_url', url);
        localStorage.setItem('ehrbase_username', username);
        localStorage.setItem('ehrbase_password', password);
    },

    // Get auth header
    getAuthHeader: function() {
        return 'Basic ' + btoa(this.username + ':' + this.password);
    }
};
