const config = require('./config');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

const chromeCapabilities = webdriver.Capabilities.chrome();

const chromeOptions = {
    'args': ['--test-type', '--start-maximized']
};

// identifiers for UI interactions
export const UI = {
    myAccount: "button-1141-btnInnerEl",
    changeSettingsButton: "button-1125-btnIconEl",// indicates admin user
    logoutButton: "nx-header-signout-1143-btnIconEl"
};

chromeCapabilities.set('chromeOptions', chromeOptions);
chromeCapabilities.set('name', 'Nexus ITs');

// set filename pattern for zalenium videos
chromeCapabilities.set("testFileNameTemplate", "{testName}_{testStatus}");

let driver = null;

const zaleniumReporter = {

    specStarted: function(test) {
        // set testname for zalenium
        chromeCapabilities.set("name", test.fullName);
    },

    // does not work on jasmine 2, we have to wait until jest updates jasmine to v3
    // set status to success or failed, currently all tests have status completed
    xspecDone: function(result, done) {
        driver.manage().addCookie({
            name: "zaleniumTestPassed", 
            value: result.status === "passed"
        });
        driver.quit().then(done);
    }
};

jasmine.getEnv().addReporter(zaleniumReporter);

exports.createDriver = function(){
    if (config.webdriverType === 'local') {
        driver = createLocalDriver();
    } else {
        driver = createRemoteDriver();
    }
    
    return driver;
};

function createRemoteDriver() {
  return new webdriver.Builder()
    .withCapabilities(chromeCapabilities)
    .build();
}

function createLocalDriver() {
  return new webdriver.Builder()
    .withCapabilities(chromeCapabilities)
    .usingServer('http://localhost:4444/wd/hub')
    .build();
}



exports.getCasUrl = async function getCasUrl(driver){
    await driver.get(config.baseUrl + config.nexusContextPath);
    return driver.getCurrentUrl();
};

exports.login = async function login(driver) {
    await driver.wait(until.elementLocated(By.id('password')), 5000);
    await driver.wait(until.elementLocated(By.id('username')), 5000);

    await driver.findElement(By.id('username')).sendKeys(config.username);
    await driver.findElement(By.id('password')).sendKeys(config.password);
    return driver.findElement(By.css('input[name="submit"]')).click();
};

exports.isAdministrator = async function isAdministrator(driver){
    // is admin button (gear symbol) at top navigation bar visible?
    return await driver.findElement(By.id(UI.changeSettingsButton)).isDisplayed()
};
