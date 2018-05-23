const config = require('./config');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

exports.createDriver = function(){
    if (config.webdriverType === 'local') {
        return createLocalDriver();
    }
    return createRemoteDriver();
};

function createRemoteDriver() {
    return new webdriver.Builder()
    .build();
}

function createLocalDriver() {
  return new webdriver.Builder()
    .withCapabilities(webdriver.Capabilities.chrome())
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
    return await driver.findElement(By.id("button-1126-btnIconEl")).isDisplayed()
};
