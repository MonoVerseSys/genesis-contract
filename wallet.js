const ethers = require('ethers')

;(async() => {
    const mnemonics =  process.env.mnemonics

    for(let i = 0; i < 21; i++) {
        const wallet = ethers.Wallet.fromMnemonic(mnemonics, `m/44'/60'/0'/0/${i}`)
        console.log(`i: ${i}, wallet.address: ${wallet.address}, wallet.privateKey : ${wallet.privateKey}, `)
        
    }
    
    
})()