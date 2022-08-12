require('dotenv').config();
const ethers = require('ethers')
const web3 = require("web3");
const RLP = require('rlp');
const validators = []
const isDev = process.env.NODE_ENV !== 'production'

const mnemonics = isDev ? process.env.mnemonicsTest : process.env.mnemonics

const count = isDev ? 3 : 19
for(let i = 0; i < count; i++) {
  const wallet = ethers.Wallet.fromMnemonic(mnemonics, `m/44'/60'/0'/0/${i}`)
  console.log(`i: ${i}, wallet.address: ${wallet.address}, wallet.privateKey : ${wallet.privateKey}, `)
  validators.push({
    consensusAddr: wallet.address,
    feeAddr: wallet.address,
    bscFeeAddr: wallet.address,
    votingPower: 0x0000000000000064
  })
}

if(!isDev) {
  // real 1
  validators.push({
    consensusAddr: '0xBfF5EFA77e5412e25d05fAf2406Ac97069675169',
    feeAddr: '0xBfF5EFA77e5412e25d05fAf2406Ac97069675169',
    bscFeeAddr: '0xBfF5EFA77e5412e25d05fAf2406Ac97069675169',
    votingPower: 0x0000000000000064
  })

  // real 2
  validators.push({
    consensusAddr: '0x88761AB2e00df4E18392539125d604aA0728d801',
    feeAddr: '0x88761AB2e00df4E18392539125d604aA0728d801',
    bscFeeAddr: '0x88761AB2e00df4E18392539125d604aA0728d801',
    votingPower: 0x0000000000000064
  })
}




console.log(validators, validators.length)

