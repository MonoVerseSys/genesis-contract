// const web3 = require("web3")
const ethers = require('ethers');
const {validators} = require('./validators')

const validatorInit = validators.map(item => {
  return {
    address: item.consensusAddr,
    balance: ethers.utils.parseUnits('1', 'ether').toHexString().substring(2)
  }
})

let init_holders = [
  {
    address: "0xfED8EFBeb3CD4485FCd18892c8407A47539C03B9", // 초기 운영 물량
    balance: ethers.utils.parseUnits('2100000', 'ether').toHexString().substring(2)
  },
  {
    address: '0xA7E346270BeB25538e76B429E99A4A3590530038', // validator manager 
    balance: ethers.utils.parseUnits('10', 'ether').toHexString().substring(2)
  }
  // {
  //   address: "0x6c468CF8c9879006E22EC4029696E005C2319C9D",
  //   balance: 10000 // without 10^18
  // }
];

init_holders = init_holders.concat(validatorInit)


// console.log(init_holders)
// console.log(ethers.utils.formatUnits('2100000000000000000000000', 'ether'))
// console.log('validator contract val', ethers.utils.parseUnits('52560000', 'ether').toHexString())


exports = module.exports = init_holders
