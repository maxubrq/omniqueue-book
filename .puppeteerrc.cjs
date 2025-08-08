// .puppeteerrc.cjs
const { join } = require('path');

module.exports = {
  executablePath: process.env.PUPPETEER_EXECUTABLE_PATH, // set in workflow
  cacheDirectory: join(process.cwd(), '.cache', 'puppeteer'),
  headless: 'new', // or true on older Puppeteer
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-gpu',
  ],
};
