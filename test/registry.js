const Registry = artifacts.require('TokenRegistry')
const RegistryProxy = artifacts.require('RegistryProxy')
const Token = artifacts.require('BurnableERC20')

contract('Test token registry', accounts => {
   let registryProxy
   let registry
   let token

   it('Should create a token registry', async () => {
      registry = await Registry.new()
      registryProxy = await RegistryProxy.new(registry.address)
      token = await Token.new(1000)
      console.log(registry)
   })

   it('Should add new token to registry', async () => {
      // Add token to registry
      await web3.eth.sendTransaction({
         from: accounts[0],
         to: registryProxy.address,
         data: registry.contract.add.getData(token.address),
      })

      // Check that it now exists
      assert(
         await web3.eth.sendTransaction({
            from: accounts[0],
            to: registryProxy.address,
            data: registry.contract.exists.getData(token.address),
         }).includes('1')
      )
   })

   it('Should remove token from registry', async () => {
      // Remove token from registry
      await web3.eth.sendTransaction({
         from: accounts[0],
         to: registryProxy.address,
         data: registry.contract.remove.getData(token.address),
      })

      // Check that it now exists
      assert(
         !(
            await web3.eth.call({
               from: accounts[0],
               to: registryProxy.address,
               data: registry.contract.exists.getData(token.address),
            }).includes('1')
         )
      )
   })
})
