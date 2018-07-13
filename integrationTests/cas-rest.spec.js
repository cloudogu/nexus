const config = require('./config');
const utils = require('./utils');
const request = require('supertest');
const AdminFunctions = require('./adminFunctions');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;

const testUserName = 'testUser';
const testUserEmail = "testUser@test.test"
const testUserPassword = "testuserpassword"

jest.setTimeout(30000);

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';


let driver;
let adminFunctions;

beforeEach(async () => {
    driver = utils.createDriver(webdriver);
    await driver.manage().window().maximize();
});

afterEach(async () => {
    await driver.quit();
});


describe('cas rest basic authentication', () => {

    test('authentication with username and password', async () => {
        await request(config.baseUrl)
            .get(config.nexusContextPath + "/service/rest/v1/script")
            .auth(config.username, config.password)
            .expect(200);
    });

    test('authentication with wrong username and password', async () => {
        await request(config.baseUrl)
            .get(config.nexusContextPath + "/service/rest/v1/script")
            .auth("ThIsIsNoTaVaLiDuSeR", "46Y2RjZjVnZWg2dGdmcmVjZGZ0c")
            .expect(401);
    });

    test('authentication with username and password of local Nexus user', async () => {
        adminFunctions = new AdminFunctions(testUserName, testUserName, testUserName, testUserEmail, testUserPassword);
        await adminFunctions.createLocalNexusUser();
        await request(config.baseUrl)
            .get(config.nexusContextPath + "/service/rest/v1/script")
            .auth(testUserName, testUserPassword)
            .expect(200);
        await adminFunctions.removeLocalNexusUser(driver);
    });

    test('authentication with wrong username and password of local Nexus user', async () => {
        adminFunctions = new AdminFunctions(testUserName, testUserName, testUserName, testUserEmail, testUserPassword);
        await adminFunctions.createLocalNexusUser();
        await request(config.baseUrl)
            .get(config.nexusContextPath + "/service/rest/v1/script")
            .auth(testUserName, "46Y2RjZjVnZWg2dGdmcmVjZGZ0c")
            .expect(401);
        await adminFunctions.removeLocalNexusUser(driver);
    });

});

