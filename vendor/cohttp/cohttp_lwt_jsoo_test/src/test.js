#!/usr/bin/env node

const assert = require('assert');

global.XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest;
const tests = require('./cohttp_lwt_jsoo_test.bc.js')

async function main() {
  {
    const [status, body] = await tests.request("https://mirage.io");
    assert(status == 200);
  }
  {
    const [status, body] = await tests.request("https://this.domain.does.not.exist");
    assert(status == 0);
  }
}

main()
