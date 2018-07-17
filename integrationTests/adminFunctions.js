const config = require('./config');
const webdriver = require('selenium-webdriver');
const request = require('supertest');
const utils = require('./utils');
const By = webdriver.By;
const until = webdriver.until;
const waitInterval = 5000;

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

    async createLocalNexusUser() {
        // add nexus script for adding test user
        let addUserScriptName = "addUserForIntegrationTesting"
        await request(config.baseUrl)
            .post('/nexus/service/rest/v1/script')
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({
                'name': addUserScriptName,
                'content': "security.addUser(\"" + this.testuserName + "\", \"" + this.testuserFirstname + "\",\"" + this.testuserSurname + "\",\"" + this.testuserEmail + "\",true,\"" + this.testuserPasswort + "\",[\"nx-admin\"])",
                'type': "groovy"
            })
            .expect(204);
        // execute nexus script
        await request(config.baseUrl)
            .post('/nexus/service/rest/v1/script/'+addUserScriptName+'/run')
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('text/plain')
            .send("groovy")
            .expect(200);
        // remove nexus script
        await request(config.baseUrl)
            .delete('/nexus/service/rest/v1/script/'+addUserScriptName)
            .auth(config.username, config.password)
            .expect(204);
    };

    async removeLocalNexusUser() {
        // add nexus script for removing test user
        let removeUserScriptName = "removeIntegrationTestingUser"
        await request(config.baseUrl)
            .post('/nexus/service/rest/v1/script')
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('json')
            .send({
                'name': removeUserScriptName,
                'content': "security.securitySystem.deleteUser(\"" + this.testuserName + "\")",
                'type': "groovy"
            })
            .expect(204);
        // execute nexus script
        await request(config.baseUrl)
            .post('/nexus/service/rest/v1/script/'+removeUserScriptName+'/run')
            .auth(config.username, config.password)
            .set('Content-Type', 'application/json;charset=UTF-8')
            .type('text/plain')
            .send("groovy")
            .expect(200);
        // remove nexus script
        await request(config.baseUrl)
            .delete('/nexus/service/rest/v1/script/'+removeUserScriptName)
            .auth(config.username, config.password)
            .expect(204);
    };

    async removeUser(driver){
        await request(config.baseUrl)
            .del('/usermgt/api/users/' + this.testuserName)
            .auth(config.username, config.password);
        await utils.getCasUrl(driver);
        // login admin
        await utils.login(driver);
        await driver.sleep(waitInterval)
        // get to testuser's user menu entry
        driver.get(config.baseUrl + config.nexusContextPath + "#admin/security/users:" + this.testuserName)
        await driver.wait(until.elementLocated(By.id("tool-1156-toolEl")), 5000);
        await driver.sleep(waitInterval)
        // dismiss popup box
        await driver.findElement(By.id("tool-1156-toolEl")).click();
        // click delete button
        await driver.wait(until.elementLocated(By.id("button-1287-btnEl")), 5000);
        await driver.findElement(By.id("button-1287-btnEl")).click();
        // wait for yes button
        await driver.wait(until.elementLocated(By.id("button-1006-btnIconEl")), 5000);
        await driver.sleep(waitInterval)
        // click Yes
        await driver.findElement(By.id("button-1006-btnIconEl")).click();
        // wait for success button
        await driver.wait(until.elementLocated(By.className("x-header-text x-window-header-text x-window-header-text-nx-message-success")), 5000);
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
        await driver.get(config.baseUrl + '/cas/logout');
    };

    async accessScriptingAPI(expectStatus){
        await request(config.baseUrl)
            .get(config.nexusContextPath+"/service/rest/v1/script")
            .auth(this.testuserName, this.testuserPasswort)
            .expect(expectStatus); //403 = "Forbidden", 200 = "OK"
    };

};
