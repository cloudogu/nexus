const config = require('./config');
const webdriver = require('selenium-webdriver');
const request = require('supertest');
const utils = require('./utils');
const By = webdriver.By;
const until = webdriver.until;

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
        await driver.sleep(500)
        //click admin menu button
        await driver.findElement(By.id("button-1127-btnIconEl")).click();
        // wait for admin options tree
        await driver.wait(until.elementLocated(By.className("x-tree-node-text")), 5000);
        // click users menu
        await driver.findElement(By.className(" x-tree-icon x-tree-icon-leaf nx-icon-feature-admin-security-users-x16")).click();
        await driver.sleep(500)
        //click testUser entry
        await driver.findElement(By.xpath("//tr[@id='gridview-1191-record-ext-record-156']/td[2]/div")).click();
        await driver.sleep(500)
        // click delete button
        await driver.wait(until.elementLocated(By.id("button-1207-btnInnerEl")), 5000);
        // await driver.wait(until.elementIsVisible(driver.findElement(By.id("button-1207-btnInnerEl")).catch));
        await driver.findElement(By.id("button-1207-btnInnerEl")).click();
        await driver.sleep(500)
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
        await driver.findElement(By.id('username')).sendKeys(this.testuserName);
        await driver.findElement(By.id('password')).sendKeys(this.testuserPasswort);
        await driver.findElement(By.css('input[name="submit"]')).click();
    };



    async testUserLogout(driver) {
        await driver.wait(until.elementLocated(By.xpath("//div[@id='header']/div[2]/span/a[2]/b")),5000);
        await driver.findElement(By.xpath("//div[@id='header']/div[2]/span/a[2]/b")).click();
    };

    async accessUsersJson(expectStatus){
        await request(config.baseUrl)
            .get(config.nexusContextPath+"/pluginManager/api/json")
            .auth(this.testuserName, this.testuserPasswort)
            .expect(expectStatus); //403 = "Forbidden", 200 = "OK"
    };

};
