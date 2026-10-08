import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { createRequire } from 'node:module';
const require = createRequire(new URL('../../package.json', import.meta.url));
const ts = require('typescript');
const axios = require('axios');

function client(adapter) {
  const source = fs.readFileSync(new URL('../../src/app/core/lib/axios.ts', import.meta.url), 'utf8');
  const compiled = ts.transpileModule(source, { compilerOptions: {
    module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022, esModuleInterop: true,
  }}).outputText;
  const exports = {};
  const window = { location: { href: '/dashboard' } };
  vm.runInNewContext(compiled, { exports, window, require(name) {
    return name === 'axios' ? axios : { trackerEnv: { TRACKER_API_BASE_URL: '/api' } };
  }});
  exports.default.defaults.adapter = adapter;
  return { http: exports.default, window };
}
function unauthorized(config) {
  return new axios.AxiosError('Unauthorized', 'ERR_BAD_REQUEST', config, undefined,
    { status: 401, data: {}, headers: {}, config });
}
function ok(config) { return { status: 200, data: { status: 200 }, headers: {}, config }; }

test('expired access triggers one shared refresh and retries concurrent requests', async () => {
  let refreshed = false;
  let renewals = 0;
  const { http, window } = client(async config => {
    if (config.url === '/auth/refresh') {
      renewals++;
      await new Promise(resolve => setTimeout(resolve, 5));
      refreshed = true;
      return ok(config);
    }
    if (!refreshed) throw unauthorized(config);
    return ok(config);
  });
  const responses = await Promise.all([http.get('/user/profile'), http.get('/user/records')]);
  assert.equal(renewals, 1);
  assert.ok(responses.every(response => response.status === 200));
  assert.equal(window.location.href, '/dashboard');
});

test('rejected refresh redirects once and never loops', async () => {
  const requests = [];
  const { http, window } = client(async config => {
    requests.push(config.url);
    throw unauthorized(config);
  });
  await assert.rejects(http.get('/user/profile'));
  assert.deepEqual(requests, ['/user/profile', '/auth/refresh']);
  assert.equal(window.location.href, '/login');
});

test('invalid login credentials do not trigger refresh or a page redirect', async () => {
  const requests = [];
  const { http, window } = client(async config => {
    requests.push(config.url);
    throw unauthorized(config);
  });
  await assert.rejects(http.post('/auth/login', {}));
  assert.deepEqual(requests, ['/auth/login']);
  assert.equal(window.location.href, '/dashboard');
});
