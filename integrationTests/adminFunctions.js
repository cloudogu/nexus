const config = require('./config');
const webdriver = require('selenium-webdriver');
const request = require('supertest');
const utils = require('./utils');
const By = webdriver.By;
const until = webdriver.until;
const waitIntervalAfterClick = 2000;

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

module.exports = class AdminFunctions{

    constructor(testuserName, testUserFirstname, testuserSurname, testuserEmail, testuserPasswort) {
        this.testuserName=testuserName;
        this.testuserFirstname=testUserFirstname;
        this.testuserSurname=testuserSurname;
        this.testuserEmail=testuserEmail;
        this.testuserPasswort=testuserPasswort;
    };

    async createUser(){
        await request(config.baseUrl)
            .post('/usermgt/api/users/')
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({
                'username': this.testuserName,
                'givenname': this.testuserFirstname,
                'surname': this.testuserSurname,
                'displayName': this.testuserName,
                'mail': this.testuserEmail,
                'password': this.testuserPasswort,
                'memberOf':[]
            });
    };

    async removeUser(driver){
        await request(config.baseUrl)
            .del('/usermgt/api/users/' + this.testuserName)
            .auth(config.username, config.password);
        await utils.getCasUrl(driver);
        await utils.login(driver);
        await driver.sleep(waitIntervalAfterClick)
        //click admin menu button
        await driver.findElement(By.id("button-1127-btnIconEl")).click();
        // wait for admin options tree
        await driver.wait(until.elementLocated(By.className("x-tree-node-text")), 5000);
        // click users menu
        await driver.findElement(By.className(" x-tree-icon x-tree-icon-leaf nx-icon-feature-admin-security-users-x16")).click();
        await driver.sleep(waitIntervalAfterClick)
        //click testUser entry
        await driver.findElement(By.xpath("//tr[@id='gridview-1191-record-ext-record-156']/td[2]/div")).click();
        await driver.sleep(waitIntervalAfterClick)
        // click delete button
        await driver.wait(until.elementLocated(By.id("button-1207-btnInnerEl")), 5000);
        // await driver.wait(until.elementIsVisible(driver.findElement(By.id("button-1207-btnInnerEl")).catch));
        await driver.findElement(By.id("button-1207-btnInnerEl")).click();
        await driver.sleep(waitIntervalAfterClick)
        await driver.findElement(By.id("button-1006-btnIconEl")).click();




        // await driver.findElement(By.id("yui-gen1-button")).click();
    };

    async giveAdminRights(){

        await request(config.baseUrl)
            .put('/usermgt/api/users/' + this.testuserName)
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({'memberOf':[config.adminGroup],
                'username':this.testuserName,
                'givenname':this.testuserFirstname,
                'surname': this.testuserSurname,
                'displayName':this.testuserName,
                'mail':this.testuserEmail,
                'password':this.testuserPasswort})
            .expect(204);
    };


    async takeAdminRights(){

        await request(config.baseUrl)
            .put('/usermgt/api/users/' + this.testuserName)
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({'memberOf':[],
                'username':this.testuserName,
                'givenname':this.testuserFirstname,
                'surname': this.testuserSurname,
                'displayName':this.testuserName,
                'mail':this.testuserEmail,
                'password':this.testuserPasswort})
            .expect(204);
    };

    async testUserLogin(driver) {
        await driver.wait(until.elementLocated(By.id('password')), 5000);
        await driver.wait(until.elementLocated(By.id('username')), 5000);

        await driver.findElement(By.id('username')).sendKeys(this.testuserName);
        await driver.findElement(By.id('password')).sendKeys(this.testuserPasswort);
        return driver.findElement(By.css('input[name="submit"]')).click();
    };



    async logoutViaCasEndpoint(driver) {
        await driver.get(config.baseUrl + '/cas/logoutViaCasEndpoint');
    };

    async accessScriptingAPI(expectStatus){
        await request(config.baseUrl)
            .get(config.nexusContextPath+"/service/rest/v1/script")
            .auth(this.testuserName, this.testuserPasswort)
            .expect(expectStatus); //403 = "Forbidden", 200 = "OK"
    };

};
