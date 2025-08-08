// .puppeteerrc.cjs
module.exports = {
  headless: 'new',
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-gpu',
    '--disable-dev-shm-usage',
    '--disable-extensions',
    '--disable-software-rasterizer',
    '--no-zygote',
  ],
};
