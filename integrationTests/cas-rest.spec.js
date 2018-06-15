const config = require('./config');
const utils = require('./utils');
const request = require('supertest');

const webdriver = require('selenium-webdriver');
const By = webdriver.By;
const until = webdriver.until;
jest.setTimeout(30000);

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';


let driver;

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

});

