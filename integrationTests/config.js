let cesFqdn = process.env.CES_FQDN;
if (!cesFqdn) {
  // url from ecosystem with private network
  cesFqdn = "192.168.56.2"
}

let webdriverType = process.env.WEBDRIVER;
if (!webdriverType) {
  webdriverType = 'local';
}

module.exports = {
    fqdn: cesFqdn,
    baseUrl: 'https://' + cesFqdn,
    nexusContextPath: '/nexus',
    username: 'admin',
    password: 'adminpw',
    firstname: 'admin',
    lastname: 'admin',
    displayName: 'admin',
    email: 'admin@admin.admin',
    webdriverType: webdriverType,
    debug: true,
    adminGroup: 'cesAdmin'
};