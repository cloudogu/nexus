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
    username: 'cwolfes',
    password: 'Trio-123',
    firstname: 'admin',
    lastname: 'admin',
    displayName: 'cwolfes',
    email: 'cwolfes@cloudogu.com',
    webdriverType: webdriverType,
    debug: true,
    adminGroup: 'CesAdministrators'
};
