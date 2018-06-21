const config = require('./config');
const utils = require('./utils');
const AdminFunctions = require('./adminFunctions');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

const testUserName = 'testUser';
const testUserEmail = "testUser@test.de"
const testUserPassword = "testuserpassword"
const waitInterval = 5000;

jest.setTimeout(120000);

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';


let driver;
let adminFunctions;

beforeEach(async() => {
    driver = await utils.createDriver(webdriver);
    await driver.manage().window().maximize();
    adminFunctions = new AdminFunctions(testUserName, testUserName, testUserName, testUserEmail, testUserPassword);
    await adminFunctions.createUser();
});

afterEach(async() => {
    await adminFunctions.logoutViaCasEndpoint(driver);
    await adminFunctions.removeUser(driver);
    await driver.quit();
});


describe('user permissions', () => {

    test('user (testUser) has admin privileges', async() => {
        await driver.get(utils.getCasUrl(driver));
        await adminFunctions.giveAdminRights();
        await adminFunctions.testUserLogin(driver);
        await driver.sleep(waitInterval)
        // get username from user account button
        const username = await driver.findElement(By.id('button-1142-btnInnerEl')).getText();
        expect(username.toLowerCase()).toMatch(testUserName.toLowerCase());
        expect(await utils.isAdministrator(driver)).toBe(true);
    });

    test('user (testUser) has no admin privileges', async() => {
        await driver.get(utils.getCasUrl(driver));
        await adminFunctions.testUserLogin(driver);
        await driver.sleep(waitInterval)
        const username = await driver.findElement(By.id('button-1142-btnInnerEl')).getText();
        expect(username.toLowerCase()).toContain(testUserName.toLowerCase());
        expect(await utils.isAdministrator(driver)).toBe(false);
    });

    test('user (testUser) remove admin privileges', async() => {
        await driver.get(utils.getCasUrl(driver));
        await adminFunctions.giveAdminRights();
        await adminFunctions.testUserLogin(driver);
        await driver.sleep(waitInterval)
        await adminFunctions.logoutViaCasEndpoint(driver);
        await adminFunctions.takeAdminRights();
        await driver.get(utils.getCasUrl(driver));
        await adminFunctions.testUserLogin(driver);
        await driver.sleep(waitInterval)
        const adminPermissions = await utils.isAdministrator(driver);
        expect(adminPermissions).toBe(false);
    });

});
