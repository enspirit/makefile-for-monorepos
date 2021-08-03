FROM monorepo/base

COPY package.json .

RUN npm install

COPY . .

CMD ["npm", "start"]
