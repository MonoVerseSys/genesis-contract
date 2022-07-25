// const web3 = require("web3")
const ethers = require('ethers')



const init_holders = [
  {
    // private key is 0x9b28f36fbd67381120752d6172ecdcf10e06ab2d9a1367aac00cdcd6ac7855d3, only use in dev
    address: "0xC88C7E1282C019fBE12Bee246E9ac50368566d9F",
    balance: ethers.utils.parseUnits('2100000', 'ether').toHexString().substring(2)
  }
  // {
  //   address: "0x6c468CF8c9879006E22EC4029696E005C2319C9D",
  //   balance: 10000 // without 10^18
  // }
];
console.log(init_holders)
console.log(ethers.utils.formatUnits('2100000000000000000000000', 'ether'))
console.log('validator contract val', ethers.utils.parseUnits('52560000', 'ether').toHexString())


exports = module.exports = init_holders
