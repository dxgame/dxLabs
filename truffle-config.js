module.exports = {
  // https://trufflesuite.com/docs/truffle/reference/configuration
  networks: {
   development: {
     host: "127.0.0.1",
     port: 9545,
     network_id: "*"
   },
   test: {
     host: "127.0.0.1",
     port: 9545,
     network_id: "*"
   }
  },
  compilers: {
    solc: {
      version: "pragma"
    }
  }
};