// Configure
// const validators = [
  
  
//   {//1
//     consensusAddr: "0xF95399FdAeEc378e344a5B6f81E2909e5a345120",
//     feeAddr: "0xF95399FdAeEc378e344a5B6f81E2909e5a345120",
//     bscFeeAddr: "0xF95399FdAeEc378e344a5B6f81E2909e5a345120",
//     votingPower: 0x0000000000000064
//   },
//   {//2
//     consensusAddr: "0x9C98f07d76cf16BfBA4f7217A2e73e616b66AD7B",
//     feeAddr: "0x9C98f07d76cf16BfBA4f7217A2e73e616b66AD7B",
//     bscFeeAddr: "0x9C98f07d76cf16BfBA4f7217A2e73e616b66AD7B",
//     votingPower: 0x0000000000000064
//   },
//   {//3
//     consensusAddr: "0x1F2b19c81c8e6D4F60dbC3E5DD2f54bBdEC8b933",
//     feeAddr: "0x1F2b19c81c8e6D4F60dbC3E5DD2f54bBdEC8b933",
//     bscFeeAddr: "0x1F2b19c81c8e6D4F60dbC3E5DD2f54bBdEC8b933",
//     votingPower: 0x0000000000000064
//   },/*
//   {//4
//     consensusAddr: "0xBfF5EFA77e5412e25d05fAf2406Ac97069675169",
//     feeAddr: "0xBfF5EFA77e5412e25d05fAf2406Ac97069675169",
//     bscFeeAddr: "0xBfF5EFA77e5412e25d05fAf2406Ac97069675169",
//     votingPower: 0x0000000000000064
//   },
//   {//5
//     consensusAddr: "0x88761AB2e00df4E18392539125d604aA0728d801",
//     feeAddr: "0x88761AB2e00df4E18392539125d604aA0728d801",
//     bscFeeAddr: "0x88761AB2e00df4E18392539125d604aA0728d801",
//     votingPower: 0x0000000000000064
//   },
//   {//6
//     consensusAddr: "0x7Ff73542b37624c63102756C6Fa52726AFfdA08c",
//     feeAddr: "0x7Ff73542b37624c63102756C6Fa52726AFfdA08c",
//     bscFeeAddr: "0x7Ff73542b37624c63102756C6Fa52726AFfdA08c",
//     votingPower: 0x0000000000000064
//   },
//   {//7
//     consensusAddr: "0x23f4F615d5Ce79B681361b6F0fBbEa9512DE7a2e",
//     feeAddr: "0x23f4F615d5Ce79B681361b6F0fBbEa9512DE7a2e",
//     bscFeeAddr: "0x23f4F615d5Ce79B681361b6F0fBbEa9512DE7a2e",
//     votingPower: 0x0000000000000064
//   },
//   {//8
//     consensusAddr: "0x67dB54D9dee1aa131Aa8eC0a33e71e5bB16b9b92",
//     feeAddr: "0x67dB54D9dee1aa131Aa8eC0a33e71e5bB16b9b92",
//     bscFeeAddr: "0x67dB54D9dee1aa131Aa8eC0a33e71e5bB16b9b92",
//     votingPower: 0x0000000000000064
//   },
//   {//9
//     consensusAddr: "0xE3032D641debC21d9C37b63D68dE28F3ABDd346F",
//     feeAddr: "0xE3032D641debC21d9C37b63D68dE28F3ABDd346F",
//     bscFeeAddr: "0xE3032D641debC21d9C37b63D68dE28F3ABDd346F",
//     votingPower: 0x0000000000000064
//   },
//   {//10
//     consensusAddr: "0xe2f78b63019918Ee0259a807c193837dc2401bA0",
//     feeAddr: "0xe2f78b63019918Ee0259a807c193837dc2401bA0",
//     bscFeeAddr: "0xe2f78b63019918Ee0259a807c193837dc2401bA0",
//     votingPower: 0x0000000000000064
//   },
//   {//11
//     consensusAddr: "0x3e9E17528f40a6d6ab0B3338Dc2b3757eB0471DA",
//     feeAddr: "0x3e9E17528f40a6d6ab0B3338Dc2b3757eB0471DA",
//     bscFeeAddr: "0x3e9E17528f40a6d6ab0B3338Dc2b3757eB0471DA",
//     votingPower: 0x0000000000000064
//   },
//   {//12
//     consensusAddr: "0xa2E0D3DEAf93Ffa88534964c218f44D25D22Be45",
//     feeAddr: "0xa2E0D3DEAf93Ffa88534964c218f44D25D22Be45",
//     bscFeeAddr: "0xa2E0D3DEAf93Ffa88534964c218f44D25D22Be45",
//     votingPower: 0x0000000000000064
//   },
//   {//13
//     consensusAddr: "0x570C6587EC2f2083f4c43c164aBcf8E373Df59bd",
//     feeAddr: "0x570C6587EC2f2083f4c43c164aBcf8E373Df59bd",
//     bscFeeAddr: "0x570C6587EC2f2083f4c43c164aBcf8E373Df59bd",
//     votingPower: 0x0000000000000064
//   },
//   {//14
//     consensusAddr: "0xc89aB8bd8c595E8F9FB82a083A0E1f3BAaBa9c69",
//     feeAddr: "0xc89aB8bd8c595E8F9FB82a083A0E1f3BAaBa9c69",
//     bscFeeAddr: "0xc89aB8bd8c595E8F9FB82a083A0E1f3BAaBa9c69",
//     votingPower: 0x0000000000000064
//   },
//   {//15
//     consensusAddr: "0xe9196Ef966d8015AD24F83A3715818f90ea7AB72",
//     feeAddr: "0xe9196Ef966d8015AD24F83A3715818f90ea7AB72",
//     bscFeeAddr: "0xe9196Ef966d8015AD24F83A3715818f90ea7AB72",
//     votingPower: 0x0000000000000064
//   },
//   {//16
//     consensusAddr: "0x4c37365DE926dfBb67968f8E8f959A1E89AaDF44",
//     feeAddr: "0x4c37365DE926dfBb67968f8E8f959A1E89AaDF44",
//     bscFeeAddr: "0x4c37365DE926dfBb67968f8E8f959A1E89AaDF44",
//     votingPower: 0x0000000000000064
//   },
//   {//17
//     consensusAddr: "0x6Bb8989D18D632c51Fb469c938D492Bd5A051f5D",
//     feeAddr: "0x6Bb8989D18D632c51Fb469c938D492Bd5A051f5D",
//     bscFeeAddr: "0x6Bb8989D18D632c51Fb469c938D492Bd5A051f5D",
//     votingPower: 0x0000000000000064
//   },
//   {//18
//     consensusAddr: "0x00eC719d84166eF7d4020e0463C6b30B2559bDED",
//     feeAddr: "0x00eC719d84166eF7d4020e0463C6b30B2559bDED",
//     bscFeeAddr: "0x00eC719d84166eF7d4020e0463C6b30B2559bDED",
//     votingPower: 0x0000000000000064
//   },
//   {//19
//     consensusAddr: "0x72E69C4985160e20175ADc589bD24D486288AE69",
//     feeAddr: "0x72E69C4985160e20175ADc589bD24D486288AE69",
//     bscFeeAddr: "0x72E69C4985160e20175ADc589bD24D486288AE69",
//     votingPower: 0x0000000000000064
//   },
//   {//20
//     consensusAddr: "0x7A6486a8BB83375E19Bd03dB74778AceEE38ab9F",
//     feeAddr: "0x7A6486a8BB83375E19Bd03dB74778AceEE38ab9F",
//     bscFeeAddr: "0x7A6486a8BB83375E19Bd03dB74778AceEE38ab9F",
//     votingPower: 0x0000000000000064
//   },
//   {//21
//     consensusAddr: "0xf910941F92172B3e7820FeDd7182e40a86569527",
//     feeAddr: "0xf910941F92172B3e7820FeDd7182e40a86569527",
//     bscFeeAddr: "0xf910941F92172B3e7820FeDd7182e40a86569527",
//     votingPower: 0x0000000000000064
//   }*/
// ];

// ===============  Do not edit below ====
function generateExtradata(validators) {
  let extraVanity =Buffer.alloc(32);
  let validatorsBytes = extraDataSerialize(validators);
  let extraSeal =Buffer.alloc(65);
  return Buffer.concat([extraVanity,validatorsBytes,extraSeal]);
}

function extraDataSerialize(validators) {
  let n = validators.length;
  let arr = [];
  for(let i = 0;i<n;i++){
    let validator = validators[i];
    arr.push(Buffer.from(web3.utils.hexToBytes(validator.consensusAddr)));
  }
  return Buffer.concat(arr);
}

function validatorUpdateRlpEncode(validators) {
  let n = validators.length;
  let vals = [];
  for(let i = 0;i<n;i++) {
    vals.push([
      validators[i].consensusAddr,
      validators[i].bscFeeAddr,
      validators[i].feeAddr,
      validators[i].votingPower,
    ]);
  }
  let pkg = [0x00, vals];
  return web3.utils.bytesToHex(RLP.encode(pkg));
}

extraValidatorBytes = generateExtradata(validators);
validatorSetBytes = validatorUpdateRlpEncode(validators);

exports = module.exports = {
  extraValidatorBytes: extraValidatorBytes,
  validatorSetBytes: validatorSetBytes,
  validators
}
