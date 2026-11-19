import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:29999';
const TENANT_HOSTS = ['a.localhost', 'b.localhost'];

export const options = {
  scenarios: {
    planners: {
      executor: 'constant-arrival-rate',
      rate: 20,
      timeUnit: '1s',
      duration: '2m',
      preAllocatedVUs: 20,
      maxVUs: 100,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{name:items}': ['p(95)<300'],
    'http_req_duration{name:solve}': ['p(95)<2000'],
  },
};

export default function () {
  const headers = { Host: TENANT_HOSTS[Math.floor(Math.random() * TENANT_HOSTS.length)] };

  const items = http.get(`${BASE_URL}/api/items`, { headers, tags: { name: 'items' } });
  check(items, { 'items 200': r => r.status === 200 });

  if (Math.random() < 0.2) {
    const solve = http.post(`${BASE_URL}/api/solve`, null, { headers, tags: { name: 'solve' } });
    check(solve, { 'solve 200': r => r.status === 200 });
  }

  sleep(1);
}
