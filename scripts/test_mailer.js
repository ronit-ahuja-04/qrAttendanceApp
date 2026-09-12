const nodemailer = require('nodemailer');
const mailer = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  family: 4,
  auth: { user: 'test', pass: 'test' }
});
console.log(mailer.options);
