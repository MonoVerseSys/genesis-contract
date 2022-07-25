const ethers = require('ethers')

;(async() => {
    const mnemonics =  process.env.mnemonics
    const wallet = ethers.Wallet.fromMnemonic(mnemonics)
    
    console.log(`wallet.address: ${wallet.address}, wallet.privateKey : ${wallet.privateKey}, `)
})()