import { getUnixTimeAfterMins, getUnixTimeNowInSec } from "./utils/timestamp";

console.log(new Date().getTime());
console.log(Date.now());

console.log(getUnixTimeNowInSec());
console.log(getUnixTimeAfterMins(10));
