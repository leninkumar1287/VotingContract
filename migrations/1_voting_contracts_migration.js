const NeoToken = artifacts.require('NeoToken.sol')


module.exports = async (deployer) => {
    try {
        await deployer.deploy(NeoToken)
    } catch (error) {
        console.log("error messsage  : ",error)
    }
}