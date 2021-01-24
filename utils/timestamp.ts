export const getUnixTimeNowInSec = () => Math.floor(Date.now() / 1000);
export const getUnitTimeAfterMins = (mins: number) => getUnixTimeNowInSec() + mins * 60;