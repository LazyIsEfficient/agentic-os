'use strict';
const http = require('node:http');
const path = require('node:path');
const { createHandler } = require('./app');

const port = Number(process.env.PORT || 3000);
http
  .createServer(createHandler({ uploadDir: path.join(__dirname, 'uploads') }))
  .listen(port, '127.0.0.1', () => console.log(`notes-share on http://127.0.0.1:${port}`));
