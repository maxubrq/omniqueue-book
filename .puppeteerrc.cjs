// .puppeteerrc.cjs
const { join } = require('path');

// .puppeteerrc.cjs
module.exports = {
    executablePath: process.env.PUPPETEER_EXECUTABLE_PATH,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu'],
};

