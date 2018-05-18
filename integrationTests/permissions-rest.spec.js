const config = require('./config');
const AdminFunctions = require('./adminFunctions');
const utils = require('./utils');
const webdriver = require('selenium-webdriver');
const cacheWaitIntervall = 11000;

jest.setTimeout(60000);
let driver;
let adminFunctions;

const testUserName = 'testUser';
const testUserEmail = "testUser@test.de"
const testUserPassword = "testuserpassword"

// disable certificate validation
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

beforeEach(async() => {
    driver = utils.createDriver(webdriver);
    adminFunctions = new AdminFunctions(testUserName, testUserName, testUserName, testUserEmail, testUserPassword);
    await adminFunctions.createUser();
});

afterEach(async() => {
    await adminFunctions.removeUser(driver);
    await driver.quit();
});


describe('administration rest tests', () => {

    test('user (' + testUserName + ') has admin privileges', async() => {
        await driver.sleep(cacheWaitIntervall) // wait for cache to expire
        await adminFunctions.accessScriptingAPI(403);
        await driver.sleep(cacheWaitIntervall) // wait for cache to expire
        await adminFunctions.giveAdminRights();
        await adminFunctions.accessScriptingAPI(200);
    });

    test('user (' + testUserName + ') has no admin privileges', async() => {
        await driver.sleep(cacheWaitIntervall) // wait for cache to expire
        await adminFunctions.accessScriptingAPI(403);
    });


    test('user (' + testUserName + ') remove admin privileges', async() => {
        await driver.sleep(cacheWaitIntervall) // wait for cache to expire
        await adminFunctions.accessScriptingAPI(403);
        await driver.sleep(cacheWaitIntervall) // wait for cache to expire
        await adminFunctions.giveAdminRights();
        await adminFunctions.accessScriptingAPI(200);
        await driver.sleep(cacheWaitIntervall) // wait for cache to expire
        await adminFunctions.takeAdminRights();
        await adminFunctions.accessScriptingAPI(403);
    });

});