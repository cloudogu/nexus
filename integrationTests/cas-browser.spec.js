const config = require('./config');
const utils = require('./utils');
const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

const logoutUrl = '/cas/logout';
const loginUrl = '/cas/login';


jest.setTimeout(30000);

let driver;

beforeEach(() => {
    driver = utils.createDriver(webdriver);
});

afterEach(() => {
    driver.quit();
});

describe('cas browser login', () => {

    test('automatic redirect to cas login', async () => {
        await driver.get(config.baseUrl + config.nexusContextPath);
        const url = await driver.getCurrentUrl();
        expect(url).toMatch(loginUrl);
    });

    test('login', async() => {
        await driver.get(utils.getCasUrl(driver));
        await utils.login(driver);
        const username = await driver.findElement(By.id('button-1145-btnInnerEl')).getText();
        expect(username.toLowerCase()).toContain(config.displayName);
    });

    test('login with wrong password', async() => {
        await driver.get(utils.getCasUrl(driver));
        await driver.wait(until.elementLocated(By.id('password')), 5000);
        await driver.wait(until.elementLocated(By.id('username')), 5000);

        await driver.findElement(By.id('username')).sendKeys("ThIsIsNoTaVaLiDuSeR");
        await driver.findElement(By.id('password')).sendKeys("46Y2RjZjVnZWg2dGdmcmVjZGZ0c");
        await driver.findElement(By.css('input[name="submit"]')).click();
        const url = await driver.getCurrentUrl();
        expect(url).toMatch(loginUrl);
    });

    test('logout front channel', async() => {
        await driver.get(utils.getCasUrl(driver));
        await utils.login(driver);
        await driver.findElement(By.id("nx-header-signout-1148-btnInnerEl")).click();
        const url = await driver.getCurrentUrl();
        expect(url).toMatch(logoutUrl);
    });

    test('logout back channel', async() => {
        await driver.get(utils.getCasUrl(driver));
        await utils.login(driver);
        await driver.get(config.baseUrl + logoutUrl);
        await driver.get(config.baseUrl + config.nexusContextPath);
        const url = await driver.getCurrentUrl();
        expect(url).toMatch(loginUrl);
    });

});


describe('browser attributes', () => {

    test('front channel user attributes', async () => {
        await driver.get(utils.getCasUrl(driver));
        await utils.login(driver);
        await driver.wait(until.elementLocated(By.id('button-1145-btnIconEl')), 5000);
        await driver.sleep(100);
        await driver.findElement(By.id("button-1145-btnIconEl")).click()
        await driver.sleep(100);
        const firstname = await driver.findElement(By.id("textfield-1175-inputEl")).getAttribute("value");
        const emailAddress = await driver.findElement(By.id("nx-email-1177-inputEl")).getAttribute("value");
        const lastName = await driver.findElement(By.id("textfield-1176-inputEl")).getAttribute("value");
        const userId = await driver.findElement(By.id("textfield-1174-inputEl")).getAttribute("value");
        expect(firstname).toBe(config.firstname);
        expect(emailAddress).toBe(config.email);
        expect(lastName).toBe(config.lastname);
        expect(userId).toBe(config.username);
    });

    test('front channel user administrator', async () => {
        await driver.get(utils.getCasUrl(driver));
        await utils.login(driver);
        const isAdministrator = await utils.isAdministrator(driver);
        expect(isAdministrator).toBe(true);
    });



});
