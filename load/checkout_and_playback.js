import http from "k6/http";
import { check, sleep } from "k6";
export let options = {
  vus: 50,
  duration: "1m",
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<1000"],
  },
};
export default function () {
  const payload = JSON.stringify({
    userId: `user-${__VU}`,
    postId: "post-1",
    deviceId: `dev-${__VU}`,
    ttl: 3600,
  });
  const params = { headers: { "Content-Type": "application/json" } };
  const res = http.post("http://localhost:3001/issue", payload, params);
  check(res, {
    "issued token": (r) => r.status === 200 && r.json("token") !== undefined,
  });
  sleep(0.1);
}
