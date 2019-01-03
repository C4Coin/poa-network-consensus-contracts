const Registry = artifacts.require('TokenRegistry')
const Token = artifacts.require('BurnableERC20')

contract('Test token registry', accounts => {
   let registry
   let token

   it('Should create a token registry', async () => {
      registry = await Registry.new();
      token = await Token.new(1000)
   })

   it('Should add new token to registry', async () => {
      await registry.add(token.address)
      assert( await registry.exists(token.address) )
   })

   it('Should remove token from registry', async () => {
      await registry.remove(token.address)
      assert( !(await registry.exists(token.address)) )
   })
})
